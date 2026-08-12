"""add email and phone verification

Revision ID: 575f764a705d
Revises: f954fb26367c
Create Date: 2026-08-13 00:46:57.336168

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.

revision: str = "575f764a705d"
down_revision: Union[str, Sequence[str], None] = "f954fb26367c"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""

    # Add email verification status.
    op.add_column(
        "users",
        sa.Column(
            "email_verified",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
    )

    # Add phone number.
    op.add_column(
        "users",
        sa.Column(
            "phone_number",
            sa.String(length=20),
            nullable=True,
        ),
    )

    # Add phone verification status.
    op.add_column(
        "users",
        sa.Column(
            "phone_verified",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
    )

    # A phone number can belong to only one user.
    op.create_unique_constraint(
        "uq_users_phone_number",
        "users",
        ["phone_number"],
    )

    # Remove the old generic verification field.
    op.drop_column(
        "users",
        "is_verified",
    )


def downgrade() -> None:
    """Downgrade schema."""

    # Restore the old verification field.
    op.add_column(
        "users",
        sa.Column(
            "is_verified",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
    )

    # Remove phone-number uniqueness.
    op.drop_constraint(
        "uq_users_phone_number",
        "users",
        type_="unique",
    )

    # Remove phone verification fields.
    op.drop_column(
        "users",
        "phone_verified",
    )

    op.drop_column(
        "users",
        "phone_number",
    )

    op.drop_column(
        "users",
        "email_verified",
    )