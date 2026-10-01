import time
import requests

from app.core.config import settings
from app.services.code_execution.base_executor import BaseCodeExecutor
from app.services.code_execution.judge0_executor import Judge0Executor
from app.services.code_execution.subprocess_executor import SubprocessExecutor

_cached_executor: BaseCodeExecutor | None = None
_last_check_time: float = 0
_CHECK_INTERVAL_SECONDS = 15.0


def get_executor() -> BaseCodeExecutor:
    """Auto-detect Judge0 service availability and return Judge0Executor or Fallback SubprocessExecutor."""
    global _cached_executor, _last_check_time

    current_time = time.time()
    if _cached_executor is not None and (current_time - _last_check_time) < _CHECK_INTERVAL_SECONDS:
        return _cached_executor

    _last_check_time = current_time

    if settings.JUDGE0_API_URL:
        try:
            resp = requests.get(
                f"{settings.JUDGE0_API_URL.rstrip('/')}/languages",
                timeout=0.5,
            )
            if resp.status_code == 200:
                _cached_executor = Judge0Executor()
                return _cached_executor
        except Exception:
            pass

    _cached_executor = SubprocessExecutor()
    return _cached_executor
