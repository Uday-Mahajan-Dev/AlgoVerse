import secrets
from datetime import datetime, timedelta, timezone
from uuid import UUID

from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import hash_token
from app.models.email_otp import EmailOTP
from app.repositories.email_otp_repository import EmailOTPRepository


class EmailOTPService:

    @staticmethod
    def generate_otp() -> str:
        return f"{secrets.randbelow(1_000_000):06d}"

    @staticmethod
    def create_otp(
        db: Session,
        user_id: UUID,
    ) -> str:

        # Invalidate any previously active OTP.
        EmailOTPRepository.invalidate_active(
            db=db,
            user_id=user_id,
        )

        otp = EmailOTPService.generate_otp()

        otp_hash = hash_token(otp)

        expires_at = (
            datetime.now(timezone.utc)
            + timedelta(
                minutes=settings.EMAIL_OTP_EXPIRE_MINUTES
            )
        )

        email_otp = EmailOTP(
            user_id=user_id,
            otp_hash=otp_hash,
            expires_at=expires_at,
            attempts=0,
            used=False,
        )

        EmailOTPRepository.create(
            db=db,
            otp=email_otp,
        )

        return otp

    @staticmethod
    def verify_otp(
        db: Session,
        user_id: UUID,
        otp: str,
    ) -> bool:

        email_otp = EmailOTPRepository.get_latest_active(
            db=db,
            user_id=user_id,
        )

        if email_otp is None:
            return False

        now = datetime.now(timezone.utc)

        # OTP expired.
        if now >= email_otp.expires_at:
            EmailOTPRepository.mark_used(
                db=db,
                otp=email_otp,
            )
            return False

        # Too many attempts.
        if email_otp.attempts >= settings.EMAIL_OTP_MAX_ATTEMPTS:
            EmailOTPRepository.mark_used(
                db=db,
                otp=email_otp,
            )
            return False

        # Increment attempts before checking the OTP.
        EmailOTPRepository.increment_attempts(
            db=db,
            otp=email_otp,
        )

        submitted_hash = hash_token(otp)

        if not secrets.compare_digest(
            submitted_hash,
            email_otp.otp_hash,
        ):
            return False

        EmailOTPRepository.mark_used(
            db=db,
            otp=email_otp,
        )

        return True