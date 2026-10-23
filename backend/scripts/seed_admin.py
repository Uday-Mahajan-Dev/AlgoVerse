import sys
from pathlib import Path
from uuid import uuid4

sys.path.append(str(Path(__file__).resolve().parent.parent))

from sqlalchemy import select
from app.db.session import SessionLocal
from app.models.role import Role
from app.models.user import User
from app.core.enums import UserRole
from app.core.security import get_password_hash


def seed_admin(
    email: str = "admin@algoverse.dev",
    username: str = "admin",
    password: str = "Admin@123",
):
    db = SessionLocal()
    try:
        # 1. Ensure ADMIN role exists
        admin_role = db.scalar(select(Role).where(Role.name == UserRole.ADMIN.value))
        if not admin_role:
            admin_role = Role(name=UserRole.ADMIN.value, description="System Administrator")
            db.add(admin_role)
            db.commit()
            db.refresh(admin_role)

        # 2. Check if admin user already exists
        user = db.scalar(select(User).where((User.email == email) | (User.username == username)))
        if user:
            print(f"Existing admin user found: ID={user.id}, Email={user.email}, Username={user.username}")
            # Ensure role is ADMIN and update password
            user.role_id = admin_role.id
            user.hashed_password = get_password_hash(password)
            user.is_active = True
            user.email_verified = True
            db.commit()
            print(f"Admin user updated successfully. Password set to: {password}")
            return user.id, email, password

        # 3. Create new admin user
        new_admin = User(
            id=uuid4(),
            email=email,
            username=username,
            hashed_password=get_password_hash(password),
            first_name="System",
            last_name="Administrator",
            role_id=admin_role.id,
            is_active=True,
            email_verified=True,
        )
        db.add(new_admin)
        db.commit()
        db.refresh(new_admin)
        print(f"Created new Admin user successfully: ID={new_admin.id}, Email={email}, Username={username}")
        print(f"Admin credentials -> Email: {email} | Password: {password}")
        return new_admin.id, email, password
    finally:
        db.close()


if __name__ == "__main__":
    seed_admin()
