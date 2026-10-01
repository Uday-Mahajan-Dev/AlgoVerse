from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field


class PublicTestCaseResponse(BaseModel):
    id: UUID
    stdin_input: str
    expected_stdout: str
    order_index: int

    model_config = ConfigDict(from_attributes=True)


class ProblemDetailResponse(BaseModel):
    id: UUID
    lesson_id: UUID
    lesson_slug: str
    title: str
    description: str
    function_name: str
    starter_code_python: str
    starter_code_java: str
    starter_code_cpp: str
    time_limit_ms: int
    memory_limit_mb: int
    public_test_cases: list[PublicTestCaseResponse] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)


class CodeExecutionRequest(BaseModel):
    code: str
    language: str  # "python", "java", "cpp"


class TestCaseExecutionResult(BaseModel):
    test_index: int
    is_hidden: bool
    passed: bool
    stdin_input: str | None = None
    expected_stdout: str | None = None
    actual_output: str | None = None
    execution_time_ms: int = 0
    error_message: str | None = None


class TrialResultResponse(BaseModel):
    verdict: str  # AC, WA, TLE, RE, CE, SE
    passed_count: int
    total_count: int
    execution_time_ms: int
    memory_used_kb: int
    test_results: list[TestCaseExecutionResult] = Field(default_factory=list)
    compile_output: str | None = None


class SubmissionResultResponse(BaseModel):
    submission_id: UUID
    verdict: str
    passed_count: int
    total_count: int
    execution_time_ms: int | None = None
    memory_used_kb: int | None = None
    failed_test_index: int | None = None
    message: str
    is_lesson_completed: bool = False


class SubmissionSummaryResponse(BaseModel):
    id: UUID
    problem_id: UUID
    language: str
    verdict: str
    execution_time_ms: int | None = None
    memory_used_kb: int | None = None
    passed_count: int
    total_count: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
