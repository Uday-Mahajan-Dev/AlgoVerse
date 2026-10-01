from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from app.api.deps import (
    get_current_student,
    get_current_teacher,
    get_current_user,
    get_db,
)
from app.models.user import User
from app.schemas.dashboard import (
    ContinueLearningResponse,
    StudentDashboardResponse,
    StudentMetricsResponse,
    TeacherDashboardResponse,
)
from app.schemas.teacher_analytics import AssignmentResponse
from app.services.dashboard_service import DashboardService

router = APIRouter(
    tags=["Dashboard"],
)


@router.get(
    "/student",
    response_model=StudentDashboardResponse,
    summary="Get complete student dashboard data",
)
def get_student_dashboard(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return DashboardService.get_student_dashboard(
        db=db,
        user=current_user,
    )


@router.get(
    "/continue-learning",
    response_model=ContinueLearningResponse | None,
    summary="Get personalized Continue Learning recommendation (4-priority resolver)",
)
def get_continue_learning(
    response: Response,
    current_student: User = Depends(get_current_student),
    db: Session = Depends(get_db),
):
    result = DashboardService.get_continue_learning(
        db=db,
        student_id=current_student.id,
    )
    if result is None:
        response.status_code = status.HTTP_204_NO_CONTENT
        return None
    return result


@router.get(
    "/metrics",
    response_model=StudentMetricsResponse,
    summary="Get real-time student metrics and daily streak",
)
def get_student_metrics(
    current_student: User = Depends(get_current_student),
    db: Session = Depends(get_db),
):
    return DashboardService.get_student_metrics(
        db=db,
        student_id=current_student.id,
    )


@router.get(
    "/teacher",
    response_model=TeacherDashboardResponse,
    summary="Get complete teacher dashboard data",
)
def get_teacher_dashboard(
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    return DashboardService.get_teacher_dashboard(
        db=db,
        teacher=current_teacher,
    )


@router.get(
    "/assignments",
    response_model=list[AssignmentResponse],
    summary="Get homework assignments for the authenticated student",
)
def get_student_assignments(
    current_student: User = Depends(get_current_student),
    db: Session = Depends(get_db),
):
    from app.services.teacher_analytics_service import TeacherAnalyticsService
    return TeacherAnalyticsService.get_student_assignments(
        db=db,
        student_id=current_student.id,
    )
