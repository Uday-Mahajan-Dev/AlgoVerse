from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class LessonResponse(BaseModel):
    id: UUID
    title: str
    slug: str
    content_type: str
    content_json: dict[str, Any] = Field(default_factory=dict)
    order_index: int = 0
    estimated_minutes: int = 10
    is_completed: bool = False

    model_config = ConfigDict(from_attributes=True)


class ModuleResponse(BaseModel):
    id: UUID
    title: str
    order_index: int = 0
    lessons: list[LessonResponse] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)


class CourseListResponse(BaseModel):
    id: UUID
    title: str
    slug: str
    description: str
    thumbnail_url: str | None = None
    difficulty: str
    topic_category: str
    module_count: int = 0
    total_lessons: int = 0
    enrollment_count: int = 0
    is_enrolled: bool = False

    model_config = ConfigDict(from_attributes=True)


class CourseDetailResponse(BaseModel):
    id: UUID
    title: str
    slug: str
    description: str
    thumbnail_url: str | None = None
    difficulty: str
    topic_category: str
    is_published: bool
    module_count: int = 0
    total_lessons: int = 0
    completed_lessons: int = 0
    completion_percentage: float = 0.0
    enrollment_count: int = 0
    is_enrolled: bool = False
    enrolled_at: datetime | None = None
    modules: list[ModuleResponse] = Field(default_factory=list)
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class EnrollmentResponse(BaseModel):
    course_id: UUID
    enrolled_at: datetime
    message: str = "Enrolled successfully"


class LessonCompletionResponse(BaseModel):
    lesson_id: UUID
    completed_at: datetime
    message: str = "Lesson marked as complete"


class CourseProgressResponse(BaseModel):
    course_id: UUID
    course_title: str
    course_slug: str
    total_lessons: int = 0
    completed_lessons: int = 0
    completion_percentage: float = 0.0
    last_completed_at: datetime | None = None
