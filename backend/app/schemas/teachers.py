from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class TeacherListItem(BaseModel):
    id: UUID
    first_name: str
    last_name: str
    username: str
    avatar_url: str | None = None
    bio: str | None = None
    country: str | None = None
    student_count: int = 0
    specialty: str | None = None
    institution_name: str | None = None
    class_code: str | None = None

    model_config = ConfigDict(from_attributes=True)


class TeacherProfileResponse(BaseModel):
    id: UUID
    first_name: str
    last_name: str
    username: str
    email: str | None = None
    avatar_url: str | None = None
    bio: str | None = None
    country: str | None = None
    student_count: int = 0
    specialty: str | None = None
    institution_name: str | None = None
    class_code: str | None = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class TeacherSelectionResponse(BaseModel):
    message: str
    teacher_id: UUID
    teacher_name: str
    selected_at: datetime


class MyTeacherResponse(BaseModel):
    has_teacher: bool
    teacher: TeacherProfileResponse | None = None
    selected_at: datetime | None = None


class EducatorRegistrationRequest(BaseModel):
    institution_name: str
    subject_expertise: str
    bio: str | None = None


class EducatorRegistrationResponse(BaseModel):
    message: str
    role: str
    class_code: str
    institution_name: str
    subject_expertise: str
    bio: str | None = None


class JoinClassRequest(BaseModel):
    class_code: str


class JoinClassResponse(BaseModel):
    message: str
    teacher_id: UUID
    teacher_name: str
    institution_name: str | None = None
    class_code: str
    joined_at: datetime

