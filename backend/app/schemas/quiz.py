from datetime import datetime
from uuid import UUID
from typing import Any
from pydantic import BaseModel, ConfigDict, Field


class QuizQuestionCreate(BaseModel):
    question_text: str = Field(..., min_length=3)
    options: list[str] = Field(..., min_length=2, max_length=4)
    correct_option_index: int = Field(..., ge=0, le=3)
    order_index: int = 0


class QuizQuestionResponse(BaseModel):
    id: UUID
    quiz_id: UUID
    question_text: str
    options: list[str]
    correct_option_index: int | None = None  # None for students during gameplay
    order_index: int

    model_config = ConfigDict(from_attributes=True)


class QuizCreate(BaseModel):
    title: str = Field(..., min_length=3, max_length=200)
    description: str = Field(default="")
    visibility: str = Field(default="CLASS_ONLY")  # "CLASS_ONLY" | "PUBLIC"
    time_per_question_seconds: int = Field(default=30, ge=10, le=120)
    questions: list[QuizQuestionCreate] = Field(..., min_length=1)


class QuizResponse(BaseModel):
    id: UUID
    teacher_id: UUID
    teacher_name: str | None = None
    title: str
    description: str
    visibility: str
    time_per_question_seconds: int
    question_count: int
    created_at: datetime
    questions: list[QuizQuestionResponse] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)


class QuizAnswerItem(BaseModel):
    question_id: UUID
    selected_index: int  # 0 to 3
    time_taken_seconds: int = Field(default=0, ge=0)


class QuizSubmitRequest(BaseModel):
    answers: list[QuizAnswerItem]


class QuizSubmitResponse(BaseModel):
    attempt_id: UUID
    quiz_id: UUID
    score: int
    max_possible_score: int
    correct_count: int
    total_questions: int
    total_time_seconds: int
    rank: int | None = None
    submitted_at: datetime


class QuizLeaderboardEntry(BaseModel):
    rank: int
    student_id: UUID
    student_name: str
    avatar_url: str | None = None
    score: int
    total_time_seconds: int
    submitted_at: datetime


class QuizAttemptDetail(BaseModel):
    student_id: UUID
    student_name: str
    is_class_student: bool
    score: int
    total_time_seconds: int
    submitted_at: datetime
    answers: list[dict[str, Any]] = Field(default_factory=list)


class QuizStatsResponse(BaseModel):
    quiz_id: UUID
    title: str
    visibility: str
    total_attempts: int
    average_score: float
    highest_score: int
    class_attempts: list[QuizAttemptDetail] = Field(default_factory=list)
    top_scorers: list[QuizLeaderboardEntry] = Field(default_factory=list)
