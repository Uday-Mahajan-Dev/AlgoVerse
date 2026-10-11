from uuid import UUID

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import (
    get_current_student,
    get_current_teacher,
    get_current_user,
    get_verified_teacher,
    get_db,
)
from app.models.user import User
from app.schemas.quiz import (
    QuizCreate,
    QuizUpdate,
    QuizLeaderboardEntry,
    QuizResponse,
    QuizStatsResponse,
    QuizSubmitRequest,
    QuizSubmitResponse,
)
from app.services.quiz_service import QuizService

router = APIRouter(
    tags=["Quizzes"],
)


@router.post(
    "",
    response_model=QuizResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new quiz with interactive questions (Teacher only)",
)
def create_quiz(
    data: QuizCreate,
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    if data.visibility in ("PUBLIC", "CLASS_ONLY"):
        get_verified_teacher(current_teacher, db)
    return QuizService.create_quiz(
        db=db,
        teacher_id=current_teacher.id,
        data=data,
    )


@router.put(
    "/{quiz_id}",
    response_model=QuizResponse,
    summary="Update an existing quiz (Teacher only)",
)
def update_quiz(
    quiz_id: UUID,
    data: QuizUpdate,
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    if data.visibility in ("PUBLIC", "CLASS_ONLY"):
        get_verified_teacher(current_teacher, db)
    return QuizService.update_quiz(
        db=db,
        quiz_id=quiz_id,
        teacher_id=current_teacher.id,
        data=data,
    )


@router.post(
    "/{quiz_id}/publish",
    response_model=QuizResponse,
    summary="Publish a quiz to students (verified faculty only)",
)
def publish_quiz(
    quiz_id: UUID,
    verified_teacher: User = Depends(get_verified_teacher),
    db: Session = Depends(get_db),
):
    return QuizService.update_quiz(
        db=db,
        quiz_id=quiz_id,
        teacher_id=verified_teacher.id,
        data=QuizUpdate(visibility="CLASS_ONLY"),
    )


@router.get(
    "/teacher",
    response_model=list[QuizResponse],
    summary="List quizzes authored by current teacher",
)
def get_teacher_quizzes(
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    return QuizService.get_teacher_quizzes(
        db=db,
        teacher_id=current_teacher.id,
    )


@router.get(
    "/public",
    response_model=list[QuizResponse],
    summary="List all public quizzes available for anyone to play",
)
def get_public_quizzes(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return QuizService.get_public_quizzes(db=db)


@router.get(
    "/class",
    response_model=list[QuizResponse],
    summary="List class quizzes for student's teacher or created by teacher",
)
def get_class_quizzes(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return QuizService.get_class_quizzes(
        db=db,
        user_id=current_user.id,
    )



@router.get(
    "/{quiz_id}",
    response_model=QuizResponse,
    summary="Get quiz details with questions",
)
def get_quiz_details(
    quiz_id: UUID,
    play: bool = Query(default=False, description="Set to true if fetching for live gameplay (omits answers)"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return QuizService.get_quiz_by_id(
        db=db,
        quiz_id=quiz_id,
        user_id=current_user.id,
        is_playing=play,
    )


@router.post(
    "/{quiz_id}/submit",
    response_model=QuizSubmitResponse,
    summary="Submit answers for a completed quiz gameplay",
)
def submit_quiz_attempt(
    quiz_id: UUID,
    submission: QuizSubmitRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return QuizService.submit_quiz(
        db=db,
        quiz_id=quiz_id,
        student_id=current_user.id,
        submission=submission,
    )


@router.get(
    "/{quiz_id}/leaderboard",
    response_model=list[QuizLeaderboardEntry],
    summary="Get top ranked leaderboard scorers for this quiz",
)
def get_quiz_leaderboard(
    quiz_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return QuizService.get_quiz_leaderboard(
        db=db,
        quiz_id=quiz_id,
        current_user=current_user,
    )


@router.get(
    "/{quiz_id}/stats",
    response_model=QuizStatsResponse,
    summary="Get detailed author stats and class participant breakdown (Teacher only)",
)
def get_quiz_stats(
    quiz_id: UUID,
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    return QuizService.get_quiz_stats(
        db=db,
        quiz_id=quiz_id,
        teacher_id=current_teacher.id,
    )
