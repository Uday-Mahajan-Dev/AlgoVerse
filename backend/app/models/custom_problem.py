import uuid
from typing import Any

from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base_model import BaseModel


class CustomProblem(BaseModel):
    __tablename__ = "custom_problems"

    teacher_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    title: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
    )

    description: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    starter_code: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
        default="",
    )

    starter_code_python: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
        default="",
    )

    starter_code_java: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
        default="",
    )

    starter_code_cpp: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
        default="",
    )

    test_cases: Mapped[list[dict[str, Any]]] = mapped_column(
        JSONB,
        nullable=False,
        default=list,
    )  # [{"input": "...", "expected": "...", "is_hidden": bool}]

    visibility: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="CLASS_ONLY",
        index=True,
    )  # "CLASS_ONLY" or "PUBLIC"

    teacher = relationship(
        "User",
        foreign_keys=[teacher_id],
    )
