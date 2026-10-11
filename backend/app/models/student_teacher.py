import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, ForeignKey, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base_model import BaseModel


class StudentTeacher(BaseModel):
    __tablename__ = "student_teachers"

    __table_args__ = (
        UniqueConstraint(
            "student_id",
            "teacher_id",
            name="uq_student_teacher_pair",
        ),
    )

    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    teacher_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    approved_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    request_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("mentorship_requests.id", ondelete="SET NULL"),
        nullable=True,
    )

    student = relationship(
        "User",
        foreign_keys=[student_id],
    )

    teacher = relationship(
        "User",
        foreign_keys=[teacher_id],
    )

    request = relationship(
        "MentorshipRequest",
        foreign_keys=[request_id],
    )
