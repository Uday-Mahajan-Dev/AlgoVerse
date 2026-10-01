from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_teacher, get_current_user, get_db
from app.models.user import User
from app.schemas.dashboard import (
    StudentDashboardResponse,
    TeacherDashboardResponse,
)
from app.services.dashboard_service import DashboardService

router = APIRouter(
    tags=["Dashboard"],
)


@router.get(
    "/student",
    response_model=StudentDashboardResponse,
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
    "/teacher",
    response_model=TeacherDashboardResponse,
)
def get_teacher_dashboard(
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    return DashboardService.get_teacher_dashboard(
        db=db,
        teacher=current_teacher,
    )
