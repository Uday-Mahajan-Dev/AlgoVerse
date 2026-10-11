from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import (
    get_current_student,
    get_db,
    get_optional_current_user,
)
from app.models.user import User
from app.schemas.courses import (
    CourseDetailResponse,
    CourseListResponse,
    CourseProgressResponse,
    EnrollmentResponse,
    LessonCompletionResponse,
    LessonResponse,
    LessonSnippetUpdateRequest,
)
from app.schemas.dashboard import LessonAccessResponse
from app.schemas.feedback import (
    LessonFeedbackCreate,
    LessonFeedbackResponse,
    LessonFeedbackSummary,
)
from app.services.course_service import CourseService
from app.services.feedback_service import FeedbackService


router = APIRouter(tags=["courses"])
lesson_router = APIRouter(tags=["lessons"])


@router.get(
    "",
    response_model=list[CourseListResponse],
    summary="List all published courses",
)
def list_courses(
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_optional_current_user),
):
    user_id = current_user.id if current_user else None
    return CourseService.get_published_courses(db=db, user_id=user_id)


@router.get(
    "/my-progress",
    response_model=list[CourseProgressResponse],
    summary="Get all enrolled courses progress for current student",
)
def get_my_all_progress(
    db: Session = Depends(get_db),
    current_student: User = Depends(get_current_student),
):
    return CourseService.get_all_student_progress(
        db=db,
        student_id=current_student.id,
    )


@router.post(
    "/lessons/{lesson_id}/access",
    response_model=LessonAccessResponse,
    summary="Record student lesson access timestamp (courses prefix)",
)
def access_lesson_courses(
    lesson_id: UUID,
    db: Session = Depends(get_db),
    current_student: User = Depends(get_current_student),
):
    return CourseService.record_lesson_access(
        db=db,
        student_id=current_student.id,
        lesson_id=lesson_id,
    )


@lesson_router.post(
    "/lessons/{lesson_id}/access",
    response_model=LessonAccessResponse,
    summary="Record student lesson access timestamp",
)
def access_lesson_direct(
    lesson_id: UUID,
    db: Session = Depends(get_db),
    current_student: User = Depends(get_current_student),
):
    return CourseService.record_lesson_access(
        db=db,
        student_id=current_student.id,
        lesson_id=lesson_id,
    )


@router.post(
    "/lessons/{lesson_id}/complete",
    response_model=LessonCompletionResponse,
    summary="Mark a lesson as completed by student (courses prefix)",
)
def complete_lesson_courses(
    lesson_id: UUID,
    db: Session = Depends(get_db),
    current_student: User = Depends(get_current_student),
):
    return CourseService.complete_lesson(
        db=db,
        student_id=current_student.id,
        lesson_id=lesson_id,
    )


@lesson_router.post(
    "/lessons/{lesson_id}/complete",
    response_model=LessonCompletionResponse,
    summary="Mark a lesson as completed by student",
)
def complete_lesson_direct(
    lesson_id: UUID,
    db: Session = Depends(get_db),
    current_student: User = Depends(get_current_student),
):
    return CourseService.complete_lesson(
        db=db,
        student_id=current_student.id,
        lesson_id=lesson_id,
    )


@lesson_router.post(
    "/lessons/{lesson_id}/feedback",
    response_model=LessonFeedbackResponse,
    summary="Submit or update rating and feedback for a lesson",
)
def submit_lesson_feedback(
    lesson_id: UUID,
    data: LessonFeedbackCreate,
    db: Session = Depends(get_db),
    current_student: User = Depends(get_current_student),
):
    return FeedbackService.submit_lesson_feedback(
        db=db,
        student_id=current_student.id,
        lesson_id=lesson_id,
        data=data,
    )


@lesson_router.get(
    "/lessons/{lesson_id}/feedback/summary",
    response_model=LessonFeedbackSummary,
    summary="Get rating summary and current student review for a lesson",
)
def get_lesson_feedback_summary(
    lesson_id: UUID,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_optional_current_user),
):
    student_id = current_user.id if current_user else None
    return FeedbackService.get_lesson_feedback_summary(
        db=db,
        lesson_id=lesson_id,
        student_id=student_id,
    )


@lesson_router.put(
    "/lessons/{lesson_id}/snippets",
    response_model=LessonResponse,
    summary="Update multi-language snippets for a visualization lesson",
)
def update_lesson_snippets(
    lesson_id: UUID,
    payload: LessonSnippetUpdateRequest,
    db: Session = Depends(get_db),
    current_student: User = Depends(get_current_student),
):
    return CourseService.update_lesson_snippets(
        db=db,
        lesson_id=lesson_id,
        payload=payload,
    )


@router.get(
    "/{slug}",
    response_model=CourseDetailResponse,
    summary="Get course detail by slug",
)
def get_course_detail(
    slug: str,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_optional_current_user),
):
    user_id = current_user.id if current_user else None
    return CourseService.get_course_detail(
        db=db,
        course_slug=slug,
        user_id=user_id,
    )


@router.post(
    "/{slug}/enroll",
    response_model=EnrollmentResponse,
    summary="Enroll current student in a course",
)
def enroll_in_course(
    slug: str,
    db: Session = Depends(get_db),
    current_student: User = Depends(get_current_student),
):
    return CourseService.enroll_in_course(
        db=db,
        student_id=current_student.id,
        course_slug=slug,
    )


@router.delete(
    "/{slug}/enroll",
    summary="Drop / un-enroll from a course",
)
def drop_course(
    slug: str,
    db: Session = Depends(get_db),
    current_student: User = Depends(get_current_student),
):
    return CourseService.drop_course(
        db=db,
        student_id=current_student.id,
        course_identifier=slug,
    )


@router.get(
    "/{slug}/progress",
    response_model=CourseProgressResponse,
    summary="Get student progress for a specific course",
)
def get_course_progress(
    slug: str,
    db: Session = Depends(get_db),
    current_student: User = Depends(get_current_student),
):
    return CourseService.get_student_progress(
        db=db,
        student_id=current_student.id,
        course_slug=slug,
    )
