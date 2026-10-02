from datetime import datetime, timedelta, timezone
from uuid import uuid4

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.enums import UserRole
from app.core.security import (
    create_access_token,
    create_refresh_token,
    hash_token,
)
from app.core.teacher_invitation_enums import (
    TeacherInvitationStatus,
)
from app.exceptions.auth import (
    DefaultRoleNotFoundException,
)
from app.models.auth_provider import AuthProvider
from app.models.refresh_token import RefreshToken
from app.models.user import User
from app.repositories.auth_provider_repository import (
    AuthProviderRepository,
)
from app.repositories.refresh_token_repository import (
    RefreshTokenRepository,
)
from app.repositories.role_repository import RoleRepository
from app.repositories.teacher_invitation_repository import (
    TeacherInvitationRepository,
)
from app.repositories.user_repository import UserRepository
from app.schemas.token import Token
from app.services.firebase_auth_service import FirebaseAuthService


class SocialAuthService:

    @staticmethod
    def _get_role_for_email(
        db: Session,
        email: str,
    ):
        invitation = (
            TeacherInvitationRepository
            .get_latest_accepted_by_email(
                db=db,
                email=email.lower(),
            )
        )

        if (
            invitation is not None
            and invitation.status
            == TeacherInvitationStatus.ACCEPTED.value
        ):
            role = RoleRepository.get_by_name(
                db,
                UserRole.TEACHER,
            )

            if role is None:
                raise DefaultRoleNotFoundException()

            return role

        role = RoleRepository.get_default_role(db)

        if role is None:
            raise DefaultRoleNotFoundException()

        return role

    @staticmethod
    def _apply_teacher_invitation(
        db: Session,
        user: User,
    ) -> User:

        invitation = (
            TeacherInvitationRepository
            .get_latest_accepted_by_email(
                db=db,
                email=user.email.lower(),
            )
        )

        if (
            invitation is not None
            and invitation.status
            == TeacherInvitationStatus.ACCEPTED.value
        ):
            teacher_role = RoleRepository.get_by_name(
                db,
                UserRole.TEACHER,
            )

            if teacher_role is None:
                raise DefaultRoleNotFoundException()

            if user.role.name == UserRole.STUDENT.value:
                user.role_id = teacher_role.id

                user = UserRepository.update(
                    db=db,
                    user=user,
                )

        return user

    @staticmethod
    def login(
        db: Session,
        id_token: str,
    ) -> Token:

        try:
            firebase_user = (
                FirebaseAuthService.verify_id_token(
                    id_token
                )
            )
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Google authentication failed on server",
            )

        firebase_uid = firebase_user.get("uid")
        email = firebase_user.get("email")

        if not firebase_uid or not email:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Google authentication failed on server",
            )

        email = email.strip().lower()
        provider = firebase_user.get("provider") or "google"

        # Check existing AuthProvider link first
        auth_provider = (
            AuthProviderRepository
            .get_by_provider_identity(
                db=db,
                provider=provider,
                provider_user_id=firebase_uid,
            )
        )

        # Fallback check for "firebase" provider identity
        if not auth_provider and provider != "firebase":
            auth_provider = (
                AuthProviderRepository
                .get_by_provider_identity(
                    db=db,
                    provider="firebase",
                    provider_user_id=firebase_uid,
                )
            )

        if auth_provider:
            user = UserRepository.get_by_id(
                db=db,
                user_id=auth_provider.user_id,
            )

            if user is None or not user.is_active:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="User account is inactive. Please contact support.",
                )

            user = (
                SocialAuthService
                ._apply_teacher_invitation(
                    db=db,
                    user=user,
                )
            )
        else:
            # Look up existing user by email
            user = UserRepository.get_by_email(
                db=db,
                email=email,
            )

            if user is None:
                # AUTO-CREATE user
                role = (
                    SocialAuthService
                    ._get_role_for_email(
                        db=db,
                        email=email,
                    )
                )

                display_name = (
                    firebase_user.get("name")
                    or email.split("@")[0]
                ).strip()

                given_name = firebase_user.get("given_name")
                family_name = firebase_user.get("family_name")

                if given_name:
                    first_name = given_name[:100]
                    last_name = (family_name or "")[:100]
                elif " " in display_name:
                    parts = display_name.split(" ", 1)
                    first_name = parts[0][:100]
                    last_name = parts[1][:100]
                else:
                    first_name = display_name[:100]
                    last_name = ""

                username_base = (
                    display_name.lower()
                    .replace(" ", "_")
                    .replace("-", "_")
                )[:22]
                if not username_base:
                    username_base = email.split("@")[0].lower()[:22]

                username = username_base
                if UserRepository.get_by_username(db, username):
                    username = f"{username_base}_{str(uuid4())[:6]}"

                user = User(
                    username=username,
                    email=email,
                    hashed_password="",
                    first_name=first_name,
                    last_name=last_name,
                    role_id=role.id,
                    is_active=True,
                    email_verified=True,
                    phone_verified=False,
                )

                user = UserRepository.create(
                    db=db,
                    user=user,
                )
            else:
                if not user.is_active:
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="User account is inactive. Please contact support.",
                    )

                user.email_verified = True
                user = UserRepository.update(
                    db=db,
                    user=user,
                )

                user = (
                    SocialAuthService
                    ._apply_teacher_invitation(
                        db=db,
                        user=user,
                    )
                )

            # Link auth provider
            try:
                AuthProviderRepository.create(
                    db=db,
                    auth_provider=AuthProvider(
                        user_id=user.id,
                        provider=provider,
                        provider_user_id=firebase_uid,
                    ),
                )
            except Exception:
                pass  # Ignore duplicate provider link if already present

        access_token = create_access_token(
            subject=str(user.id),
        )

        refresh_token = create_refresh_token(
            subject=str(user.id),
        )

        refresh = RefreshToken(
            user_id=user.id,
            token_hash=hash_token(
                refresh_token
            ),
            expires_at=(
                datetime.now(timezone.utc)
                + timedelta(
                    days=30,
                )
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
