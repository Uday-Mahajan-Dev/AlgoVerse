"""add teacher_profiles table for self-serve educator system

Revision ID: h1a2b3c4d5e6
Revises: g1a2b3c4d5e6
Create Date: 2026-10-02 15:45:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'h1a2b3c4d5e6'
down_revision: Union[str, Sequence[str], None] = 'g1a2b3c4d5e6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'teacher_profiles',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('institution_name', sa.String(length=200), server_default='', nullable=False),
        sa.Column('subject_expertise', sa.String(length=200), server_default='Data Structures & Algorithms', nullable=False),
        sa.Column('bio', sa.Text(), nullable=True),
        sa.Column('class_code', sa.String(length=20), nullable=False),
        sa.Column('is_verified', sa.Boolean(), server_default='false', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', name='uq_teacher_profiles_user_id'),
        sa.UniqueConstraint('class_code', name='uq_teacher_profiles_class_code'),
    )
    op.create_index(op.f('ix_teacher_profiles_user_id'), 'teacher_profiles', ['user_id'], unique=True)
    op.create_index(op.f('ix_teacher_profiles_class_code'), 'teacher_profiles', ['class_code'], unique=True)


def downgrade() -> None:
    op.drop_index(op.f('ix_teacher_profiles_class_code'), table_name='teacher_profiles')
    op.drop_index(op.f('ix_teacher_profiles_user_id'), table_name='teacher_profiles')
    op.drop_table('teacher_profiles')
