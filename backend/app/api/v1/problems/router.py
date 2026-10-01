from typing import List
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.problem import (
    CodeExecutionRequest,
    ProblemDetailResponse,
    SubmissionResultResponse,
    SubmissionSummaryResponse,
    TrialResultResponse,
)
from app.services.judge_service import JudgeService

router = APIRouter()


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
def run_trial(
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
        result = JudgeService.run_trial(
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
def submit_solution(
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
        result = JudgeService.submit_solution(
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
