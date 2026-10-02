import uuid
from datetime import datetime, date

from sqlalchemy import Date, DateTime, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base_model import BaseModel


class TAApprovalRequest(BaseModel):
    __tablename__ = "ta_approval_requests"

    applicant_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    supervisor_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    status: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="PENDING",
        index=True,
    )

    requested_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    responded_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    institution_name: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
        default="",
    )

    designation: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        default="Teaching Assistant",
    )

    subject_expertise: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
        default="",
    )

    bio: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    date_of_birth: Mapped[date | None] = mapped_column(
        Date,
        nullable=True,
    )

    applicant = relationship(
        "User",
        foreign_keys=[applicant_id],
    )

    supervisor = relationship(
        "User",
        foreign_keys=[supervisor_id],
    )
