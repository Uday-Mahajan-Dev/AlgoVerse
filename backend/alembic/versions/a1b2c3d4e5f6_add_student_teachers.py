"""add student teachers

Revision ID: a1b2c3d4e5f6
Revises: 12174c995d8c
Create Date: 2026-10-01 23:23:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, Sequence[str], None] = '12174c995d8c'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        'student_teachers',
        sa.Column('student_id', sa.UUID(), nullable=False),
        sa.Column('teacher_id', sa.UUID(), nullable=False),
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['student_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['teacher_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('student_id', name='uq_student_teacher_student'),
    )
    op.create_index(op.f('ix_student_teachers_student_id'), 'student_teachers', ['student_id'], unique=True)
    op.create_index(op.f('ix_student_teachers_teacher_id'), 'student_teachers', ['teacher_id'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_student_teachers_teacher_id'), table_name='student_teachers')
    op.drop_index(op.f('ix_student_teachers_student_id'), table_name='student_teachers')
    op.drop_table('student_teachers')
