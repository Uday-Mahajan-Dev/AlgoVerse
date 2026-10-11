import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import DateTime, Float, ForeignKey, Integer, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base_model import BaseModel


class QuizAttempt(BaseModel):
    __tablename__ = "quiz_attempts"

    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    quiz_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("quizzes.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    score: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
    )

    raw_score: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
    )

    final_score: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
    )

    total_time_seconds: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
    )

    time_taken_seconds: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
    )

    multiplier_applied: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=1.0,
    )

    answers: Mapped[list[dict[str, Any]]] = mapped_column(
        JSONB,
        nullable=False,
        default=list,
    )  # [{"question_id": str, "selected_index": int, "time_taken_seconds": int, "is_correct": bool}]

    submitted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    student = relationship(
        "User",
        foreign_keys=[student_id],
    )

    quiz = relationship(
        "Quiz",
        back_populates="attempts",
    )
