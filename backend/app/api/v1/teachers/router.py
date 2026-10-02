from uuid import UUID

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import (
    get_current_student,
    get_current_teacher,
    get_current_user,
    get_db,
)
from app.models.user import User
from app.schemas.teacher_analytics import (
    AssignmentCreateRequest,
    AssignmentResponse,
    BottleneckLessonResponse,
    ConceptPerformanceResponse,
    StudentProgressResponse,
    TeacherOverviewResponse,
)
from app.schemas.teachers import (
    EducatorRegistrationRequest,
    EducatorRegistrationResponse,
    JoinClassRequest,
    JoinClassResponse,
    MyTeacherResponse,
    TARequestResponse,
    TAResponseActionRequest,
    TAResponseActionResult,
    TeacherListItem,
    TeacherProfileResponse,
    TeacherSelectionResponse,
)
from app.services.teacher_analytics_service import TeacherAnalyticsService
from app.services.teacher_service import TeacherService

router = APIRouter(
    tags=["Teachers"],
)


# ============================================================
# TEACHER DISCOVERY & SELECTION (STUDENT / PUBLIC)
# ============================================================

@router.post(
    "/register-educator",
    response_model=EducatorRegistrationResponse,
    status_code=status.HTTP_200_OK,
    summary="Self-serve educator registration with age gate and TA supervisor approval flow",
)
def register_educator(
    request: EducatorRegistrationRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    bio_content = request.professional_bio or request.bio
    return TeacherService.register_educator(
        db=db,
        user_id=current_user.id,
        institution_name=request.institution_name,
        designation=request.designation,
        subject_expertise=request.subject_expertise,
        date_of_birth=request.date_of_birth,
        supervisor_email=request.supervisor_email,
        bio=bio_content,
    )


@router.get(
    "/ta-requests",
    response_model=list[TARequestResponse],
    summary="Get pending Teaching Assistant approval requests assigned to current teacher",
)
def get_ta_requests(
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    return TeacherService.get_ta_requests(
        db=db,
        teacher_id=current_teacher.id,
    )


@router.post(
    "/ta-requests/{request_id}/respond",
    response_model=TAResponseActionResult,
    summary="Approve or reject a pending Teaching Assistant approval request",
)
def respond_to_ta_request(
    request_id: UUID,
    body: TAResponseActionRequest,
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    return TeacherService.respond_to_ta_request(
        db=db,
        teacher_id=current_teacher.id,
        request_id=request_id,
        action=body.action,
    )


@router.post(
    "/join-class",
    response_model=JoinClassResponse,
    status_code=status.HTTP_200_OK,
    summary="Join an educator's class using a unique class joining code",
)
def join_class(
    request: JoinClassRequest,
    current_student: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return TeacherService.join_class_by_code(
        db=db,
        student_id=current_student.id,
        class_code=request.class_code,
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



# ============================================================
# TEACHER ANALYTICS (TEACHER ROLE ONLY)
# ============================================================

@router.get(
    "/analytics/overview",
    response_model=TeacherOverviewResponse,
    summary="Get teacher overview stats and recent student activity feed",
)
def get_teacher_overview(
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    return TeacherAnalyticsService.get_teacher_overview(
        db=db,
        teacher_id=current_teacher.id,
    )


@router.get(
    "/analytics/students",
    response_model=list[StudentProgressResponse],
    summary="Get detailed progress list for all students of this teacher",
)
def get_student_progress_list(
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    return TeacherAnalyticsService.get_student_progress_list(
        db=db,
        teacher_id=current_teacher.id,
    )


@router.get(
    "/analytics/bottlenecks",
    response_model=list[BottleneckLessonResponse],
    summary="Get top 10 bottleneck lessons with lowest student completion rates",
)
def get_bottleneck_lessons(
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    return TeacherAnalyticsService.get_bottleneck_lessons(
        db=db,
        teacher_id=current_teacher.id,
    )


@router.get(
    "/analytics/concepts",
    response_model=list[ConceptPerformanceResponse],
    summary="Get module-level concept mastery matrix across enrolled students",
)
def get_concept_performance_matrix(
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    return TeacherAnalyticsService.get_concept_performance_matrix(
        db=db,
        teacher_id=current_teacher.id,
    )


# ============================================================
# HOMEWORK ASSIGNMENT MANAGEMENT (TEACHER ROLE)
# ============================================================

@router.post(
    "/assignments",
    response_model=list[AssignmentResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create homework assignments for selected students",
)
def create_assignments(
    request: AssignmentCreateRequest,
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    return TeacherAnalyticsService.create_assignments(
        db=db,
        teacher_id=current_teacher.id,
        student_ids=request.student_ids,
        lesson_id=request.lesson_id,
        due_date=request.due_date,
        notes=request.notes,
    )


@router.get(
    "/assignments",
    response_model=list[AssignmentResponse],
    summary="List all homework assignments created by current teacher",
)
def get_teacher_assignments(
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    return TeacherAnalyticsService.get_teacher_assignments(
        db=db,
        teacher_id=current_teacher.id,
    )


# ============================================================
# TEACHER PROFILE & SELECTION
# ============================================================

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
