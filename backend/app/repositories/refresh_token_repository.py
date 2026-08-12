from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.refresh_token import RefreshToken


class RefreshTokenRepository:

    @staticmethod
    def create(
        db: Session,
        token: RefreshToken,
    ) -> RefreshToken:

        db.add(token)
        db.commit()
        db.refresh(token)

        return token

    @staticmethod
    def get_by_hash(
        db: Session,
        token_hash: str,
    ) -> RefreshToken | None:

        return db.scalar(
            select(RefreshToken).where(
                RefreshToken.token_hash == token_hash,
            )
        )

    @staticmethod
    def revoke(
        db: Session,
        token: RefreshToken,
    ) -> None:

        token.revoked = True
        db.commit()

    @staticmethod
    def delete(
        db: Session,
        token: RefreshToken,
    ) -> None:

        db.delete(token)
        db.commit()

    @staticmethod
    def revoke_by_hash(
        db: Session,
        token_hash: str,
    ) -> bool:

        token = db.scalar(
            select(RefreshToken).where(
                RefreshToken.token_hash == token_hash,
            )
        )

        if token is None:
            return False

        db.delete(token)
        db.commit()

        return True