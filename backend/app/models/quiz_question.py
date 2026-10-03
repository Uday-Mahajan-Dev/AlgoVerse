import uuid

from sqlalchemy import ForeignKey, Integer, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base_model import BaseModel


class QuizQuestion(BaseModel):
    __tablename__ = "quiz_questions"

    quiz_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("quizzes.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    question_text: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    options: Mapped[list[str]] = mapped_column(
        JSONB,
        nullable=False,
    )  # 4 options: ["opt1", "opt2", "opt3", "opt4"]

    correct_option_index: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )  # 0-3

    order_index: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
    )

    quiz = relationship(
        "Quiz",
        back_populates="questions",
    )
