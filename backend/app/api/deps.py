from collections.abc import Generator

from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.core.enums import UserRole
from app.core.security import decode_token
from app.db.session import SessionLocal
from app.exceptions.auth import InvalidCredentialsException
from app.models.user import User
from app.repositories.user_repository import UserRepository


oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="/api/v1/auth/login",
)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:

    payload = decode_token(token)

    if payload is None:
        raise InvalidCredentialsException()

    user_id = payload.get("sub")

    if user_id is None:
        raise InvalidCredentialsException()

    user = UserRepository.get_by_id(
        db=db,
        user_id=user_id,
    )

    if user is None:
        raise InvalidCredentialsException()

    if not user.is_active:
        raise InvalidCredentialsException()

    return user


def require_role(role: UserRole):
    def dependency(
        current_user: User = Depends(get_current_user),
    ) -> User:

        if current_user.role.name != role.value:
            raise InvalidCredentialsException()

        return current_user

    return dependency


get_current_admin = require_role(UserRole.ADMIN)
get_current_teacher = require_role(UserRole.TEACHER)
get_current_student = require_role(UserRole.STUDENT)