"""add test case explanations and default hidden

Revision ID: q1a2b3c4d5e6
Revises: p1a2b3c4d5e6
Create Date: 2026-10-11 02:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'q1a2b3c4d5e6'
down_revision: Union[str, Sequence[str], None] = 'p1a2b3c4d5e6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Update test_cases table
    op.execute("""
        ALTER TABLE test_cases ADD COLUMN IF NOT EXISTS explanation TEXT;
        ALTER TABLE test_cases ALTER COLUMN is_hidden SET DEFAULT true;
        UPDATE test_cases SET is_hidden = true WHERE is_hidden IS NULL;
    """)


def downgrade() -> None:
    op.execute("""
        ALTER TABLE test_cases DROP COLUMN IF EXISTS explanation;
        ALTER TABLE test_cases ALTER COLUMN is_hidden SET DEFAULT false;
    """)
