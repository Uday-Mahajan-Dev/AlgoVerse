import uuid
from sqlalchemy import (
    Boolean,
    ForeignKey,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base_model import BaseModel


class Course(BaseModel):
    __tablename__ = "courses"

    title: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    slug: Mapped[str] = mapped_column(
        String(255),
        unique=True,
        nullable=False,
        index=True,
    )

    description: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    thumbnail_url: Mapped[str | None] = mapped_column(
        String(512),
        nullable=True,
    )

    difficulty: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
    )

    topic_category: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    is_published: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )

    created_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )

    creator = relationship(
        "User",
        foreign_keys=[created_by],
    )

    modules = relationship(
        "CourseModule",
        back_populates="course",
        cascade="all, delete-orphan",
        order_by="CourseModule.order_index",
    )

    enrollments = relationship(
        "CourseEnrollment",
        back_populates="course",
        cascade="all, delete-orphan",
    )
