from datetime import datetime, timedelta, timezone

from uuid import UUID
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    get_password_hash,
    hash_token,
    verify_password,
)
from app.exceptions.auth import (
    DefaultRoleNotFoundException,
    EmailAlreadyExistsException,
    InvalidCredentialsException,
    UsernameAlreadyExistsException,
)
from app.models.refresh_token import RefreshToken
from app.models.user import User
from app.repositories.email_otp_repository import EmailOTPRepository
from app.repositories.refresh_token_repository import RefreshTokenRepository
from app.repositories.role_repository import RoleRepository
from app.repositories.user_repository import UserRepository
from app.schemas.auth import LoginRequest, RegisterRequest
from app.schemas.token import Token
from app.services.email_otp_service import EmailOTPService
from app.services.email_service import EmailService


class AuthService:

    @staticmethod
    def register(
        db: Session,
        data: RegisterRequest,
    ) -> User:

        if UserRepository.get_by_email(
            db,
            data.email,
        ):
            raise EmailAlreadyExistsException()

        if UserRepository.get_by_username(
            db,
            data.username,
        ):
            raise UsernameAlreadyExistsException()

        role = RoleRepository.get_default_role(db)

        if role is None:
            raise DefaultRoleNotFoundException()

        user = User(
            username=data.username,
            email=data.email,
            hashed_password=get_password_hash(
                data.password,
            ),
            first_name=data.first_name,
            last_name=data.last_name,
            role_id=role.id,
            email_verified=False,
            phone_verified=False,
        )

        user = UserRepository.create(
            db=db,
            user=user,
        )

        otp = EmailOTPService.create_otp(
            db=db,
            user_id=user.id,
        )

        EmailService.send_email_otp(
            recipient=user.email,
            otp=otp,
        )

        return user

    @staticmethod
    def verify_email(
        db: Session,
        email: str,
        otp: str,
    ) -> User:

        user = UserRepository.get_by_email(
            db,
            email,
        )

        if user is None:
            raise InvalidCredentialsException()

        if user.email_verified:
            return user

        verified = EmailOTPService.verify_otp(
            db=db,
            user_id=user.id,
            otp=otp,
        )

        if not verified:
            raise InvalidCredentialsException()

        user.email_verified = True

        return UserRepository.update(
            db=db,
            user=user,
        )

    @staticmethod
    def resend_verification(
        db: Session,
        email: str,
    ) -> None:

        user = UserRepository.get_by_email(
            db,
            email,
        )

        if user is None:
            raise InvalidCredentialsException()

        if user.email_verified:
            raise InvalidCredentialsException()

        latest_otp = EmailOTPRepository.get_latest(
            db=db,
            user_id=user.id,
        )

        if latest_otp is not None:
            cooldown = timedelta(
                seconds=settings.EMAIL_OTP_RESEND_COOLDOWN_SECONDS,
            )

            now = datetime.now(timezone.utc)

            if now - latest_otp.created_at < cooldown:
                raise InvalidCredentialsException()

        otp = EmailOTPService.create_otp(
            db=db,
            user_id=user.id,
        )

        EmailService.send_email_otp(
            recipient=user.email,
            otp=otp,
        )

    @staticmethod
    def login(
        db: Session,
        data: LoginRequest,
    ) -> Token:

        user = UserRepository.get_by_email(
            db,
            data.email,
        )

        if user is None:
            raise InvalidCredentialsException()

        if not user.hashed_password:
            raise InvalidCredentialsException()

        if not verify_password(
            data.password,
            user.hashed_password,
        ):
            raise InvalidCredentialsException()

        if not user.email_verified:
            raise InvalidCredentialsException()

        access_token = create_access_token(
            subject=str(user.id),
        )

        refresh_token = create_refresh_token(
            subject=str(user.id),
        )

        refresh = RefreshToken(
            user_id=user.id,
            token_hash=hash_token(
                refresh_token,
            ),
            expires_at=datetime.now(timezone.utc)
            + timedelta(
                days=settings.REFRESH_TOKEN_EXPIRE_DAYS,
            ),
        )

        RefreshTokenRepository.create(
            db=db,
            token=refresh,
        )

        return Token(
            access_token=access_token,
            refresh_token=refresh_token,
        )

    @staticmethod
    def refresh(
        db: Session,
        refresh_token: str,
    ) -> Token:

        payload = decode_token(
            refresh_token,
        )

        if payload is None:
            raise InvalidCredentialsException()

        if payload.get("type") != "refresh":
            raise InvalidCredentialsException()

        user_id = payload.get("sub")

        if user_id is None:
            raise InvalidCredentialsException()

        try:
            user_uuid = UUID(str(user_id))
        except ValueError:
            raise InvalidCredentialsException()

        token_hash = hash_token(
            refresh_token,
        )

        stored_token = RefreshTokenRepository.get_by_hash(
            db,
            token_hash,
        )

        if stored_token is None:
            raise InvalidCredentialsException()

        if stored_token.user_id != user_uuid:
            raise InvalidCredentialsException()

        if stored_token.revoked:
            raise InvalidCredentialsException()

        if stored_token.expires_at < datetime.now(timezone.utc):
            raise InvalidCredentialsException()

        access_token = create_access_token(
            subject=user_id,
        )

        new_refresh_token = create_refresh_token(
            subject=user_id,
        )

        RefreshTokenRepository.delete(
            db,
            stored_token,
        )

        RefreshTokenRepository.create(
            db=db,
            token=RefreshToken(
                user_id=stored_token.user_id,
                token_hash=hash_token(
                    new_refresh_token,
                ),
                expires_at=datetime.now(timezone.utc)
                + timedelta(
                    days=settings.REFRESH_TOKEN_EXPIRE_DAYS,
                ),
            ),
        )

        return Token(
            access_token=access_token,
            refresh_token=new_refresh_token,
        )

    @staticmethod
    def logout(
        db: Session,
        refresh_token: str,
    ) -> None:

        payload = decode_token(
            refresh_token,
        )

        if payload is None:
            raise InvalidCredentialsException()

        if payload.get("type") != "refresh":
            raise InvalidCredentialsException()

        token_hash = hash_token(
            refresh_token,
        )

        success = RefreshTokenRepository.revoke_by_hash(
            db,
            token_hash,
        )

        if not success:
            raise InvalidCredentialsException()