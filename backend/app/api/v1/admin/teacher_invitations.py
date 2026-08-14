from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import (
    get_current_admin,
    get_db,
)
from app.models.user import User
from app.schemas.teacher_invitation import (
    TeacherInvitationCreate,
    TeacherInvitationResponse,
)
from app.services.teacher_invitation_service import (
    TeacherInvitationService,
)


router = APIRouter(
    prefix="/teacher-invitations",
    tags=["Teacher Invitations"],
)


@router.post(
    "",
    response_model=TeacherInvitationResponse,
    status_code=201,
)
def create_teacher_invitation(
    data: TeacherInvitationCreate,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    return TeacherInvitationService.create_invitation(
        db=db,
        data=data,
        invited_by=current_admin,
    )