"""add quiz time scoring and multiplier

Revision ID: r1a2b3c4d5e6
Revises: q1a2b3c4d5e6
Create Date: 2026-10-11 03:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'r1a2b3c4d5e6'
down_revision: Union[str, Sequence[str], None] = 'q1a2b3c4d5e6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Update quizzes table
    op.execute("""
        ALTER TABLE quizzes
        ADD COLUMN IF NOT EXISTS scoring_mode VARCHAR(20) NOT NULL DEFAULT 'FLAT',
        ADD COLUMN IF NOT EXISTS time_limit_seconds INTEGER,
        ADD COLUMN IF NOT EXISTS min_multiplier DOUBLE PRECISION NOT NULL DEFAULT 0.5,
        ADD COLUMN IF NOT EXISTS decay DOUBLE PRECISION NOT NULL DEFAULT 0.5;
    """)

    # 2. Update quiz_attempts table
    op.execute("""
        ALTER TABLE quiz_attempts
        ADD COLUMN IF NOT EXISTS raw_score INTEGER NOT NULL DEFAULT 0,
        ADD COLUMN IF NOT EXISTS final_score INTEGER NOT NULL DEFAULT 0,
        ADD COLUMN IF NOT EXISTS time_taken_seconds INTEGER NOT NULL DEFAULT 0,
        ADD COLUMN IF NOT EXISTS multiplier_applied DOUBLE PRECISION NOT NULL DEFAULT 1.0;

        -- Backfill existing attempts
        UPDATE quiz_attempts
        SET raw_score = score,
            final_score = score,
            time_taken_seconds = total_time_seconds,
            multiplier_applied = 1.0
        WHERE final_score = 0 AND score > 0;
    """)


def downgrade() -> None:
    op.execute("""
        ALTER TABLE quiz_attempts
        DROP COLUMN IF EXISTS raw_score,
        DROP COLUMN IF EXISTS final_score,
        DROP COLUMN IF EXISTS time_taken_seconds,
        DROP COLUMN IF EXISTS multiplier_applied;

        ALTER TABLE quizzes
        DROP COLUMN IF EXISTS scoring_mode,
        DROP COLUMN IF EXISTS time_limit_seconds,
        DROP COLUMN IF EXISTS min_multiplier,
        DROP COLUMN IF EXISTS decay;
    """)
