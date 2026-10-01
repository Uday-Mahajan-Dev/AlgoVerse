import uuid

from sqlalchemy import ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base_model import BaseModel


class StudentTeacher(BaseModel):
    __tablename__ = "student_teachers"

    __table_args__ = (
        UniqueConstraint(
            "student_id",
            name="uq_student_teacher_student",
        ),
    )

    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )

    teacher_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    student = relationship(
        "User",
        foreign_keys=[student_id],
    )

    teacher = relationship(
        "User",
        foreign_keys=[teacher_id],
    )
