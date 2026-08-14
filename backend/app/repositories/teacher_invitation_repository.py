from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.teacher_invitation_enums import TeacherInvitationStatus
from app.models.teacher_invitation import TeacherInvitation


class TeacherInvitationRepository:

    @staticmethod
    def create(
        db: Session,
        invitation: TeacherInvitation,
    ) -> TeacherInvitation:

        db.add(invitation)
        db.commit()
        db.refresh(invitation)

        return invitation

    @staticmethod
    def update(
        db: Session,
        invitation: TeacherInvitation,
    ) -> TeacherInvitation:

        db.commit()
        db.refresh(invitation)

        return invitation

    @staticmethod
    def get_by_token_hash(
        db: Session,
        token_hash: str,
    ) -> TeacherInvitation | None:

        return db.scalar(
            select(TeacherInvitation).where(
                TeacherInvitation.token_hash == token_hash
            )
        )

    @staticmethod
    def get_latest_pending_by_email(
        db: Session,
        email: str,
    ) -> TeacherInvitation | None:

        return db.scalar(
            select(TeacherInvitation)
            .where(
                TeacherInvitation.email == email,
                TeacherInvitation.status
                == TeacherInvitationStatus.PENDING.value,
            )
            .order_by(
                TeacherInvitation.created_at.desc()
            )
        )

    @staticmethod
    def get_latest_accepted_by_email(
        db: Session,
        email: str,
    ) -> TeacherInvitation | None:

        return db.scalar(
            select(TeacherInvitation)
            .where(
                TeacherInvitation.email == email,
                TeacherInvitation.status
                == TeacherInvitationStatus.ACCEPTED.value,
            )
            .order_by(
                TeacherInvitation.accepted_at.desc()
            )
        )

    @staticmethod
    def expire_if_needed(
        db: Session,
        invitation: TeacherInvitation,
    ) -> TeacherInvitation:

        now = datetime.now(timezone.utc)

        if (
            invitation.status
            == TeacherInvitationStatus.PENDING.value
            and invitation.expires_at <= now
        ):
            invitation.status = (
                TeacherInvitationStatus.EXPIRED.value
            )

            db.commit()
            db.refresh(invitation)

        return invitation