from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class MentorshipRequestCreate(BaseModel):
    teacher_id: UUID | None = None
    class_code: str | None = None
    message: str | None = Field(None, max_length=500)


class MentorshipRequestResponse(BaseModel):
    id: UUID
    student_id: UUID
    teacher_id: UUID
    class_code_attempted: str | None = None
    status: str
    message: str | None = None
    created_at: datetime
    resolved_at: datetime | None = None
    resolved_by: UUID | None = None

    # Student details
    student_name: str
    student_username: str
    student_email: str
    student_avatar: str | None = None

    # Teacher details
    teacher_name: str
    teacher_username: str
    teacher_institution: str | None = None
    teacher_designation: str | None = None
    teacher_avatar: str | None = None

    model_config = ConfigDict(from_attributes=True)


class ClassroomSettingsRequest(BaseModel):
    max_students: int | None = Field(None, ge=1, le=5000)
    is_accepting_requests: bool | None = None


class ClassroomSettingsResponse(BaseModel):
    teacher_id: UUID
    max_students: int
    is_accepting_requests: bool
    current_student_count: int
    capacity_pct: float
    class_code: str


class ProfessorListItem(BaseModel):
    id: UUID
    first_name: str
    last_name: str
    username: str
    avatar_url: str | None = None
    institution_name: str | None = None
    designation: str | None = None
    specialty: str
    student_count: int
    max_students: int
    is_accepting_requests: bool
    is_verified: bool
    rating_avg: float = 0.0
    avg_rating: float = 0.0
    rating_count: int = 0
    class_code: str | None = None


class StudentMentorItem(BaseModel):
    teacher_id: UUID
    teacher_name: str
    teacher_username: str
    teacher_avatar: str | None = None
    institution_name: str | None = None
    designation: str | None = None
    specialty: str | None = None
    class_code: str | None = None
    approved_at: datetime
