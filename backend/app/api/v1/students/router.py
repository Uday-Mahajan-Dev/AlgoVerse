from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.custom_problem import CustomProblemResponse
from app.services.custom_problem_service import CustomProblemService

router = APIRouter(
    tags=["Students"],
)


@router.get(
    "/me/mentor-problems",
    response_model=list[CustomProblemResponse],
    summary="Get custom problems published by the student's linked mentor teacher(s)",
)
def get_mentor_problems(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return CustomProblemService.get_mentor_custom_problems(
        db=db,
        student_id=current_user.id,
    )
