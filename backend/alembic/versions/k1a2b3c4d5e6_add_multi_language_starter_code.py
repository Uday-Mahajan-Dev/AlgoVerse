"""add multi-language starter code to custom_problems

Revision ID: k1a2b3c4d5e6
Revises: j1a2b3c4d5e6
Create Date: 2026-10-03 02:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'k1a2b3c4d5e6'
down_revision: Union[str, Sequence[str], None] = 'j1a2b3c4d5e6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('custom_problems', sa.Column('starter_code_python', sa.Text(), server_default='', nullable=True))
    op.add_column('custom_problems', sa.Column('starter_code_java', sa.Text(), server_default='', nullable=True))
    op.add_column('custom_problems', sa.Column('starter_code_cpp', sa.Text(), server_default='', nullable=True))
    op.alter_column('custom_problems', 'starter_code', nullable=True)
    
    # Populate existing starter_code into starter_code_python
    op.execute("UPDATE custom_problems SET starter_code_python = starter_code WHERE starter_code IS NOT NULL AND (starter_code_python = '' OR starter_code_python IS NULL)")


def downgrade() -> None:
    op.drop_column('custom_problems', 'starter_code_cpp')
    op.drop_column('custom_problems', 'starter_code_java')
    op.drop_column('custom_problems', 'starter_code_python')
