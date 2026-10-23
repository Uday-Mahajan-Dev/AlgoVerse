from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.educator_application import (
    EducatorApplicationCreate,
    EducatorApplicationResponse,
)
from app.services.educator_application_service import EducatorApplicationService

router = APIRouter(
    prefix="/educator-applications",
    tags=["Educator Applications"],
)


@router.post(
    "",
    response_model=EducatorApplicationResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Submit educator application (pending admin review)",
)
def create_educator_application(
    data: EducatorApplicationCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return EducatorApplicationService.create_application(
        db=db,
        user_id=current_user.id,
        data=data,
    )


@router.get(
    "/me",
    response_model=EducatorApplicationResponse | None,
    summary="Get current user's latest educator application and status",
)
def get_my_educator_application(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return EducatorApplicationService.get_user_application(
        db=db,
        user_id=current_user.id,
    )


@router.post(
    "/me/cancel",
    response_model=EducatorApplicationResponse,
    summary="Cancel current pending educator application",
)
def cancel_my_educator_application(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return EducatorApplicationService.cancel_user_application(
        db=db,
        user_id=current_user.id,
    )
