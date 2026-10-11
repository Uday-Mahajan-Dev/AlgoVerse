"""add mentorship requests and classroom capacity

Revision ID: o1a2b3c4d5e6
Revises: n1a2b3c4d5e6
Create Date: 2026-10-10 18:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'o1a2b3c4d5e6'
down_revision: Union[str, Sequence[str], None] = 'n1a2b3c4d5e6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Add capacity columns to teacher_profiles
    op.execute("""
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name = 'teacher_profiles' AND column_name = 'max_students'
            ) THEN
                ALTER TABLE teacher_profiles ADD COLUMN max_students INTEGER NOT NULL DEFAULT 100;
            END IF;

            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name = 'teacher_profiles' AND column_name = 'is_accepting_requests'
            ) THEN
                ALTER TABLE teacher_profiles ADD COLUMN is_accepting_requests BOOLEAN NOT NULL DEFAULT TRUE;
            END IF;
        END $$;
    """)

    # 2. Create mentorship_requests table
    op.execute("""
        CREATE TABLE IF NOT EXISTS mentorship_requests (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            teacher_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            class_code_attempted VARCHAR(20),
            status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
            message TEXT,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ,
            resolved_at TIMESTAMPTZ,
            resolved_by UUID REFERENCES users(id) ON DELETE SET NULL
        );

        CREATE INDEX IF NOT EXISTS ix_mentorship_requests_student_id ON mentorship_requests (student_id);
        CREATE INDEX IF NOT EXISTS ix_mentorship_requests_teacher_id ON mentorship_requests (teacher_id);
        CREATE INDEX IF NOT EXISTS ix_mentorship_requests_status ON mentorship_requests (status);
    """)

    # 3. Update student_teachers table for multi-professor and approval tracking
    op.execute("""
        DO $$
        BEGIN
            -- Drop single-student unique constraint if present
            IF EXISTS (
                SELECT 1 FROM information_schema.table_constraints
                WHERE table_name = 'student_teachers' AND constraint_name = 'uq_student_teacher_student'
            ) THEN
                ALTER TABLE student_teachers DROP CONSTRAINT uq_student_teacher_student;
            END IF;

            -- Drop unique constraint on student_id directly if created by mapped_column(unique=True)
            IF EXISTS (
                SELECT 1 FROM pg_constraint
                WHERE conname = 'student_teachers_student_id_key'
            ) THEN
                ALTER TABLE student_teachers DROP CONSTRAINT student_teachers_student_id_key;
            END IF;

            -- Drop unique index on student_id if present
            DROP INDEX IF EXISTS ix_student_teachers_student_id;
            CREATE INDEX IF NOT EXISTS ix_student_teachers_student_id ON student_teachers (student_id);

            -- Add approved_at column if not exists
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name = 'student_teachers' AND column_name = 'approved_at'
            ) THEN
                ALTER TABLE student_teachers ADD COLUMN approved_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
            END IF;

            -- Add request_id column if not exists
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name = 'student_teachers' AND column_name = 'request_id'
            ) THEN
                ALTER TABLE student_teachers ADD COLUMN request_id UUID REFERENCES mentorship_requests(id) ON DELETE SET NULL;
            END IF;

            -- Add multi-professor pair constraint if not exists
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.table_constraints
                WHERE table_name = 'student_teachers' AND constraint_name = 'uq_student_teacher_pair'
            ) THEN
                ALTER TABLE student_teachers ADD CONSTRAINT uq_student_teacher_pair UNIQUE (student_id, teacher_id);
            END IF;
        END $$;
    """)


def downgrade() -> None:
    op.execute("""
        DO $$
        BEGIN
            IF EXISTS (
                SELECT 1 FROM information_schema.table_constraints
                WHERE table_name = 'student_teachers' AND constraint_name = 'uq_student_teacher_pair'
            ) THEN
                ALTER TABLE student_teachers DROP CONSTRAINT uq_student_teacher_pair;
            END IF;

            ALTER TABLE student_teachers DROP COLUMN IF EXISTS request_id;
            ALTER TABLE student_teachers DROP COLUMN IF EXISTS approved_at;

            IF NOT EXISTS (
                SELECT 1 FROM information_schema.table_constraints
                WHERE table_name = 'student_teachers' AND constraint_name = 'uq_student_teacher_student'
            ) THEN
                ALTER TABLE student_teachers ADD CONSTRAINT uq_student_teacher_student UNIQUE (student_id);
            END IF;
        END $$;

        DROP TABLE IF EXISTS mentorship_requests CASCADE;

        ALTER TABLE teacher_profiles DROP COLUMN IF EXISTS max_students;
        ALTER TABLE teacher_profiles DROP COLUMN IF EXISTS is_accepting_requests;
    """)
