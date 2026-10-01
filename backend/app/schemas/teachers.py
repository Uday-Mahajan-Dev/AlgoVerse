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
