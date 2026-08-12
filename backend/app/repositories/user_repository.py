from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import User


class UserRepository:

    @staticmethod
    def get_by_id(
        db: Session,
        user_id: UUID,
    ) -> User | None:
        return db.scalar(
            select(User).where(
                User.id == user_id
            )
        )

    @staticmethod
    def get_by_email(
        db: Session,
        email: str,
    ) -> User | None:
        return db.scalar(
            select(User).where(
                User.email == email
            )
        )

    @staticmethod
    def get_by_username(
        db: Session,
        username: str,
    ) -> User | None:
        return db.scalar(
            select(User).where(
                User.username == username
            )
        )

    @staticmethod
    def create(
        db: Session,
        user: User,
    ) -> User:

        db.add(user)
        db.commit()
        db.refresh(user)

        return user

    @staticmethod
    def update(
        db: Session,
        user: User,
    ) -> User:

        db.commit()
        db.refresh(user)

        return user

    @staticmethod
    def delete(
        db: Session,
        user: User,
    ) -> None:

        db.delete(user)
        db.commit()