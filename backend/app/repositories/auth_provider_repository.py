from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.auth_provider import AuthProvider


class AuthProviderRepository:

    @staticmethod
    def get_by_provider_identity(
        db: Session,
        provider: str,
        provider_user_id: str,
    ) -> AuthProvider | None:
        return db.scalar(
            select(AuthProvider).where(
                AuthProvider.provider == provider,
                AuthProvider.provider_user_id == provider_user_id,
            )
        )

    @staticmethod
    def get_by_user_and_provider(
        db: Session,
        user_id: UUID,
        provider: str,
    ) -> AuthProvider | None:
        return db.scalar(
            select(AuthProvider).where(
                AuthProvider.user_id == user_id,
                AuthProvider.provider == provider,
            )
        )

    @staticmethod
    def create(
        db: Session,
        auth_provider: AuthProvider,
    ) -> AuthProvider:
        db.add(auth_provider)
        db.commit()
        db.refresh(auth_provider)

        return auth_provider
