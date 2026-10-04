import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base_class import Base


class CustomProblemCompletion(Base):
    __tablename__ = "custom_problem_completions"

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

    custom_problem_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("custom_problems.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    first_ac_submission_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("submissions.id", ondelete="SET NULL"),
        nullable=True,
    )

    xp_awarded: Mapped[int] = mapped_column(
        Integer,
        default=50,
        nullable=False,
    )

    completed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    student = relationship(
        "User",
        foreign_keys=[student_id],
    )

    custom_problem = relationship(
        "CustomProblem",
        foreign_keys=[custom_problem_id],
    )

    first_ac_submission = relationship(
        "Submission",
        foreign_keys=[first_ac_submission_id],
    )

    __table_args__ = (
        UniqueConstraint(
            "student_id",
            "custom_problem_id",
            name="uq_student_custom_problem_completion",
        ),
    )
