from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr


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

    gender: str | None = None


class UserCreate(UserBase):
    password: str


class UserUpdate(BaseModel):
    first_name: str | None = None
    last_name: str | None = None

    avatar_url: str | None = None
    cover_image_url: str | None = None

    bio: str | None = None

    country: str | None = None
    timezone: str | None = None

    preferred_language: str | None = None

    date_of_birth: date | None = None

    gender: str | None = None


class UserResponse(UserBase):
    id: UUID

    role_id: UUID
    role_name: str

    is_active: bool
    email_verified: bool
    phone_verified: bool

    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True,
    )

    @classmethod
    def from_user(cls, user):
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
            gender=user.gender,
            id=user.id,
            role_id=user.role_id,
            role_name=user.role.name,
            is_active=user.is_active,
            email_verified=user.email_verified,
            phone_verified=user.phone_verified,
            created_at=user.created_at,
            updated_at=user.updated_at,
        )