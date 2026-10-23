from datetime import date, datetime
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field


class EducatorApplicationCreate(BaseModel):
    requested_role: str = Field(..., description="PROFESSOR or ASSISTANT")
    date_of_birth: date
    institution_name: str = Field(..., min_length=2, max_length=200)
    designation: str = Field(..., min_length=2, max_length=100)
    subject_expertise: str = Field(..., min_length=2, max_length=200)
    bio: str | None = Field(None, max_length=2000)
    supervisor_email: str | None = Field(None, max_length=255)


class EducatorApplicationRejectRequest(BaseModel):
    admin_note: str | None = None


class EducatorApplicationResponse(BaseModel):
    id: UUID
    user_id: UUID
    applicant_name: str | None = None
    applicant_email: str | None = None
    requested_role: str
    date_of_birth_at_application: date
    age_at_application: int
    institution_name: str
    designation: str
    subject_expertise: str
    bio: str | None = None
    supervisor_email: str | None = None
    status: str
    admin_note: str | None = None
    created_at: datetime
    reviewed_at: datetime | None = None
    reviewed_by: UUID | None = None

    model_config = ConfigDict(from_attributes=True)

    @classmethod
    def from_model(cls, app_model) -> "EducatorApplicationResponse":
        u = getattr(app_model, "user", None)
        full_name = None
        email = None
        if u:
            full_name = f"{u.first_name or ''} {u.last_name or ''}".strip()
            if not full_name:
                full_name = u.username
            email = u.email

        return cls(
            id=app_model.id,
            user_id=app_model.user_id,
            applicant_name=full_name,
            applicant_email=email,
            requested_role=app_model.requested_role,
            date_of_birth_at_application=app_model.date_of_birth_at_application,
            age_at_application=app_model.age_at_application,
            institution_name=app_model.institution_name,
            designation=app_model.designation,
            subject_expertise=app_model.subject_expertise,
            bio=app_model.bio,
            supervisor_email=app_model.supervisor_email,
            status=app_model.status,
            admin_note=app_model.admin_note,
            created_at=app_model.created_at,
            reviewed_at=app_model.reviewed_at,
            reviewed_by=app_model.reviewed_by,
        )
