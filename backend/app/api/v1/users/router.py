from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.core.enums import UserRole
from app.models.teacher_profile import TeacherProfile
from app.models.user import User
from app.repositories.role_repository import RoleRepository
from app.schemas.badge import UserBadgeResponse
from app.schemas.user import UserResponse, UserUpdate
from app.services.badge_service import BadgeService

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
    return UserResponse.from_user(current_user, db)


@router.patch("/me", response_model=UserResponse, summary="Edit current user profile details")
def update_user_profile(
    data: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Check username uniqueness if changed
    if data.username is not None and data.username.strip():
        new_username = data.username.strip()
        if new_username.lower() != current_user.username.lower():
            existing = db.scalar(
                select(User).where(
                    User.username.ilike(new_username),
                    User.id != current_user.id,
                )
            )
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Username '{new_username}' is already taken. Please choose another username.",
                )
            current_user.username = new_username

    if data.first_name is not None:
        current_user.first_name = data.first_name.strip()
    if data.last_name is not None:
        current_user.last_name = data.last_name.strip()
    if data.bio is not None:
        current_user.bio = data.bio.strip()
        # If user has teacher profile, update bio there too
        tp = db.scalar(select(TeacherProfile).where(TeacherProfile.user_id == current_user.id))
        if tp:
            tp.bio = data.bio.strip()
    if data.avatar_url is not None:
        current_user.avatar_url = data.avatar_url.strip()
    if data.cover_image_url is not None:
        current_user.cover_image_url = data.cover_image_url.strip()
    if data.country is not None:
        current_user.country = data.country.strip()
    if data.timezone is not None:
        current_user.timezone = data.timezone.strip()
    if data.preferred_language is not None:
        current_user.preferred_language = data.preferred_language.strip()
    if data.date_of_birth is not None:
        current_user.date_of_birth = data.date_of_birth
    if data.gender is not None:
        current_user.gender = data.gender.strip()
    if data.instagram_url is not None:
        current_user.instagram_url = data.instagram_url.strip()
    if data.linkedin_url is not None:
        current_user.linkedin_url = data.linkedin_url.strip()

    try:
        db.commit()
        db.refresh(current_user)
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update profile. Please try again.",
        )

    return UserResponse.from_user(current_user, db)


@router.get("/me", response_model=UserResponse)
def get_user_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Auto-award first login badge on fetching profile
    BadgeService.award_badge_if_eligible(db, current_user.id, "FIRST_LOGIN")
    return UserResponse.from_user(current_user, db)


@router.get("/me/badges", response_model=list[UserBadgeResponse], summary="Get all badges with current user's earned status")
def get_my_badges(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return BadgeService.get_user_badges(db=db, user_id=current_user.id)
