"""add_educator_applications_and_dob_source

Revision ID: t1a2b3c4d5e6
Revises: s1a2b3c4d5e6
Create Date: 2026-10-24 00:10:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 't1a2b3c4d5e6'
down_revision: Union[str, None] = 's1a2b3c4d5e6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Add dob_source to users table
    op.add_column(
        'users',
        sa.Column('dob_source', sa.String(length=20), nullable=True)
    )

    # 2. Create educator_applications table
    op.create_table(
        'educator_applications',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('requested_role', sa.String(length=50), nullable=False),
        sa.Column('date_of_birth_at_application', sa.Date(), nullable=False),
        sa.Column('age_at_application', sa.Integer(), nullable=False),
        sa.Column('institution_name', sa.String(length=200), nullable=False),
        sa.Column('designation', sa.String(length=100), nullable=False),
        sa.Column('subject_expertise', sa.String(length=200), nullable=False),
        sa.Column('bio', sa.Text(), nullable=True),
        sa.Column('supervisor_email', sa.String(length=255), nullable=True),
        sa.Column('status', sa.String(length=20), server_default='PENDING', nullable=False),
        sa.Column('admin_note', sa.Text(), nullable=True),
        sa.Column('reviewed_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('reviewed_by', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['reviewed_by'], ['users.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id')
    )

    op.create_index(
        op.f('ix_educator_applications_user_id'),
        'educator_applications',
        ['user_id'],
        unique=False
    )
    op.create_index(
        op.f('ix_educator_applications_status'),
        'educator_applications',
        ['status'],
        unique=False
    )

    # Partial unique index: only ONE PENDING application per user
    op.create_index(
        'uq_educator_app_user_pending',
        'educator_applications',
        ['user_id'],
        unique=True,
        postgresql_where=sa.text("status = 'PENDING'")
    )


def downgrade() -> None:
    op.drop_index('uq_educator_app_user_pending', table_name='educator_applications')
    op.drop_index(op.f('ix_educator_applications_status'), table_name='educator_applications')
    op.drop_index(op.f('ix_educator_applications_user_id'), table_name='educator_applications')
    op.drop_table('educator_applications')
    op.drop_column('users', 'dob_source')
