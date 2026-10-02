import time
import requests

from app.core.config import settings
from app.services.code_execution.base_executor import BaseCodeExecutor
from app.services.code_execution.judge0_executor import Judge0Executor
from app.services.code_execution.subprocess_executor import SubprocessExecutor

_cached_executor: BaseCodeExecutor | None = None
_last_check_time: float = 0.0
_CHECK_INTERVAL_SECONDS = 30.0


def check_judge0_reachability(timeout: float = 2.0) -> bool:
    """Check if Judge0 instance is reachable and healthy."""
    if not settings.JUDGE0_API_URL:
        return False
    try:
        url = f"{settings.JUDGE0_API_URL.rstrip('/')}/languages"
        resp = requests.get(url, timeout=timeout)
        return resp.status_code == 200
    except Exception:
        return False


def get_executor(force_check: bool = False) -> BaseCodeExecutor:
    """Auto-detect Judge0 service availability and return Judge0Executor or Fallback SubprocessExecutor."""
    global _cached_executor, _last_check_time

    current_time = time.time()
    if not force_check and _cached_executor is not None and (current_time - _last_check_time) < _CHECK_INTERVAL_SECONDS:
        return _cached_executor

    _last_check_time = current_time

    if check_judge0_reachability(timeout=2.0):
        _cached_executor = Judge0Executor()
    else:
        _cached_executor = SubprocessExecutor()

    return _cached_executor


def get_executor_status() -> dict:
    """Return current executor status information."""
    reachable = check_judge0_reachability(timeout=2.0)
    executor_name = "judge0" if reachable else "subprocess"
    return {
        "executor": executor_name,
        "judge0_url": settings.JUDGE0_API_URL or "",
        "reachable": reachable,
        "supported_languages": ["python", "java", "cpp"] if reachable else ["python"],
    }

