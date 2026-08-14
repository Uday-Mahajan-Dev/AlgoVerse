from uuid import UUID

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.models.email_otp import EmailOTP


class EmailOTPRepository:

    @staticmethod
    def create(
        db: Session,
        otp: EmailOTP,
    ) -> EmailOTP:

        db.add(otp)
        db.commit()
        db.refresh(otp)

        return otp

    @staticmethod
    def get_latest(
        db: Session,
        user_id: UUID,
    ) -> EmailOTP | None:

        return db.scalar(
            select(EmailOTP)
            .where(
                EmailOTP.user_id == user_id,
            )
            .order_by(
                EmailOTP.created_at.desc(),
            )
        )

    @staticmethod
    def get_latest_active(
        db: Session,
        user_id: UUID,
    ) -> EmailOTP | None:

        return db.scalar(
            select(EmailOTP)
            .where(
                EmailOTP.user_id == user_id,
                EmailOTP.used.is_(False),
            )
            .order_by(
                EmailOTP.created_at.desc(),
            )
        )

    @staticmethod
    def invalidate_active(
        db: Session,
        user_id: UUID,
    ) -> None:

        db.execute(
            update(EmailOTP)
            .where(
                EmailOTP.user_id == user_id,
                EmailOTP.used.is_(False),
            )
            .values(used=True)
        )

        db.commit()

    @staticmethod
    def increment_attempts(
        db: Session,
        otp: EmailOTP,
    ) -> EmailOTP:

        otp.attempts += 1

        db.commit()
        db.refresh(otp)

        return otp

    @staticmethod
    def mark_used(
        db: Session,
        otp: EmailOTP,
    ) -> EmailOTP:

        otp.used = True

        db.commit()
        db.refresh(otp)

        return otp