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
