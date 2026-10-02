import uuid

from sqlalchemy import Boolean, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base_model import BaseModel


class TeacherProfile(BaseModel):
    __tablename__ = "teacher_profiles"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )

    institution_name: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
        default="",
    )

    subject_expertise: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
        default="Data Structures & Algorithms",
    )

    bio: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    class_code: Mapped[str] = mapped_column(
        String(20),
        unique=True,
        nullable=False,
        index=True,
    )

    is_verified: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )

    user = relationship(
        "User",
        back_populates="teacher_profile",
    )
