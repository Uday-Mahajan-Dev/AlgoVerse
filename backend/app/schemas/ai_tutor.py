from typing import Any
from uuid import UUID
from pydantic import BaseModel, Field


class HintRequest(BaseModel):
    lesson_id: UUID
    hint_level: int = Field(..., ge=1, le=3, description="1 (gentle nudge), 2 (specific direction), 3 (approach reveal)")
    visualization_state: dict[str, Any] | None = None
    code: str | None = None
    error_info: str | None = None


class HintResponse(BaseModel):
    hint_text: str
    hint_level: int
    hints_remaining: int


class ErrorExplanationRequest(BaseModel):
    submission_id: UUID


class ErrorExplanationResponse(BaseModel):
    explanation: str
    failed_test_summary: str | None = None


class RecommendationItem(BaseModel):
    lesson_id: UUID
    lesson_title: str
    course_title: str
    reason: str
    priority: str = Field("medium", description="high, medium, low")


class RecommendationResponse(BaseModel):
    recommendations: list[RecommendationItem]


class AIFallbackResponse(BaseModel):
    message: str


class AIStatusResponse(BaseModel):
    configured: bool
    provider: str
    model: str
    message: str
