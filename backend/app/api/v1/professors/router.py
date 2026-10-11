from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_student, get_db, get_optional_current_user
from app.models.user import User
from app.schemas.feedback import ProfessorRatingCreate, ProfessorRatingsSummary
from app.schemas.mentorship import ProfessorListItem
from app.services.feedback_service import FeedbackService
from app.services.mentorship_service import MentorshipService

router = APIRouter(
    tags=["Professors"],
)


@router.get(
    "",
    response_model=list[ProfessorListItem],
    summary="List all verified professors in directory with capacity and student stats",
)
def list_professors(
    q: str | None = Query(default=None, description="Search by name, username, institution, or specialty"),
    verified_only: bool = Query(default=True, description="Filter only admin-verified faculty"),
    include_unverified: bool = Query(default=False, description="Include unverified faculty for admin tools"),
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_optional_current_user),
):
    effective_verified_only = False if include_unverified else verified_only
    return MentorshipService.get_professors_directory(
        db=db,
        search_query=q,
        verified_only=effective_verified_only,
    )


@router.post(
    "/{teacher_id}/rate",
    response_model=ProfessorRatingsSummary,
    summary="Rate an educator (only approved mentees allowed)",
)
def rate_professor(
    teacher_id: UUID,
    data: ProfessorRatingCreate,
    db: Session = Depends(get_db),
    current_student: User = Depends(get_current_student),
):
    return FeedbackService.submit_professor_rating(
        db=db,
        student_id=current_student.id,
        teacher_id=teacher_id,
        data=data,
    )


@router.get(
    "/{teacher_id}/ratings",
    response_model=ProfessorRatingsSummary,
    summary="Get ratings and reviews for an educator",
)
def get_professor_ratings(
    teacher_id: UUID,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_optional_current_user),
):
    student_id = current_user.id if current_user else None
    return FeedbackService.get_professor_ratings_summary(
        db=db,
        teacher_id=teacher_id,
        student_id=student_id,
    )

