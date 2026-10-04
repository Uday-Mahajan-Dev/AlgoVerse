"""add custom problem completions and submission xp

Revision ID: n1a2b3c4d5e6
Revises: m1a2b3c4d5e6
Create Date: 2026-10-04 18:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID


# revision identifiers, used by Alembic.
revision: str = 'n1a2b3c4d5e6'
down_revision: Union[str, Sequence[str], None] = 'm1a2b3c4d5e6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Add columns to submissions table if not already present
    op.execute("""
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name = 'submissions' AND column_name = 'is_first_ac'
            ) THEN
                ALTER TABLE submissions ADD COLUMN is_first_ac BOOLEAN NOT NULL DEFAULT FALSE;
            END IF;

            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name = 'submissions' AND column_name = 'xp_awarded'
            ) THEN
                ALTER TABLE submissions ADD COLUMN xp_awarded INTEGER NOT NULL DEFAULT 0;
            END IF;
        END $$;
    """)

    # 2. Create custom_problem_completions table
    op.execute("""
        CREATE TABLE IF NOT EXISTS custom_problem_completions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            custom_problem_id UUID NOT NULL REFERENCES custom_problems(id) ON DELETE CASCADE,
            first_ac_submission_id UUID REFERENCES submissions(id) ON DELETE SET NULL,
            xp_awarded INTEGER NOT NULL DEFAULT 50,
            completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            CONSTRAINT uq_student_custom_problem_completion UNIQUE (student_id, custom_problem_id)
        );

        CREATE INDEX IF NOT EXISTS ix_custom_problem_completions_student_id ON custom_problem_completions (student_id);
        CREATE INDEX IF NOT EXISTS ix_custom_problem_completions_custom_problem_id ON custom_problem_completions (custom_problem_id);
    """)


def downgrade() -> None:
    op.execute("""
        DROP TABLE IF EXISTS custom_problem_completions CASCADE;
        ALTER TABLE submissions DROP COLUMN IF EXISTS is_first_ac;
        ALTER TABLE submissions DROP COLUMN IF EXISTS xp_awarded;
    """)
