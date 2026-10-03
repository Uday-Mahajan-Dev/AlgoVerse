"""add custom_problems, quizzes, quiz_questions, quiz_attempts, and target_role on badges

Revision ID: j1a2b3c4d5e6
Revises: i1a2b3c4d5e6
Create Date: 2026-10-03 01:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'j1a2b3c4d5e6'
down_revision: Union[str, Sequence[str], None] = 'i1a2b3c4d5e6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Add target_role to badges
    op.add_column('badges', sa.Column('target_role', sa.String(length=20), server_default='ALL', nullable=False))

    # 2. Create custom_problems table
    op.create_table(
        'custom_problems',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('teacher_id', sa.UUID(), nullable=False),
        sa.Column('title', sa.String(length=200), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('starter_code', sa.Text(), server_default='', nullable=False),
        sa.Column('test_cases', postgresql.JSONB(astext_type=sa.Text()), server_default='[]', nullable=False),
        sa.Column('visibility', sa.String(length=20), server_default='CLASS_ONLY', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['teacher_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_custom_problems_teacher_id'), 'custom_problems', ['teacher_id'], unique=False)
    op.create_index(op.f('ix_custom_problems_visibility'), 'custom_problems', ['visibility'], unique=False)

    # 3. Create quizzes table
    op.create_table(
        'quizzes',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('teacher_id', sa.UUID(), nullable=False),
        sa.Column('title', sa.String(length=200), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('visibility', sa.String(length=20), server_default='CLASS_ONLY', nullable=False),
        sa.Column('time_per_question_seconds', sa.Integer(), server_default='30', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['teacher_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_quizzes_teacher_id'), 'quizzes', ['teacher_id'], unique=False)
    op.create_index(op.f('ix_quizzes_visibility'), 'quizzes', ['visibility'], unique=False)

    # 4. Create quiz_questions table
    op.create_table(
        'quiz_questions',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('quiz_id', sa.UUID(), nullable=False),
        sa.Column('question_text', sa.Text(), nullable=False),
        sa.Column('options', postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column('correct_option_index', sa.Integer(), nullable=False),
        sa.Column('order_index', sa.Integer(), server_default='0', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['quiz_id'], ['quizzes.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_quiz_questions_quiz_id'), 'quiz_questions', ['quiz_id'], unique=False)

    # 5. Create quiz_attempts table
    op.create_table(
        'quiz_attempts',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('student_id', sa.UUID(), nullable=False),
        sa.Column('quiz_id', sa.UUID(), nullable=False),
        sa.Column('score', sa.Integer(), server_default='0', nullable=False),
        sa.Column('total_time_seconds', sa.Integer(), server_default='0', nullable=False),
        sa.Column('answers', postgresql.JSONB(astext_type=sa.Text()), server_default='[]', nullable=False),
        sa.Column('submitted_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['student_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['quiz_id'], ['quizzes.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_quiz_attempts_student_id'), 'quiz_attempts', ['student_id'], unique=False)
    op.create_index(op.f('ix_quiz_attempts_quiz_id'), 'quiz_attempts', ['quiz_id'], unique=False)

    # 6. Update assignments table (nullable lesson_id, add custom_problem_id, quiz_id)
    op.alter_column('assignments', 'lesson_id', existing_type=sa.UUID(), nullable=True)
    op.add_column('assignments', sa.Column('custom_problem_id', sa.UUID(), nullable=True))
    op.create_foreign_key('fk_assignments_custom_problem_id', 'assignments', 'custom_problems', ['custom_problem_id'], ['id'], ondelete='CASCADE')
    op.add_column('assignments', sa.Column('quiz_id', sa.UUID(), nullable=True))
    op.create_foreign_key('fk_assignments_quiz_id', 'assignments', 'quizzes', ['quiz_id'], ['id'], ondelete='CASCADE')


def downgrade() -> None:
    op.drop_constraint('fk_assignments_quiz_id', 'assignments', type_='foreignkey')
    op.drop_column('assignments', 'quiz_id')
    op.drop_constraint('fk_assignments_custom_problem_id', 'assignments', type_='foreignkey')
    op.drop_column('assignments', 'custom_problem_id')
    op.alter_column('assignments', 'lesson_id', existing_type=sa.UUID(), nullable=False)

    op.drop_index(op.f('ix_quiz_attempts_quiz_id'), table_name='quiz_attempts')
    op.drop_index(op.f('ix_quiz_attempts_student_id'), table_name='quiz_attempts')
    op.drop_table('quiz_attempts')

    op.drop_index(op.f('ix_quiz_questions_quiz_id'), table_name='quiz_questions')
    op.drop_table('quiz_questions')

    op.drop_index(op.f('ix_quizzes_visibility'), table_name='quizzes')
    op.drop_index(op.f('ix_quizzes_teacher_id'), table_name='quizzes')
    op.drop_table('quizzes')

    op.drop_index(op.f('ix_custom_problems_visibility'), table_name='custom_problems')
    op.drop_index(op.f('ix_custom_problems_teacher_id'), table_name='custom_problems')
    op.drop_table('custom_problems')

    op.drop_column('badges', 'target_role')
