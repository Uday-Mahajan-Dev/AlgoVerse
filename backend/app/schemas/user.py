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

    country: str |None = None
    timezone: str | None = None

    preferred_language: str | None = None

    date_of_birth: date | None = None

    gender: str | None = None


class UserResponse(UserBase):
    id: UUID

    role_id: UUID

    is_active: bool
    email_verified: bool
    phone_verified: bool

    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True,
    )