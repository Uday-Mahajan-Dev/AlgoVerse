import uuid

from sqlalchemy import (
    Boolean,
    Date,
    ForeignKey,
    String,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base_model import BaseModel


class User(BaseModel):
    __tablename__ = "users"

    username: Mapped[str] = mapped_column(
        String(30),
        unique=True,
        nullable=False,
        index=True,
    )

    email: Mapped[str] = mapped_column(
        String(255),
        unique=True,
        nullable=False,
        index=True,
    )

    hashed_password: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    first_name: Mapped[str] = mapped_column(
        String(100),
    )

    last_name: Mapped[str] = mapped_column(
        String(100),
    )

    avatar_url: Mapped[str | None] = mapped_column(
        String(500),
    )

    cover_image_url: Mapped[str | None] = mapped_column(
        String(500),
    )

    bio: Mapped[str | None] = mapped_column(
        String(500),
    )

    country: Mapped[str | None] = mapped_column(
        String(100),
    )

    timezone: Mapped[str | None] = mapped_column(
        String(100),
    )

    preferred_language: Mapped[str | None] = mapped_column(
        String(30),
    )

    date_of_birth: Mapped[Date | None] = mapped_column(
        Date,
    )

    gender: Mapped[str | None] = mapped_column(
        String(20),
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
    )

    email_verified: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )

    phone_number: Mapped[str | None] = mapped_column(
        String(20),
        unique=True,
        nullable=True,
    )

    phone_verified: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )

    role_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("roles.id"),
        nullable=False,
    )

    role = relationship(
        "Role",
        back_populates="users",
    )

    refresh_tokens = relationship(
        "RefreshToken",
        back_populates="user",
        cascade="all, delete-orphan",
    )

    email_otps = relationship(
        "EmailOTP",
        back_populates="user",
        cascade="all, delete-orphan",
    )

    auth_providers = relationship(
        "AuthProvider",
        back_populates="user",
        cascade="all, delete-orphan",
    )

    teacher_profile = relationship(
        "TeacherProfile",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )

