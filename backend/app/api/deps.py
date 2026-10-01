from collections.abc import Generator
from uuid import UUID

from fastapi import Depends
# from fastapi.security import OAuth2PasswordBearer
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.core.enums import UserRole
from app.core.security import decode_token
from app.db.session import SessionLocal
from app.exceptions.auth import InvalidCredentialsException
from app.models.user import User
from app.repositories.user_repository import UserRepository


bearer_scheme = HTTPBearer()
optional_bearer_scheme = HTTPBearer(auto_error=False)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(
        bearer_scheme
    ),
    db: Session = Depends(get_db),
) -> User:
    token = credentials.credentials

    payload = decode_token(token)

    if not payload:
        raise InvalidCredentialsException()

    if payload.get("type") != "access":
        raise InvalidCredentialsException()

    user_id = payload.get("sub")

    if not user_id:
        raise InvalidCredentialsException()

    try:
        user_uuid = UUID(str(user_id))
    except ValueError:
        raise InvalidCredentialsException()

    user = UserRepository.get_by_id(
        db=db,
        user_id=user_uuid,
    )

    if user is None:
        raise InvalidCredentialsException()

    if not user.is_active:
        raise InvalidCredentialsException()

    return user


def get_optional_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(
        optional_bearer_scheme
    ),
    db: Session = Depends(get_db),
) -> User | None:
    if not credentials:
        return None

    token = credentials.credentials
    payload = decode_token(token)

    if not payload or payload.get("type") != "access":
        return None

    user_id = payload.get("sub")
    if not user_id:
        return None

    try:
        user_uuid = UUID(str(user_id))
    except ValueError:
        return None

    user = UserRepository.get_by_id(
        db=db,
        user_id=user_uuid,
    )

    if user is None or not user.is_active:
        return None

    return user


def require_role(role: UserRole):
    def dependency(
        current_user: User = Depends(get_current_user),
    ) -> User:

        if current_user.role.name != role.value:
            raise InvalidCredentialsException()

        return current_user

    return dependency


def require_roles(*roles: UserRole):
    def dependency(
        current_user: User = Depends(get_current_user),
    ) -> User:
        allowed_roles = {r.value for r in roles}
        if current_user.role.name not in allowed_roles:
            raise InvalidCredentialsException()

        return current_user

    return dependency


get_current_admin = require_role(UserRole.ADMIN)
get_current_teacher = require_role(UserRole.TEACHER)
get_current_student = require_role(UserRole.STUDENT)
get_current_course_creator = require_roles(UserRole.TEACHER, UserRole.ADMIN)