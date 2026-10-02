"""add educator age-gate, edit profile social links, and achievement badges

Revision ID: i1a2b3c4d5e6
Revises: h1a2b3c4d5e6
Create Date: 2026-10-02 18:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'i1a2b3c4d5e6'
down_revision: Union[str, Sequence[str], None] = 'h1a2b3c4d5e6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Add social link columns to users
    op.add_column('users', sa.Column('instagram_url', sa.String(length=255), nullable=True))
    op.add_column('users', sa.Column('linkedin_url', sa.String(length=255), nullable=True))

    # 2. Add designation, date_of_birth, supervisor_id to teacher_profiles
    op.add_column('teacher_profiles', sa.Column('designation', sa.String(length=100), server_default='Professor', nullable=False))
    op.add_column('teacher_profiles', sa.Column('date_of_birth', sa.Date(), nullable=True))
    op.add_column('teacher_profiles', sa.Column('supervisor_id', sa.UUID(), nullable=True))
    op.create_foreign_key('fk_teacher_profiles_supervisor_id', 'teacher_profiles', 'users', ['supervisor_id'], ['id'], ondelete='SET NULL')
    op.create_index(op.f('ix_teacher_profiles_supervisor_id'), 'teacher_profiles', ['supervisor_id'], unique=False)

    # 3. Create ta_approval_requests table
    op.create_table(
        'ta_approval_requests',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('applicant_id', sa.UUID(), nullable=False),
        sa.Column('supervisor_id', sa.UUID(), nullable=False),
        sa.Column('status', sa.String(length=20), server_default='PENDING', nullable=False),
        sa.Column('requested_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('responded_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('institution_name', sa.String(length=200), server_default='', nullable=False),
        sa.Column('designation', sa.String(length=100), server_default='Teaching Assistant', nullable=False),
        sa.Column('subject_expertise', sa.String(length=200), server_default='', nullable=False),
        sa.Column('bio', sa.Text(), nullable=True),
        sa.Column('date_of_birth', sa.Date(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['applicant_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['supervisor_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_ta_approval_requests_applicant_id'), 'ta_approval_requests', ['applicant_id'], unique=False)
    op.create_index(op.f('ix_ta_approval_requests_supervisor_id'), 'ta_approval_requests', ['supervisor_id'], unique=False)
    op.create_index(op.f('ix_ta_approval_requests_status'), 'ta_approval_requests', ['status'], unique=False)

    # 4. Create badges table
    op.create_table(
        'badges',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('code', sa.String(length=50), nullable=False),
        sa.Column('title', sa.String(length=100), nullable=False),
        sa.Column('description', sa.String(length=255), nullable=False),
        sa.Column('icon_key', sa.String(length=50), nullable=False),
        sa.Column('category', sa.String(length=50), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('code', name='uq_badges_code'),
    )
    op.create_index(op.f('ix_badges_code'), 'badges', ['code'], unique=True)

    # 5. Create user_badges table
    op.create_table(
        'user_badges',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('badge_id', sa.UUID(), nullable=False),
        sa.Column('earned_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['badge_id'], ['badges.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'badge_id', name='uq_user_badges_user_id_badge_id'),
    )
    op.create_index(op.f('ix_user_badges_user_id'), 'user_badges', ['user_id'], unique=False)
    op.create_index(op.f('ix_user_badges_badge_id'), 'user_badges', ['badge_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_user_badges_badge_id'), table_name='user_badges')
    op.drop_index(op.f('ix_user_badges_user_id'), table_name='user_badges')
    op.drop_table('user_badges')

    op.drop_index(op.f('ix_badges_code'), table_name='badges')
    op.drop_table('badges')

    op.drop_index(op.f('ix_ta_approval_requests_status'), table_name='ta_approval_requests')
    op.drop_index(op.f('ix_ta_approval_requests_supervisor_id'), table_name='ta_approval_requests')
    op.drop_index(op.f('ix_ta_approval_requests_applicant_id'), table_name='ta_approval_requests')
    op.drop_table('ta_approval_requests')

    op.drop_constraint('fk_teacher_profiles_supervisor_id', 'teacher_profiles', type_='foreignkey')
    op.drop_index(op.f('ix_teacher_profiles_supervisor_id'), table_name='teacher_profiles')
    op.drop_column('teacher_profiles', 'supervisor_id')
    op.drop_column('teacher_profiles', 'date_of_birth')
    op.drop_column('teacher_profiles', 'designation')

    op.drop_column('users', 'linkedin_url')
    op.drop_column('users', 'instagram_url')
