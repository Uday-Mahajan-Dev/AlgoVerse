"""add feedback and ratings

Revision ID: p1a2b3c4d5e6
Revises: o1a2b3c4d5e6
Create Date: 2026-10-11 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'p1a2b3c4d5e6'
down_revision: Union[str, Sequence[str], None] = 'o1a2b3c4d5e6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Create lesson_feedback table
    op.execute("""
        CREATE TABLE IF NOT EXISTS lesson_feedback (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
            rating INTEGER NOT NULL,
            comment TEXT,
            created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
            updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
            CONSTRAINT uq_lesson_feedback_student_lesson UNIQUE (student_id, lesson_id),
            CONSTRAINT chk_lesson_feedback_rating_range CHECK (rating >= 1 AND rating <= 5)
        );
        CREATE INDEX IF NOT EXISTS ix_lesson_feedback_student_id ON lesson_feedback(student_id);
        CREATE INDEX IF NOT EXISTS ix_lesson_feedback_lesson_id ON lesson_feedback(lesson_id);
    """)

    # 2. Create problem_feedback table
    op.execute("""
        CREATE TABLE IF NOT EXISTS problem_feedback (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            problem_id UUID NOT NULL,
            problem_kind VARCHAR(20) NOT NULL DEFAULT 'course',
            rating INTEGER NOT NULL,
            comment TEXT,
            created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
            updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
            CONSTRAINT uq_problem_feedback_student_problem_kind UNIQUE (student_id, problem_id, problem_kind),
            CONSTRAINT chk_problem_feedback_rating_range CHECK (rating >= 1 AND rating <= 5),
            CONSTRAINT chk_problem_feedback_kind_valid CHECK (problem_kind IN ('course', 'custom'))
        );
        CREATE INDEX IF NOT EXISTS ix_problem_feedback_student_id ON problem_feedback(student_id);
        CREATE INDEX IF NOT EXISTS ix_problem_feedback_problem_id ON problem_feedback(problem_id);
        CREATE INDEX IF NOT EXISTS ix_problem_feedback_problem_kind ON problem_feedback(problem_kind);
    """)

    # 3. Create professor_ratings table
    op.execute("""
        CREATE TABLE IF NOT EXISTS professor_ratings (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            rating INTEGER NOT NULL,
            comment TEXT,
            created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
            updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
            CONSTRAINT uq_professor_ratings_student_teacher UNIQUE (student_id, teacher_id),
            CONSTRAINT chk_professor_ratings_rating_range CHECK (rating >= 1 AND rating <= 5)
        );
        CREATE INDEX IF NOT EXISTS ix_professor_ratings_student_id ON professor_ratings(student_id);
        CREATE INDEX IF NOT EXISTS ix_professor_ratings_teacher_id ON professor_ratings(teacher_id);
    """)


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS professor_ratings CASCADE;")
    op.execute("DROP TABLE IF EXISTS problem_feedback CASCADE;")
    op.execute("DROP TABLE IF EXISTS lesson_feedback CASCADE;")
