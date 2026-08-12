import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent))

import app.db.base
from sqlalchemy import select
import app.models.user
import app.models.role
from app.db.session import SessionLocal
from app.models.role import Role


from app.core.enums import UserRole


ROLES = [
    (UserRole.ADMIN, "System Administrator"),
    (UserRole.TEACHER, "Teacher"),
    (UserRole.STUDENT, "Student"),
]

def main():

    db = SessionLocal()

    try:

        for name, description in ROLES:

            role = db.scalar(
                select(Role).where(
                    Role.name == name.value
                )
            )

            if role is None:

                db.add(
                    Role(
                        name=name.value,
                        description=description,
                    )
                )

        db.commit()

        print("Roles seeded successfully.")

    finally:

        db.close()


if __name__ == "__main__":
    main()