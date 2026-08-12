from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.enums import UserRole
from app.models.role import Role


class RoleRepository:

    @staticmethod
    def get_by_name(
        db: Session,
        name: UserRole,
    ) -> Role | None:

        return db.scalar(
            select(Role).where(
                Role.name == name.value,
            )
        )

    @staticmethod
    def get_default_role(
        db: Session,
    ) -> Role | None:

        return RoleRepository.get_by_name(
            db,
            UserRole.STUDENT,
        )