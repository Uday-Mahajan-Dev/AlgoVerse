import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base_class import Base


class Problem(Base):
    __tablename__ = "problems"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    lesson_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("lessons.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )

    title: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    description: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    function_name: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    starter_code_python: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    starter_code_java: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    starter_code_cpp: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    solution_code_python: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    solution_code_java: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    solution_code_cpp: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    time_limit_ms: Mapped[int] = mapped_column(
        Integer,
        default=2000,
        nullable=False,
    )

    memory_limit_mb: Mapped[int] = mapped_column(
        Integer,
        default=64,
        nullable=False,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    lesson = relationship(
        "Lesson",
        back_populates="problem",
    )

    test_cases = relationship(
        "TestCase",
        back_populates="problem",
        cascade="all, delete-orphan",
        order_by="TestCase.order_index",
    )

    submissions = relationship(
        "Submission",
        back_populates="problem",
        cascade="all, delete-orphan",
    )
