"""add assignment model for teacher homework management

Revision ID: g1a2b3c4d5e6
Revises: f6a7b8c9d0e1
Create Date: 2026-10-02 01:45:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'g1a2b3c4d5e6'
down_revision: Union[str, Sequence[str], None] = 'f6a7b8c9d0e1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'assignments',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('teacher_id', sa.UUID(), nullable=False),
        sa.Column('student_id', sa.UUID(), nullable=False),
        sa.Column('lesson_id', sa.UUID(), nullable=False),
        sa.Column('assigned_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('due_date', sa.DateTime(timezone=True), nullable=True),
        sa.Column('status', sa.String(length=32), server_default='pending', nullable=False),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('completed_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['teacher_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['student_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['lesson_id'], ['lessons.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_assignments_teacher_id'), 'assignments', ['teacher_id'], unique=False)
    op.create_index(op.f('ix_assignments_student_id'), 'assignments', ['student_id'], unique=False)
    op.create_index(op.f('ix_assignments_lesson_id'), 'assignments', ['lesson_id'], unique=False)
    op.create_index(op.f('ix_assignments_status'), 'assignments', ['status'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_assignments_status'), table_name='assignments')
    op.drop_index(op.f('ix_assignments_lesson_id'), table_name='assignments')
    op.drop_index(op.f('ix_assignments_student_id'), table_name='assignments')
    op.drop_index(op.f('ix_assignments_teacher_id'), table_name='assignments')
    op.drop_table('assignments')
