import uuid
from datetime import date, datetime
from sqlalchemy import (
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    text,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base_model import BaseModel


class EducatorApplication(BaseModel):
    __tablename__ = "educator_applications"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    requested_role: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
    )  # PROFESSOR | ASSISTANT

    date_of_birth_at_application: Mapped[date] = mapped_column(
        Date,
        nullable=False,
    )

    age_at_application: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )

    institution_name: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
    )

    designation: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    subject_expertise: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
    )

    bio: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    supervisor_email: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )

    status: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="PENDING",
        server_default="PENDING",
        index=True,
    )  # PENDING | APPROVED | REJECTED | CANCELLED

    admin_note: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    reviewed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    reviewed_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )

    user = relationship(
        "User",
        foreign_keys=[user_id],
        back_populates="educator_applications",
    )

    reviewer = relationship(
        "User",
        foreign_keys=[reviewed_by],
    )

    __table_args__ = (
        Index(
            "uq_educator_app_user_pending",
            "user_id",
            unique=True,
            postgresql_where=text("status = 'PENDING'"),
        ),
    )
