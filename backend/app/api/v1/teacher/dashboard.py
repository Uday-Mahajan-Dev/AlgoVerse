from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_teacher, get_db
from app.models.user import User
from app.schemas.teacher_dashboard import TeacherDashboardResponseSchema
from app.services.teacher_dashboard_service import TeacherDashboardService


router = APIRouter(
    prefix="/teacher",
    tags=["Teacher Dashboard"],
)


@router.get(
    "/dashboard",
    response_model=TeacherDashboardResponseSchema,
)
def get_teacher_dashboard(
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    return TeacherDashboardService.get_dashboard_data(
        db=db,
        teacher=current_teacher,
    )
