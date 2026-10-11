from typing import List
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api.deps import (
    get_current_user,
    get_db,
    get_optional_current_user,
    get_verified_teacher,
)
from app.models.user import User
from app.schemas.custom_problem import (
    CustomProblemCreate,
    CustomProblemUpdate,
    CustomProblemResponse,
)
from app.schemas.feedback import (
    ProblemFeedbackCreate,
    ProblemFeedbackResponse,
    ProblemFeedbackSummary,
)
from app.services.feedback_service import FeedbackService
from app.schemas.problem import (
    CodeExecutionRequest,
    ProblemDetailResponse,
    SubmissionResultResponse,
    SubmissionSummaryResponse,
    TrialResultResponse,
)
from app.services.code_execution.executor_factory import get_executor_status
from app.services.custom_problem_service import CustomProblemService
from app.services.judge_service import JudgeService

router = APIRouter()


@router.post("/custom", response_model=CustomProblemResponse, status_code=status.HTTP_201_CREATED)
def create_custom_problem(
    request: CustomProblemCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Create a new custom algorithmic problem with test cases.
    """
    return CustomProblemService.create_custom_problem(
        db=db,
        teacher_id=current_user.id,
        data=request,
    )


@router.get("/custom/{problem_id}", response_model=CustomProblemResponse)
def get_custom_problem(
    problem_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Fetch custom problem details and test cases.
    """
    return CustomProblemService.get_custom_problem_by_id(
        db=db,
        problem_id=problem_id,
        user_id=current_user.id,
    )


@router.put("/custom/{problem_id}", response_model=CustomProblemResponse)
def update_custom_problem(
    problem_id: UUID,
    request: CustomProblemUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Update custom problem details and test cases.
    """
    return CustomProblemService.update_custom_problem(
        db=db,
        problem_id=problem_id,
        teacher_id=current_user.id,
        data=request,
    )


@router.post("/custom/{problem_id}/publish", response_model=CustomProblemResponse)
def publish_custom_problem(
    problem_id: UUID,
    verified_teacher: User = Depends(get_verified_teacher),
    db: Session = Depends(get_db),
):
    """
    Publish a custom problem to students (verified faculty only).
    """
    return CustomProblemService.publish_problem(
        db=db,
        teacher=verified_teacher,
        problem_id=problem_id,
    )



@router.get("/executor-status")
def check_executor_status(
    current_user: User = Depends(get_current_user),
):
    """
    Check the current backend code execution engine status (Judge0 vs Subprocess fallback).
    """
    return get_executor_status()


@router.get("/lesson/{lesson_slug}", response_model=ProblemDetailResponse)
def get_problem_for_lesson(
    lesson_slug: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Fetch coding problem details, starter codes, and public test cases for a lesson.
    NEVER returns solution code or hidden test cases.
    """
    problem = JudgeService.get_problem_by_lesson_slug(db, lesson_slug)
    if not problem:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No coding problem found for lesson '{lesson_slug}'",
        )
    return problem


@router.post("/{problem_id}/run", response_model=TrialResultResponse)
async def run_trial(
    problem_id: UUID,
    request: CodeExecutionRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Execute student code against public test cases only.
    Does not save a submission record to the database.
    """
    try:
        result = await JudgeService.run_trial(
            db=db,
            problem_id=problem_id,
            code=request.code,
            language=request.language.lower(),
        )
        return result
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Execution error: {str(e)}",
        )


@router.post("/{problem_id}/submit", response_model=SubmissionResultResponse)
async def submit_solution(
    problem_id: UUID,
    request: CodeExecutionRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Execute student code against all test cases (public + hidden).
    Saves a Submission record and marks the lesson complete if Accepted (AC).
    """
    try:
        result = await JudgeService.submit_solution(
            db=db,
            student_id=current_user.id,
            problem_id=problem_id,
            code=request.code,
            language=request.language.lower(),
        )
        return result
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Evaluation error: {str(e)}",
        )


@router.get("/{problem_id}/submissions", response_model=List[SubmissionSummaryResponse])
def get_submissions(
    problem_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get the authenticated student's submission history for a specific problem.
    """
    return JudgeService.get_submissions(
        db=db,
        student_id=current_user.id,
        problem_id=problem_id,
    )


@router.post(
    "/{problem_id}/feedback",
    response_model=ProblemFeedbackResponse,
    summary="Submit or update rating and feedback for a problem (course or custom)",
)
def submit_problem_feedback(
    problem_id: UUID,
    data: ProblemFeedbackCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return FeedbackService.submit_problem_feedback(
        db=db,
        student_id=current_user.id,
        problem_id=problem_id,
        data=data,
    )


@router.get(
    "/{problem_id}/feedback/summary",
    response_model=ProblemFeedbackSummary,
    summary="Get rating summary and current student review for a problem",
)
def get_problem_feedback_summary(
    problem_id: UUID,
    problem_kind: str = Query(default="course", description="'course' or 'custom'"),
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_optional_current_user),
):
    student_id = current_user.id if current_user else None
    return FeedbackService.get_problem_feedback_summary(
        db=db,
        problem_id=problem_id,
        problem_kind=problem_kind,
        student_id=student_id,
    )

