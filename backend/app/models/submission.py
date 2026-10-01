import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base_class import Base


class Submission(Base):
    __tablename__ = "submissions"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    problem_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("problems.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    code: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    language: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
    )

    verdict: Mapped[str] = mapped_column(
        String(10),
        nullable=False,
    )

    execution_time_ms: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
    )

    memory_used_kb: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
    )

    passed_count: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False,
    )

    total_count: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False,
    )

    failed_test_index: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
    )

    actual_output: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    error_message: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    student = relationship(
        "User",
        foreign_keys=[student_id],
    )

    problem = relationship(
        "Problem",
        back_populates="submissions",
        foreign_keys=[problem_id],
    )
