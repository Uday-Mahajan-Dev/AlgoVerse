from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_student, get_current_user, get_db
from app.models.user import User
from app.schemas.teachers import (
    MyTeacherResponse,
    TeacherListItem,
    TeacherProfileResponse,
    TeacherSelectionResponse,
)
from app.services.teacher_service import TeacherService

router = APIRouter(
    tags=["Teachers"],
)


@router.get(
    "",
    response_model=list[TeacherListItem],
)
def list_teachers(
    q: str | None = Query(default=None, description="Search by name, username, or bio"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return TeacherService.get_all_teachers(
        db=db,
        search_query=q,
    )


@router.get(
    "/my-teacher",
    response_model=MyTeacherResponse,
)
def get_my_teacher(
    current_student: User = Depends(get_current_student),
    db: Session = Depends(get_db),
):
    return TeacherService.get_my_teacher(
        db=db,
        student_id=current_student.id,
    )


@router.get(
    "/{teacher_id}",
    response_model=TeacherProfileResponse,
)
def get_teacher_profile(
    teacher_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return TeacherService.get_teacher_profile(
        db=db,
        teacher_id=teacher_id,
    )


@router.post(
    "/{teacher_id}/select",
    response_model=TeacherSelectionResponse,
)
def select_teacher(
    teacher_id: UUID,
    current_student: User = Depends(get_current_student),
    db: Session = Depends(get_db),
):
    return TeacherService.select_teacher(
        db=db,
        student_id=current_student.id,
        teacher_id=teacher_id,
    )
