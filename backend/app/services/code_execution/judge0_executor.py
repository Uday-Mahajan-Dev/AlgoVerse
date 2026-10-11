import asyncio
import httpx
import requests

from app.core.config import settings
from app.services.code_execution.base_executor import (
    BaseCodeExecutor,
    ExecutionResult,
)


class Judge0Executor(BaseCodeExecutor):
    LANGUAGE_IDS = {
        "python": 71,  # Python 3.8.1
        "java": 62,    # Java OpenJDK 13.0.1
        "cpp": 54,     # C++ GCC 9.2.0
    }

    STATUS_MAP = {
        3: "AC",   # Accepted
        4: "WA",   # Wrong Answer
        5: "TLE",  # Time Limit Exceeded
        6: "CE",   # Compilation Error
        7: "RE",   # Runtime Error (SIGSEGV)
        8: "RE",   # Runtime Error (SIGXFSZ)
        9: "RE",   # Runtime Error (SIGFPE)
        10: "RE",  # Runtime Error (SIGABRT)
        11: "RE",  # Runtime Error (NZEC)
        12: "RE",  # Runtime Error (Other)
        13: "CE",  # Internal Error (treated as CE)
    }

    def _prepare_payload(
        self,
        source_code: str,
        language: str,
        stdin_input: str,
        time_limit_ms: int,
        memory_limit_mb: int,
    ) -> tuple[dict | None, str]:
        lang_key = (language or "").strip().lower()
        if lang_key == "c++":
            lang_key = "cpp"
        elif lang_key in ("python3", "py"):
            lang_key = "python"

        if lang_key not in self.LANGUAGE_IDS:
            return None, lang_key

        language_id = self.LANGUAGE_IDS[lang_key]
        min_mem_kb = 512000 if lang_key == "java" else 128000
        payload = {
            "source_code": source_code,
            "language_id": language_id,
            "stdin": stdin_input,
            "cpu_time_limit": max(0.5, time_limit_ms / 1000.0),
            "memory_limit": max(min_mem_kb, memory_limit_mb * 1024),  # in KB
            "enable_per_process_and_thread_time_limit": True,
            "enable_per_process_and_thread_memory_limit": True,
        }
        return payload, lang_key

    def _parse_judge0_response(self, data: dict) -> ExecutionResult:
        status_info = data.get("status", {})
        status_id = status_info.get("id", 0)

        stdout = data.get("stdout") or ""
        stderr = data.get("stderr") or ""
        compile_output = data.get("compile_output") or ""

        if compile_output:
            stderr = f"{compile_output}\n{stderr}".strip()

        raw_time = data.get("time")
        execution_time_ms = int(float(raw_time) * 1000) if raw_time else 0
        memory_used_kb = int(data.get("memory") or 0)

        timed_out = status_id == 5
        compile_error = status_id == 6 or status_id == 13
        exit_code = 0 if status_id == 3 else (1 if compile_error or timed_out else 2)

        return ExecutionResult(
            stdout=stdout,
            stderr=stderr,
            exit_code=exit_code,
            execution_time_ms=execution_time_ms,
            memory_used_kb=memory_used_kb,
            timed_out=timed_out,
            compile_error=compile_error,
        )

    def execute(
        self,
        source_code: str,
        language: str,
        stdin_input: str,
        time_limit_ms: int = 2000,
        memory_limit_mb: int = 64,
    ) -> ExecutionResult:
        payload, lang_key = self._prepare_payload(
            source_code, language, stdin_input, time_limit_ms, memory_limit_mb
        )
        if payload is None:
            return ExecutionResult(
                stdout="",
                stderr=f"Unsupported language: '{language}'. Supported: {list(self.LANGUAGE_IDS.keys())}",
                exit_code=1,
                execution_time_ms=0,
                memory_used_kb=0,
                timed_out=False,
                compile_error=True,
            )

        endpoint = f"{settings.JUDGE0_API_URL.rstrip('/')}/submissions?base64_encoded=false&wait=true"

        try:
            response = requests.post(
                endpoint,
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=(time_limit_ms / 1000.0) + 10.0,
            )
            response.raise_for_status()
            return self._parse_judge0_response(response.json())
        except Exception as e:
            return ExecutionResult(
                stdout="",
                stderr=f"Judge0 execution error: {str(e)}",
                exit_code=1,
                execution_time_ms=0,
                memory_used_kb=0,
                timed_out=False,
                compile_error=True,
            )

    async def _execute_single_async(
        self,
        client: httpx.AsyncClient,
        payload: dict,
        endpoint: str,
    ) -> ExecutionResult:
        try:
            response = await client.post(
                endpoint,
                json=payload,
                headers={"Content-Type": "application/json"},
            )
            response.raise_for_status()
            return self._parse_judge0_response(response.json())
        except Exception as e:
            return ExecutionResult(
                stdout="",
                stderr=f"Judge0 execution error: {str(e)}",
                exit_code=1,
                execution_time_ms=0,
                memory_used_kb=0,
                timed_out=False,
                compile_error=True,
            )

    async def execute_batch_async(
        self,
        source_code: str,
        language: str,
        test_inputs: list[str],
        time_limit_ms: int = 2000,
        memory_limit_mb: int = 64,
    ) -> list[ExecutionResult]:
        if not test_inputs:
            return []

        payload_sample, lang_key = self._prepare_payload(
            source_code, language, "", time_limit_ms, memory_limit_mb
        )
        if payload_sample is None:
            err_res = ExecutionResult(
                stdout="",
                stderr=f"Unsupported language: '{language}'. Supported: {list(self.LANGUAGE_IDS.keys())}",
                exit_code=1,
                execution_time_ms=0,
                memory_used_kb=0,
                timed_out=False,
                compile_error=True,
            )
            return [err_res] * len(test_inputs)

        endpoint = f"{settings.JUDGE0_API_URL.rstrip('/')}/submissions?base64_encoded=false&wait=true"
        timeout = (time_limit_ms / 1000.0) + 10.0

        async with httpx.AsyncClient(timeout=timeout) as client:
            tasks = []
            for stdin_input in test_inputs:
                payload, _ = self._prepare_payload(
                    source_code, language, stdin_input, time_limit_ms, memory_limit_mb
                )
                tasks.append(self._execute_single_async(client, payload, endpoint))
            return await asyncio.gather(*tasks)

