"""add problem, test case, and submission models

Revision ID: f6a7b8c9d0e1
Revises: e5f6a7b8c9d0
Create Date: 2026-10-02 01:05:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'f6a7b8c9d0e1'
down_revision: Union[str, Sequence[str], None] = 'e5f6a7b8c9d0'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. problems
    op.create_table(
        'problems',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('lesson_id', sa.UUID(), nullable=False),
        sa.Column('title', sa.String(length=255), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('function_name', sa.String(length=100), nullable=False),
        sa.Column('starter_code_python', sa.Text(), nullable=False),
        sa.Column('starter_code_java', sa.Text(), nullable=False),
        sa.Column('starter_code_cpp', sa.Text(), nullable=False),
        sa.Column('solution_code_python', sa.Text(), nullable=False),
        sa.Column('solution_code_java', sa.Text(), nullable=False),
        sa.Column('solution_code_cpp', sa.Text(), nullable=False),
        sa.Column('time_limit_ms', sa.Integer(), server_default='2000', nullable=False),
        sa.Column('memory_limit_mb', sa.Integer(), server_default='64', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['lesson_id'], ['lessons.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('lesson_id'),
    )
    op.create_index(op.f('ix_problems_lesson_id'), 'problems', ['lesson_id'], unique=True)

    # 2. test_cases
    op.create_table(
        'test_cases',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('problem_id', sa.UUID(), nullable=False),
        sa.Column('stdin_input', sa.Text(), nullable=False),
        sa.Column('expected_stdout', sa.Text(), nullable=False),
        sa.Column('is_hidden', sa.Boolean(), server_default=sa.text('false'), nullable=False),
        sa.Column('order_index', sa.Integer(), server_default='0', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['problem_id'], ['problems.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_test_cases_problem_id'), 'test_cases', ['problem_id'], unique=False)

    # 3. submissions
    op.create_table(
        'submissions',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('student_id', sa.UUID(), nullable=False),
        sa.Column('problem_id', sa.UUID(), nullable=False),
        sa.Column('code', sa.Text(), nullable=False),
        sa.Column('language', sa.String(length=20), nullable=False),
        sa.Column('verdict', sa.String(length=10), nullable=False),
        sa.Column('execution_time_ms', sa.Integer(), nullable=True),
        sa.Column('memory_used_kb', sa.Integer(), nullable=True),
        sa.Column('passed_count', sa.Integer(), server_default='0', nullable=False),
        sa.Column('total_count', sa.Integer(), server_default='0', nullable=False),
        sa.Column('failed_test_index', sa.Integer(), nullable=True),
        sa.Column('actual_output', sa.Text(), nullable=True),
        sa.Column('error_message', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['problem_id'], ['problems.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['student_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_submissions_problem_id'), 'submissions', ['problem_id'], unique=False)
    op.create_index(op.f('ix_submissions_student_id'), 'submissions', ['student_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_submissions_student_id'), table_name='submissions')
    op.drop_index(op.f('ix_submissions_problem_id'), table_name='submissions')
    op.drop_table('submissions')
    op.drop_index(op.f('ix_test_cases_problem_id'), table_name='test_cases')
    op.drop_table('test_cases')
    op.drop_index(op.f('ix_problems_lesson_id'), table_name='problems')
    op.drop_table('problems')
