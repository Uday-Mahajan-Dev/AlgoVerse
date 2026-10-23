from uuid import UUID

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import (
    get_current_student,
    get_current_teacher,
    get_current_user,
    get_db,
    get_verified_teacher,
)
from app.models.user import User
from app.schemas.mentorship import (
    ClassroomSettingsRequest,
    ClassroomSettingsResponse,
    MentorshipRequestResponse,
    StudentMentorItem,
)
from app.services.mentorship_service import MentorshipService
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
from app.schemas.quiz import QuizStatsResponse
from app.services.quiz_service import QuizService
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
    summary="Request to join an educator's class using a unique class joining code",
)
def join_class(
    request: JoinClassRequest,
    current_student: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Enforces Phase 1: Students do NOT auto-enroll; submits Mentorship Request
    req = MentorshipService.create_request(
        db=db,
        student_id=current_student.id,
        class_code=request.class_code,
    )
    return JoinClassResponse(
        message=f"Mentorship request submitted to {req.teacher_name}. Awaiting faculty approval.",
        teacher_id=req.teacher_id,
        teacher_name=req.teacher_name,
        institution_name=req.teacher_institution or "",
        class_code=req.class_code_attempted or request.class_code,
        joined_at=req.created_at,
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
    "/my-mentors",
    response_model=list[StudentMentorItem],
    summary="Get all approved mentor professors for current student (multi-professor)",
)
def get_my_mentors(
    current_student: User = Depends(get_current_student),
    db: Session = Depends(get_db),
):
    return MentorshipService.get_my_mentors(
        db=db,
        student_id=current_student.id,
    )


# ============================================================
# MENTORSHIP REQUESTS & CLASSROOM SETTINGS (TEACHER ROLE)
# ============================================================

@router.get(
    "/me/mentorship-requests",
    response_model=list[MentorshipRequestResponse],
    summary="Get mentorship requests for current teacher, with optional status filter",
)
def get_teacher_mentorship_requests(
    status: str | None = Query(default=None, description="Filter by status: PENDING, APPROVED, REJECTED, ALL"),
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    return MentorshipService.get_teacher_requests(
        db=db,
        teacher_id=current_teacher.id,
        status_filter=status,
    )


@router.post(
    "/me/mentorship-requests/{request_id}/approve",
    response_model=MentorshipRequestResponse,
    summary="Approve a student mentorship request (verified faculty only, checks capacity)",
)
def approve_mentorship_request(
    request_id: UUID,
    verified_teacher: User = Depends(get_verified_teacher),
    db: Session = Depends(get_db),
):
    return MentorshipService.approve_request(
        db=db,
        request_id=request_id,
        teacher_id=verified_teacher.id,
    )


@router.post(
    "/me/mentorship-requests/{request_id}/reject",
    response_model=MentorshipRequestResponse,
    summary="Reject a student mentorship request (verified faculty only)",
)
def reject_mentorship_request(
    request_id: UUID,
    verified_teacher: User = Depends(get_verified_teacher),
    db: Session = Depends(get_db),
):
    return MentorshipService.reject_request(
        db=db,
        request_id=request_id,
        teacher_id=verified_teacher.id,
    )


@router.get(
    "/me/classroom-settings",
    response_model=ClassroomSettingsResponse,
    summary="Get classroom capacity settings and current enrollment",
)
def get_classroom_settings(
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    return MentorshipService.get_classroom_settings(
        db=db,
        teacher_id=current_teacher.id,
    )


@router.patch(
    "/me/classroom-settings",
    response_model=ClassroomSettingsResponse,
    summary="Update classroom max capacity threshold and request intake toggle (verified faculty only)",
)
def update_classroom_settings(
    body: ClassroomSettingsRequest,
    verified_teacher: User = Depends(get_verified_teacher),
    db: Session = Depends(get_db),
):
    return MentorshipService.update_classroom_settings(
        db=db,
        teacher_id=verified_teacher.id,
        max_students=body.max_students,
        is_accepting_requests=body.is_accepting_requests,
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


from app.schemas.custom_problem import (
    CustomProblemCreate,
    CustomProblemUpdate,
    CustomProblemResponse,
    CustomProblemStatsResponse,
    CustomProblemSubmissionsResponse,
    GenerateTemplatesRequest,
    GenerateTemplatesResponse,
)
from app.services.custom_problem_service import CustomProblemService


# ============================================================
# EDUCATOR STUDIO - CUSTOM CODING PROBLEMS (TEACHER ROLE)
# ============================================================

@router.post(
    "/custom-problems/generate-templates",
    response_model=GenerateTemplatesResponse,
    summary="Auto-generate Python, Java, and C++ starter templates from single teacher code",
)
def generate_starter_templates(
    request: GenerateTemplatesRequest,
    current_teacher: User = Depends(get_current_teacher),
):
    templates = CustomProblemService.auto_generate_starter_codes(
        code=request.code,
        source_lang=request.language,
    )
    return GenerateTemplatesResponse(
        starter_code_python=templates["starter_code_python"],
        starter_code_java=templates["starter_code_java"],
        starter_code_cpp=templates["starter_code_cpp"],
    )


@router.post(
    "/custom-problems",
    response_model=CustomProblemResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new custom algorithmic problem in Educator Studio",
)
def create_custom_problem(
    request: CustomProblemCreate,
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    if (request.visibility or "").upper() in ("CLASS_ONLY", "PUBLIC"):
        get_verified_teacher(current_teacher, db)
    return CustomProblemService.create_custom_problem(
        db=db,
        teacher_id=current_teacher.id,
        data=request,
    )


@router.get(
    "/custom-problems",
    response_model=list[CustomProblemResponse],
    summary="List all custom problems authored by current teacher",
)
def get_teacher_custom_problems(
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    return CustomProblemService.get_teacher_custom_problems(
        db=db,
        teacher_id=current_teacher.id,
    )


@router.get(
    "/custom-problems/{problem_id}",
    response_model=CustomProblemResponse,
    summary="Get details of a custom problem",
)
def get_custom_problem(
    problem_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return CustomProblemService.get_custom_problem_by_id(
        db=db,
        problem_id=problem_id,
        user_id=current_user.id,
    )


@router.put(
    "/custom-problems/{problem_id}",
    response_model=CustomProblemResponse,
    summary="Update an existing custom problem",
)
def update_custom_problem(
    problem_id: UUID,
    request: CustomProblemUpdate,
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    if (request.visibility or "").upper() in ("CLASS_ONLY", "PUBLIC"):
        get_verified_teacher(current_teacher, db)
    return CustomProblemService.update_custom_problem(
        db=db,
        problem_id=problem_id,
        teacher_id=current_teacher.id,
        data=request,
    )


@router.post(
    "/custom-problems/{problem_id}/publish",
    response_model=CustomProblemResponse,
    summary="Publish a custom problem to students (verified faculty only)",
)
def publish_custom_problem(
    problem_id: UUID,
    verified_teacher: User = Depends(get_verified_teacher),
    db: Session = Depends(get_db),
):
    return CustomProblemService.publish_problem(
        db=db,
        teacher=verified_teacher,
        problem_id=problem_id,
    )


@router.get(
    "/custom-problems/{problem_id}/stats",
    response_model=CustomProblemStatsResponse,
    summary="Get global and class statistics for a custom problem",
)
def get_custom_problem_stats(
    problem_id: UUID,
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    return CustomProblemService.get_custom_problem_stats(
        db=db,
        problem_id=problem_id,
        teacher_id=current_teacher.id,
    )


@router.get(
    "/custom-problems/{problem_id}/submissions",
    response_model=CustomProblemSubmissionsResponse,
    summary="Get detailed submission history with student code for a custom problem (Teacher only)",
)
def get_custom_problem_submissions(
    problem_id: UUID,
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    return CustomProblemService.get_custom_problem_submissions(
        db=db,
        problem_id=problem_id,
        teacher_id=current_teacher.id,
    )


@router.get(
    "/quizzes/{quiz_id}/stats",
    response_model=QuizStatsResponse,
    summary="Get global and class statistics for a quiz (Teacher only)",
)
def get_teacher_quiz_stats(
    quiz_id: UUID,
    current_teacher: User = Depends(get_current_teacher),
    db: Session = Depends(get_db),
):
    return QuizService.get_quiz_stats(
        db=db,
        quiz_id=quiz_id,
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
        custom_problem_id=request.custom_problem_id,
        quiz_id=request.quiz_id,
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


from app.schemas.quiz import QuizResponse
from app.services.quiz_service import QuizService


@router.get(
    "/{teacher_id}/custom-problems",
    response_model=list[CustomProblemResponse],
    summary="Get custom problems authored by a teacher",
)
def get_teacher_profile_custom_problems(
    teacher_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return CustomProblemService.get_teacher_published_custom_problems(
        db=db,
        teacher_id=teacher_id,
    )


@router.get(
    "/{teacher_id}/quizzes",
    response_model=list[QuizResponse],
    summary="Get quizzes authored by a teacher",
)
def get_teacher_profile_quizzes(
    teacher_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return QuizService.get_teacher_quizzes(
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

