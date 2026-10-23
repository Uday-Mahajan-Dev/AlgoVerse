from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr
from sqlalchemy import select
from sqlalchemy.orm import Session


class UserBase(BaseModel):
    username: str
    email: EmailStr
    phone_number: str | None = None

    first_name: str
    last_name: str

    avatar_url: str | None = None
    cover_image_url: str | None = None

    bio: str | None = None

    country: str | None = None
    timezone: str | None = None

    preferred_language: str | None = None

    date_of_birth: date | None = None
    dob_source: str | None = None

    gender: str | None = None

    instagram_url: str | None = None
    linkedin_url: str | None = None


class UserCreate(UserBase):
    password: str


class UserUpdate(BaseModel):
    username: str | None = None
    first_name: str | None = None
    last_name: str | None = None

    avatar_url: str | None = None
    cover_image_url: str | None = None

    bio: str | None = None

    country: str | None = None
    timezone: str | None = None

    preferred_language: str | None = None

    date_of_birth: date | None = None
    dob_source: str | None = None

    gender: str | None = None

    instagram_url: str | None = None
    linkedin_url: str | None = None


class UserResponse(UserBase):
    id: UUID

    role_id: UUID
    role_name: str

    is_active: bool
    email_verified: bool
    phone_verified: bool

    class_code: str | None = None
    institution_name: str | None = None
    designation: str | None = None
    subject_expertise: str | None = None
    ta_application_status: str | None = None
    educator_application_status: str | None = None
    is_dob_locked: bool = False
    auth_providers: list[str] = []
    is_verified: bool | None = None

    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True,
    )

    @classmethod
    def from_user(cls, user, db: Session | None = None):
        class_code = None
        institution_name = None
        designation = None
        subject_expertise = None
        if hasattr(user, "teacher_profile") and user.teacher_profile:
            class_code = user.teacher_profile.class_code
            institution_name = user.teacher_profile.institution_name
            designation = getattr(user.teacher_profile, "designation", None)
            subject_expertise = user.teacher_profile.subject_expertise

        ta_application_status = None
        educator_application_status = None
        is_dob_locked = False

        if db is not None:
            from app.models.ta_approval_request import TAApprovalRequest
            from app.models.educator_application import EducatorApplication

            pending_req = db.scalar(
                select(TAApprovalRequest).where(
                    TAApprovalRequest.applicant_id == user.id,
                    TAApprovalRequest.status == "PENDING",
                )
            )
            if pending_req:
                ta_application_status = "PENDING"

            latest_app = db.scalar(
                select(EducatorApplication)
                .where(EducatorApplication.user_id == user.id)
                .order_by(EducatorApplication.created_at.desc())
                .limit(1)
            )
            if latest_app:
                educator_application_status = latest_app.status
                if latest_app.status in ("PENDING", "APPROVED"):
                    is_dob_locked = True

        if getattr(user, "teacher_profile", None) and user.teacher_profile and user.teacher_profile.is_verified:
            is_dob_locked = True

        return cls(
            username=user.username,
            email=user.email,
            phone_number=user.phone_number,
            first_name=user.first_name,
            last_name=user.last_name,
            avatar_url=user.avatar_url,
            cover_image_url=user.cover_image_url,
            bio=user.bio,
            country=user.country,
            timezone=user.timezone,
            preferred_language=user.preferred_language,
            date_of_birth=user.date_of_birth,
            dob_source=getattr(user, "dob_source", None),
            gender=user.gender,
            instagram_url=getattr(user, "instagram_url", None),
            linkedin_url=getattr(user, "linkedin_url", None),
            id=user.id,
            role_id=user.role_id,
            role_name=user.role.name,
            is_active=user.is_active,
            email_verified=user.email_verified,
            phone_verified=user.phone_verified,
            class_code=class_code,
            institution_name=institution_name,
            designation=designation,
            subject_expertise=subject_expertise,
            ta_application_status=ta_application_status,
            educator_application_status=educator_application_status,
            is_dob_locked=is_dob_locked,
            auth_providers=[
                str(getattr(p, 'provider', '')).lower()
                for p in getattr(user, 'auth_providers', [])
            ],
            is_verified=getattr(user.teacher_profile, "is_verified", False) if hasattr(user, "teacher_profile") and user.teacher_profile else None,
            created_at=user.created_at,
            updated_at=user.updated_at,
        )