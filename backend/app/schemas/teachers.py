from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr


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
    designation: str | None = None
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
    designation: str | None = None
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
    designation: str = "Professor"
    subject_expertise: str
    professional_bio: str | None = None
    bio: str | None = None  # alias support
    date_of_birth: date
    supervisor_email: EmailStr | None = None


class EducatorRegistrationResponse(BaseModel):
    status: str = "APPROVED"  # APPROVED | PENDING_SUPERVISOR_APPROVAL
    message: str
    role: str
    class_code: str | None = None
    institution_name: str
    designation: str
    subject_expertise: str
    bio: str | None = None


class TARequestResponse(BaseModel):
    id: UUID
    applicant_id: UUID
    applicant_name: str
    applicant_email: str
    applicant_username: str
    applicant_avatar_url: str | None = None
    institution_name: str
    designation: str
    subject_expertise: str
    bio: str | None = None
    date_of_birth: date | None = None
    status: str
    requested_at: datetime
    responded_at: datetime | None = None

    model_config = ConfigDict(from_attributes=True)


class TAResponseActionRequest(BaseModel):
    action: str  # APPROVE | REJECT


class TAResponseActionResult(BaseModel):
    message: str
    request_id: UUID
    status: str
    applicant_id: UUID


class JoinClassRequest(BaseModel):
    class_code: str


class JoinClassResponse(BaseModel):
    message: str
    teacher_id: UUID
    teacher_name: str
    institution_name: str | None = None
    class_code: str
    joined_at: datetime
