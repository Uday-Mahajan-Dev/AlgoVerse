import uuid
from sqlalchemy import ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base_model import BaseModel


class Lesson(BaseModel):
    __tablename__ = "lessons"

    module_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("course_modules.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

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

    content_type: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
    )  # CONCEPT, VISUALIZATION, PROBLEM

    content_json: Mapped[dict] = mapped_column(
        JSONB,
        default=dict,
        nullable=False,
    )

    order_index: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False,
    )

    estimated_minutes: Mapped[int] = mapped_column(
        Integer,
        default=10,
        nullable=False,
    )

    module = relationship(
        "CourseModule",
        back_populates="lessons",
    )

    completions = relationship(
        "LessonCompletion",
        back_populates="lesson",
        cascade="all, delete-orphan",
    )
