from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator


# --- Lesson Feedback Schemas ---

class LessonFeedbackCreate(BaseModel):
    rating: int = Field(..., ge=1, le=5, description="Star rating from 1 to 5")
    comment: str | None = Field(default=None, max_length=2000, description="Optional feedback text")


class LessonFeedbackResponse(BaseModel):
    id: UUID
    student_id: UUID
    lesson_id: UUID
    rating: int
    comment: str | None = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class LessonFeedbackSummary(BaseModel):
    avg_rating: float = 0.0
    rating_count: int = 0
    my_rating: int | None = None
    my_comment: str | None = None


# --- Problem Feedback Schemas ---

class ProblemFeedbackCreate(BaseModel):
    problem_kind: str = Field(default="course", description="'course' or 'custom'")
    rating: int = Field(..., ge=1, le=5, description="Star rating from 1 to 5")
    comment: str | None = Field(default=None, max_length=2000, description="Optional feedback text")


class ProblemFeedbackResponse(BaseModel):
    id: UUID
    student_id: UUID
    problem_id: UUID
    problem_kind: str
    rating: int
    comment: str | None = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ProblemFeedbackSummary(BaseModel):
    avg_rating: float = 0.0
    rating_count: int = 0
    my_rating: int | None = None
    my_comment: str | None = None


# --- Professor Rating Schemas ---

class ProfessorRatingCreate(BaseModel):
    rating: int = Field(..., ge=1, le=5, description="Star rating from 1 to 5")
    comment: str | None = Field(default=None, max_length=2000, description="Optional review text")


class ProfessorRatingItem(BaseModel):
    id: UUID
    student_id: UUID
    student_name: str
    student_avatar: str | None = None
    rating: int
    comment: str | None = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ProfessorRatingsSummary(BaseModel):
    avg_rating: float = 0.0
    rating_count: int = 0
    my_rating: int | None = None
    my_comment: str | None = None
    ratings: list[ProfessorRatingItem] = Field(default_factory=list)
