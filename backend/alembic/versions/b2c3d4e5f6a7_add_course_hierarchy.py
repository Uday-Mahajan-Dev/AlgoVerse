"""add course hierarchy

Revision ID: b2c3d4e5f6a7
Revises: a1b2c3d4e5f6
Create Date: 2026-10-01 23:45:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'b2c3d4e5f6a7'
down_revision: Union[str, Sequence[str], None] = 'a1b2c3d4e5f6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. courses
    op.create_table(
        'courses',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('title', sa.String(length=255), nullable=False),
        sa.Column('slug', sa.String(length=255), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('thumbnail_url', sa.String(length=512), nullable=True),
        sa.Column('difficulty', sa.String(length=50), nullable=False),
        sa.Column('topic_category', sa.String(length=100), nullable=False),
        sa.Column('is_published', sa.Boolean(), server_default=sa.text('false'), nullable=False),
        sa.Column('created_by', sa.UUID(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['created_by'], ['users.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_courses_slug'), 'courses', ['slug'], unique=True)

    # 2. course_modules
    op.create_table(
        'course_modules',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('course_id', sa.UUID(), nullable=False),
        sa.Column('title', sa.String(length=255), nullable=False),
        sa.Column('order_index', sa.Integer(), server_default=sa.text('0'), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['course_id'], ['courses.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_course_modules_course_id'), 'course_modules', ['course_id'], unique=False)

    # 3. lessons
    op.create_table(
        'lessons',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('module_id', sa.UUID(), nullable=False),
        sa.Column('title', sa.String(length=255), nullable=False),
        sa.Column('slug', sa.String(length=255), nullable=False),
        sa.Column('content_type', sa.String(length=50), nullable=False),
        sa.Column('content_json', postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.Column('order_index', sa.Integer(), server_default=sa.text('0'), nullable=False),
        sa.Column('estimated_minutes', sa.Integer(), server_default=sa.text('10'), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['module_id'], ['course_modules.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_lessons_module_id'), 'lessons', ['module_id'], unique=False)
    op.create_index(op.f('ix_lessons_slug'), 'lessons', ['slug'], unique=True)

    # 4. course_enrollments
    op.create_table(
        'course_enrollments',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('student_id', sa.UUID(), nullable=False),
        sa.Column('course_id', sa.UUID(), nullable=False),
        sa.Column('enrolled_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['course_id'], ['courses.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['student_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('student_id', 'course_id', name='uq_course_enrollment_student_course'),
    )
    op.create_index(op.f('ix_course_enrollments_course_id'), 'course_enrollments', ['course_id'], unique=False)
    op.create_index(op.f('ix_course_enrollments_student_id'), 'course_enrollments', ['student_id'], unique=False)

    # 5. lesson_completions
    op.create_table(
        'lesson_completions',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('student_id', sa.UUID(), nullable=False),
        sa.Column('lesson_id', sa.UUID(), nullable=False),
        sa.Column('completed_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['lesson_id'], ['lessons.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['student_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('student_id', 'lesson_id', name='uq_lesson_completion_student_lesson'),
    )
    op.create_index(op.f('ix_lesson_completions_lesson_id'), 'lesson_completions', ['lesson_id'], unique=False)
    op.create_index(op.f('ix_lesson_completions_student_id'), 'lesson_completions', ['student_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_lesson_completions_student_id'), table_name='lesson_completions')
    op.drop_index(op.f('ix_lesson_completions_lesson_id'), table_name='lesson_completions')
    op.drop_table('lesson_completions')

    op.drop_index(op.f('ix_course_enrollments_student_id'), table_name='course_enrollments')
    op.drop_index(op.f('ix_course_enrollments_course_id'), table_name='course_enrollments')
    op.drop_table('course_enrollments')

    op.drop_index(op.f('ix_lessons_slug'), table_name='lessons')
    op.drop_index(op.f('ix_lessons_module_id'), table_name='lessons')
    op.drop_table('lessons')

    op.drop_index(op.f('ix_course_modules_course_id'), table_name='course_modules')
    op.drop_table('course_modules')

    op.drop_index(op.f('ix_courses_slug'), table_name='courses')
    op.drop_table('courses')
