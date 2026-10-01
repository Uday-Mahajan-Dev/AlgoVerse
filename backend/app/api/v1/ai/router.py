from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_student, get_current_user, get_db
from app.models.user import User
from app.schemas.ai_tutor import (
    HintRequest,
    HintResponse,
    ErrorExplanationRequest,
    ErrorExplanationResponse,
    RecommendationResponse,
    AIStatusResponse,
)
from app.services.ai_tutor_service import AITutorService

router = APIRouter(tags=["AI Mentorship"])


@router.get(
    "/status",
    response_model=AIStatusResponse,
    status_code=status.HTTP_200_OK,
    summary="Check AI tutor status and configuration",
)
def get_ai_status(
    current_user: User = Depends(get_current_user),
) -> AIStatusResponse:
    return AITutorService.get_status()


@router.post(
    "/hint",
    response_model=HintResponse,
    status_code=status.HTTP_200_OK,
    summary="Get contextual Socratic hint for visualization or coding lesson",
)
def get_hint(
    payload: HintRequest,
    db: Session = Depends(get_db),
    current_student: User = Depends(get_current_student),
) -> HintResponse:
    hint_text, remaining = AITutorService.get_hint(
        db=db,
        student_id=current_student.id,
        lesson_id=payload.lesson_id,
        hint_level=payload.hint_level,
        visualization_state=payload.visualization_state,
        code=payload.code,
        error_info=payload.error_info,
    )
    return HintResponse(
        hint_text=hint_text,
        hint_level=payload.hint_level,
        hints_remaining=remaining,
    )


@router.post(
    "/explain",
    response_model=ErrorExplanationResponse,
    status_code=status.HTTP_200_OK,
    summary="Get AI explanation for a submission error",
)
def explain_error(
    payload: ErrorExplanationRequest,
    db: Session = Depends(get_db),
    current_student: User = Depends(get_current_student),
) -> ErrorExplanationResponse:
    explanation, failed_summary = AITutorService.explain_error(
        db=db,
        student_id=current_student.id,
        submission_id=payload.submission_id,
    )
    return ErrorExplanationResponse(
        explanation=explanation,
        failed_test_summary=failed_summary,
    )


@router.get(
    "/recommend",
    response_model=RecommendationResponse,
    status_code=status.HTTP_200_OK,
    summary="Get personalized lesson recommendations",
)
def get_recommendations(
    db: Session = Depends(get_db),
    current_student: User = Depends(get_current_student),
) -> RecommendationResponse:
    items = AITutorService.recommend_next(
        db=db,
        student_id=current_student.id,
    )
    return RecommendationResponse(recommendations=items)
