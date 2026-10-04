from datetime import datetime
from uuid import UUID
from typing import Any
from pydantic import BaseModel, ConfigDict, Field


class TestCaseItem(BaseModel):
    input: str
    expected: str
    is_hidden: bool = False


class CustomProblemCreate(BaseModel):
    title: str = Field(..., min_length=3, max_length=200)
    description: str = Field(..., min_length=10)
    starter_code: str = ""
    starter_code_python: str | None = ""
    starter_code_java: str | None = ""
    starter_code_cpp: str | None = ""
    test_cases: list[TestCaseItem] = Field(default_factory=list)
    visibility: str = Field(default="CLASS_ONLY")  # "CLASS_ONLY" | "PUBLIC"


class CustomProblemResponse(BaseModel):
    id: UUID
    teacher_id: UUID
    teacher_name: str | None = None
    title: str
    description: str
    starter_code: str | None = None
    starter_code_python: str | None = None
    starter_code_java: str | None = None
    starter_code_cpp: str | None = None
    test_cases: list[dict[str, Any]]
    visibility: str
    created_at: datetime
    total_submissions: int = 0
    accepted_submissions: int = 0
    is_completed: bool = False
    xp_reward: int = 50
    best_verdict: str | None = None
    languages: list[str] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)


class CustomProblemSubmissionItem(BaseModel):
    submission_id: UUID
    student_id: UUID
    student_name: str
    student_email: str | None = None
    verdict: str
    language: str
    runtime_ms: int | None = None
    xp_awarded: int = 0
    is_first_ac: bool = False
    created_at: datetime
    code: str


class CustomProblemSubmissionsResponse(BaseModel):
    items: list[CustomProblemSubmissionItem] = Field(default_factory=list)
    total_attempts: int
    successful_ac: int
    pass_rate: float


class CustomProblemStatsResponse(BaseModel):
    id: UUID
    title: str
    visibility: str
    total_attempts: int
    successful_submissions: int
    success_rate: float
    pass_rate: float = 0.0
    class_roster_stats: list[dict[str, Any]] = Field(default_factory=list)
    submissions: list[CustomProblemSubmissionItem] = Field(default_factory=list)
    public_stats_count: int = 0


class GenerateTemplatesRequest(BaseModel):
    code: str = ""
    language: str = "python"


class GenerateTemplatesResponse(BaseModel):
    starter_code_python: str
    starter_code_java: str
    starter_code_cpp: str

