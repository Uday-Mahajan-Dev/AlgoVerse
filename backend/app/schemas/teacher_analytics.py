from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field


class RecentActivityItem(BaseModel):
    student_name: str
    student_avatar: str | None = None
    action_type: str  # "COMPLETED_LESSON", "SUBMITTED_AC", "SUBMITTED_WA", etc.
    item_title: str
    timestamp: datetime


class TeacherOverviewResponse(BaseModel):
    total_students: int
    active_students: int
    avg_course_completion: float
    total_submissions_today: int
    recent_activity_feed: list[RecentActivityItem] = Field(default_factory=list)


class StudentProgressResponse(BaseModel):
    student_id: UUID
    student_name: str
    student_username: str
    student_email: str
    student_avatar: str | None = None
    courses_enrolled: int
    lessons_completed: int
    current_streak: int
    last_active_at: datetime | None = None
    overall_completion_pct: float
    status: str  # "active" | "at_risk" | "inactive"


class BottleneckLessonResponse(BaseModel):
    lesson_id: UUID
    lesson_slug: str
    lesson_title: str
    module_title: str
    course_title: str
    course_slug: str
    content_type: str
    total_students_enrolled: int
    completion_count: int
    completion_rate: float  # e.g. 0.23 -> 23%
    avg_attempts: float
    failure_rate: float


class ConceptPerformanceResponse(BaseModel):
    module_id: UUID
    module_title: str
    course_title: str
    course_slug: str
    total_lessons: int
    avg_completion_rate: float  # e.g. 0.82 -> 82%
    weak_lesson_count: int
    status: str  # "strong" (>80%) | "moderate" (50-80%) | "weak" (<50%)


class AssignmentCreateRequest(BaseModel):
    student_ids: list[UUID]
    lesson_id: UUID
    due_date: datetime | None = None
    notes: str | None = None


class AssignmentResponse(BaseModel):
    id: UUID
    teacher_id: UUID
    teacher_name: str
    student_id: UUID
    student_name: str
    lesson_id: UUID
    lesson_slug: str
    lesson_title: str
    course_title: str
    course_slug: str
    assigned_at: datetime
    due_date: datetime | None = None
    status: str  # "pending", "completed", "overdue"
    notes: str | None = None
    completed_at: datetime | None = None

    model_config = ConfigDict(from_attributes=True)
