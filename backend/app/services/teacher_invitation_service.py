import secrets
from datetime import datetime, timedelta, timezone

from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.enums import UserRole
from app.core.security import hash_token
from app.core.teacher_invitation_enums import TeacherInvitationStatus
from app.exceptions.auth import InvalidCredentialsException
from app.models.teacher_invitation import TeacherInvitation
from app.repositories.role_repository import RoleRepository
from app.repositories.teacher_invitation_repository import (
    TeacherInvitationRepository,
)
from app.services.email_service import EmailService


class TeacherInvitationService:

    @staticmethod
    def create_invitation(
        db: Session,
        email: str,
        invited_by,
    ) -> TeacherInvitation:

        email = email.strip().lower()

        existing = (
            TeacherInvitationRepository
            .get_latest_pending_by_email(
                db=db,
                email=email,
            )
        )

        if existing is not None:

            existing = (
                TeacherInvitationRepository
                .expire_if_needed(
                    db=db,
                    invitation=existing,
                )
            )

            if (
                existing.status
                == TeacherInvitationStatus.PENDING.value
            ):
                raise InvalidCredentialsException()

        raw_token = secrets.token_urlsafe(48)

        token_hash = hash_token(raw_token)

        expires_at = (
            datetime.now(timezone.utc)
            + timedelta(
                hours=settings.TEACHER_INVITATION_EXPIRE_HOURS
            )
        )

        invitation = TeacherInvitation(
            email=email,
            status=TeacherInvitationStatus.PENDING.value,
            token_hash=token_hash,
            invited_by=invited_by,
            expires_at=expires_at,
        )

        invitation = TeacherInvitationRepository.create(
            db=db,
            invitation=invitation,
        )

        invitation_url = (
            f"{settings.TEACHER_INVITATION_BASE_URL}"
            f"?token={raw_token}"
        )

        EmailService.send_teacher_invitation(
            recipient=email,
            invitation_url=invitation_url,
        )

        return invitation

    @staticmethod
    def accept_invitation(
        db: Session,
        raw_token: str,
    ) -> TeacherInvitation:

        if not raw_token:
            raise InvalidCredentialsException()

        token_hash = hash_token(raw_token)

        invitation = (
            TeacherInvitationRepository
            .get_by_token_hash(
                db=db,
                token_hash=token_hash,
            )
        )

        if invitation is None:
            raise InvalidCredentialsException()

        invitation = (
            TeacherInvitationRepository
            .expire_if_needed(
                db=db,
                invitation=invitation,
            )
        )

        if (
            invitation.status
            == TeacherInvitationStatus.EXPIRED.value
        ):
            raise InvalidCredentialsException()

        if (
            invitation.status
            == TeacherInvitationStatus.REVOKED.value
        ):
            raise InvalidCredentialsException()

        if (
            invitation.status
            == TeacherInvitationStatus.ACCEPTED.value
        ):
            return invitation

        invitation.status = (
            TeacherInvitationStatus.ACCEPTED.value
        )

        invitation.accepted_at = datetime.now(
            timezone.utc
        )

        return TeacherInvitationRepository.update(
            db=db,
            invitation=invitation,
        )

    @staticmethod
    def get_teacher_role(db: Session):

        role = RoleRepository.get_by_name(
            db,
            UserRole.TEACHER,
        )

        if role is None:
            raise InvalidCredentialsException()

        return role
