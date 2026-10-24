import asyncio
import base64
import io
import logging
import re
import zipfile
import httpx
import requests

from app.core.config import settings
from app.services.code_execution.base_executor import (
    BaseCodeExecutor,
    ExecutionResult,
)

logger = logging.getLogger(__name__)


class Judge0Executor(BaseCodeExecutor):
    LANGUAGE_IDS = {
        "python": 71,  # Python 3.8.1
        "java": 89,    # Multi-file program (Java with JVM flags)
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

    @staticmethod
    def detect_java_class_name(source_code: str) -> str:
        """Detect public class name from Java source code, defaulting to 'Main'."""
        code_no_comments = re.sub(r"//.*", "", source_code)
        code_no_comments = re.sub(r"/\*.*?\*/", "", code_no_comments, flags=re.DOTALL)
        match = re.search(r"public\s+class\s+([A-Za-z_][A-Za-z0-9_]*)", code_no_comments)
        if match:
            return match.group(1)
        match_any = re.search(r"class\s+([A-Za-z_][A-Za-z0-9_]*)", code_no_comments)
        if match_any:
            return match_any.group(1)
        return "Main"

    @staticmethod
    def build_java_zip(class_name: str, java_code: str) -> str:
        """
        Build an in-memory base64-encoded zip containing:
        - <ClassName>.java
        - compile script: javac -encoding UTF-8 <ClassName>.java
        - run script with JVM metaspace flags to prevent startup memory reservation crash
        """
        compile_script = f"#!/bin/bash\njavac -encoding UTF-8 {class_name}.java\n"
        run_script = (
            f"#!/bin/bash\n"
            f"java -XX:+UseSerialGC -XX:-UseCompressedClassPointers "
            f"-XX:MaxMetaspaceSize=128m -Xss64m -Xmx256m -Xshare:off {class_name}\n"
        )

        buf = io.BytesIO()
        with zipfile.ZipFile(buf, "w", compression=zipfile.ZIP_DEFLATED) as z:
            z.writestr(f"{class_name}.java", java_code)

            compile_info = zipfile.ZipInfo("compile")
            compile_info.external_attr = 0o755 << 16
            z.writestr(compile_info, compile_script.encode("utf-8"))

            run_info = zipfile.ZipInfo("run")
            run_info.external_attr = 0o755 << 16
            z.writestr(run_info, run_script.encode("utf-8"))

        return base64.b64encode(buf.getvalue()).decode("utf-8")

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

        min_mem_kb = 512000 if lang_key == "java" else 128000
        mem_limit = max(min_mem_kb, memory_limit_mb * 1024)

        if lang_key == "java":
            class_name = self.detect_java_class_name(source_code)
            additional_files_b64 = self.build_java_zip(class_name, source_code)
            payload = {
                "source_code": "",
                "language_id": 89,
                "additional_files": additional_files_b64,
                "stdin": stdin_input,
                "cpu_time_limit": max(0.5, time_limit_ms / 1000.0),
                "memory_limit": mem_limit,
                "enable_per_process_and_thread_time_limit": True,
                "enable_per_process_and_thread_memory_limit": True,
            }
        else:
            language_id = self.LANGUAGE_IDS[lang_key]
            payload = {
                "source_code": source_code,
                "language_id": language_id,
                "stdin": stdin_input,
                "cpu_time_limit": max(0.5, time_limit_ms / 1000.0),
                "memory_limit": mem_limit,
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

        # Error mapping: If JVM failed to start due to metaspace or VM init
        if "Error occurred during initialization of VM" in stderr or "Could not allocate metaspace" in stderr:
            logger.error("Java runtime failed to start on the judge server: %s", stderr)
            stderr = "Java runtime failed to start on the judge server"
            return ExecutionResult(
                stdout=stdout,
                stderr=stderr,
                exit_code=1,
                execution_time_ms=0,
                memory_used_kb=0,
                timed_out=False,
                compile_error=False,
            )

        raw_time = data.get("time")
        execution_time_ms = int(float(raw_time) * 1000) if raw_time else 0
        memory_used_kb = int(data.get("memory") or 0)

        timed_out = status_id == 5
        compile_error = status_id == 6 or status_id == 13 or (bool(compile_output) and not stdout and status_id != 3)
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
            if lang_key in ("python", "python3", "py"):
                from app.services.code_execution.subprocess_executor import SubprocessExecutor
                return SubprocessExecutor().execute(
                    source_code=source_code,
                    language=language,
                    stdin_input=stdin_input,
                    time_limit_ms=time_limit_ms,
                    memory_limit_mb=memory_limit_mb,
                )
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
            results = await asyncio.gather(*tasks)

            # If Judge0 execution failed and language is Python, fallback gracefully to SubprocessExecutor
            if results and any(r.compile_error and "Judge0 execution error:" in r.stderr for r in results):
                if lang_key in ("python", "python3", "py"):
                    from app.services.code_execution.subprocess_executor import SubprocessExecutor
                    return await SubprocessExecutor().execute_batch_async(
                        source_code=source_code,
                        language=language,
                        test_inputs=test_inputs,
                        time_limit_ms=time_limit_ms,
                        memory_limit_mb=memory_limit_mb,
                    )

            return results

