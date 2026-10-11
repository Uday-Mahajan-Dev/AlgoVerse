import asyncio
from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass
class ExecutionResult:
    stdout: str
    stderr: str
    exit_code: int
    execution_time_ms: int
    memory_used_kb: int
    timed_out: bool
    compile_error: bool


class BaseCodeExecutor(ABC):
    @abstractmethod
    def execute(
        self,
        source_code: str,
        language: str,
        stdin_input: str,
        time_limit_ms: int = 2000,
        memory_limit_mb: int = 64,
    ) -> ExecutionResult:
        """Execute source code with given input and resource limits."""
        pass

    async def execute_batch_async(
        self,
        source_code: str,
        language: str,
        test_inputs: list[str],
        time_limit_ms: int = 2000,
        memory_limit_mb: int = 64,
    ) -> list[ExecutionResult]:
        """Execute multiple test case inputs concurrently."""
        tasks = [
            asyncio.to_thread(
                self.execute,
                source_code,
                language,
                stdin_input,
                time_limit_ms,
                memory_limit_mb,
            )
            for stdin_input in test_inputs
        ]
        return await asyncio.gather(*tasks)

