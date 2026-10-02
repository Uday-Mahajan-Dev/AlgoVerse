from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.core.enums import UserRole
from app.models.user import User
from app.repositories.role_repository import RoleRepository
from app.schemas.user import UserResponse


router = APIRouter(
    prefix="/users",
    tags=["Users"],
)


class RoleUpdateRequest(BaseModel):
    role: str


@router.patch("/me/role", response_model=UserResponse)
def update_user_role(
    data: RoleUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    role_str = data.role.strip().upper()
    if role_str not in [UserRole.STUDENT.value, UserRole.TEACHER.value, UserRole.ADMIN.value]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid role '{data.role}'. Allowed roles: STUDENT, TEACHER, ADMIN.",
        )

    role = RoleRepository.get_by_name(db, UserRole(role_str))
    if role is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Role '{role_str}' not found in database.",
        )

    current_user.role_id = role.id
    current_user.role = role
    db.commit()
    db.refresh(current_user)
    return UserResponse.from_user(current_user)


@router.get("/me", response_model=UserResponse)
def get_user_profile(
    current_user: User = Depends(get_current_user),
):
    return UserResponse.from_user(current_user)
