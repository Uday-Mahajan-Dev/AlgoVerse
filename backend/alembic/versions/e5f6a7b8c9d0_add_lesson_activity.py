"""add student lesson activity

Revision ID: e5f6a7b8c9d0
Revises: b2c3d4e5f6a7
Create Date: 2026-10-02 00:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'e5f6a7b8c9d0'
down_revision: Union[str, Sequence[str], None] = 'b2c3d4e5f6a7'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'student_lesson_activities',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('student_id', sa.UUID(), nullable=False),
        sa.Column('lesson_id', sa.UUID(), nullable=False),
        sa.Column('last_accessed_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['lesson_id'], ['lessons.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['student_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('student_id', 'lesson_id', name='uq_student_lesson_activity'),
    )
    op.create_index(
        op.f('ix_student_lesson_activities_student_id'),
        'student_lesson_activities',
        ['student_id'],
        unique=False,
    )
    op.create_index(
        op.f('ix_student_lesson_activities_lesson_id'),
        'student_lesson_activities',
        ['lesson_id'],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        op.f('ix_student_lesson_activities_lesson_id'),
        table_name='student_lesson_activities',
    )
    op.drop_index(
        op.f('ix_student_lesson_activities_student_id'),
        table_name='student_lesson_activities',
    )
    op.drop_table('student_lesson_activities')
