"""allow custom problem submissions

Revision ID: m1a2b3c4d5e6
Revises: l1a2b3c4d5e6
Create Date: 2026-10-04 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'm1a2b3c4d5e6'
down_revision: Union[str, Sequence[str], None] = 'l1a2b3c4d5e6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Drop FK constraint on submissions.problem_id to allow custom problem IDs
    op.execute("""
        DO $$
        BEGIN
            IF EXISTS (
                SELECT 1 FROM information_schema.table_constraints
                WHERE constraint_name = 'submissions_problem_id_fkey'
                AND table_name = 'submissions'
            ) THEN
                ALTER TABLE submissions DROP CONSTRAINT submissions_problem_id_fkey;
            END IF;
        END $$;
    """)


def downgrade() -> None:
    pass
