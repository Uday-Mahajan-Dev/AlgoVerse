from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.badge import BadgeResponse, UserBadgeResponse
from app.services.badge_service import BadgeService

router = APIRouter(
    tags=["Badges"],
)


@router.get("", response_model=list[BadgeResponse], summary="List all badges in the AlgoVerse achievement catalog")
def get_all_badges(
    db: Session = Depends(get_db),
):
    return BadgeService.get_all_badges(db=db)


@router.get("/my", response_model=list[UserBadgeResponse], summary="List all badges with current user's earned status")
def get_my_badges(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return BadgeService.get_user_badges(db=db, user_id=current_user.id)
