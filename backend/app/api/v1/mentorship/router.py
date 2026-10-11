from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_student, get_current_user, get_db
from app.models.user import User
from app.schemas.mentorship import (
    MentorshipRequestCreate,
    MentorshipRequestResponse,
)
from app.services.mentorship_service import MentorshipService

router = APIRouter(
    tags=["Mentorship"],
)


@router.post(
    "/requests",
    response_model=MentorshipRequestResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Submit a mentorship request to a professor via ID or class code",
)
def create_mentorship_request(
    body: MentorshipRequestCreate,
    current_student: User = Depends(get_current_student),
    db: Session = Depends(get_db),
):
    return MentorshipService.create_request(
        db=db,
        student_id=current_student.id,
        teacher_id=body.teacher_id,
        class_code=body.class_code,
        message=body.message,
    )


@router.get(
    "/requests/me",
    response_model=list[MentorshipRequestResponse],
    summary="Get all mentorship requests submitted by current student",
)
def get_my_mentorship_requests(
    current_student: User = Depends(get_current_student),
    db: Session = Depends(get_db),
):
    return MentorshipService.get_student_requests(
        db=db,
        student_id=current_student.id,
    )
