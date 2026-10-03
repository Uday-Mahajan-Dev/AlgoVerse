from datetime import datetime, timedelta, timezone
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import desc, func, select
from sqlalchemy.orm import Session, selectinload

from app.models.assignment import Assignment
from app.models.course import Course
from app.models.course_enrollment import CourseEnrollment
from app.models.course_module import CourseModule
from app.models.custom_problem import CustomProblem
from app.models.lesson import Lesson
from app.models.lesson_completion import LessonCompletion
from app.models.problem import Problem
from app.models.quiz import Quiz
from app.models.student_lesson_activity import StudentLessonActivity
from app.models.student_teacher import StudentTeacher
from app.models.submission import Submission
from app.models.user import User
from app.schemas.teacher_analytics import (
    AssignmentResponse,
    BottleneckLessonResponse,
    ConceptPerformanceResponse,
    RecentActivityItem,
    StudentProgressResponse,
    TeacherOverviewResponse,
)
from app.services.badge_service import BadgeService
from app.services.notification_service import NotificationService



class TeacherAnalyticsService:

    @staticmethod
    def _get_teacher_students(db: Session, teacher_id: UUID) -> list[User]:
        """Fetch all student User entities paired with this teacher."""
        return (
            db.execute(
                select(User)
                .join(StudentTeacher, StudentTeacher.student_id == User.id)
                .where(StudentTeacher.teacher_id == teacher_id)
            )
            .scalars()
            .all()
        )

    @staticmethod
    def _calculate_student_streak(db: Session, student_id: UUID) -> int:
        """Calculate continuous daily streak in UTC calendar days."""
        # TODO: use student timezone from profile when available
        completion_dates_raw = (
            db.execute(
                select(func.date(LessonCompletion.completed_at))
                .where(LessonCompletion.student_id == student_id)
                .distinct()
                .order_by(desc(func.date(LessonCompletion.completed_at)))
            )
            .scalars()
            .all()
        )

        date_set = set(completion_dates_raw)
        today = datetime.now(timezone.utc).date()
        yesterday = today - timedelta(days=1)

        streak = 0
        if today in date_set:
            curr = today
            while curr in date_set:
                streak += 1
                curr -= timedelta(days=1)
        elif yesterday in date_set:
            curr = yesterday
            while curr in date_set:
                streak += 1
                curr -= timedelta(days=1)

        return streak

    @staticmethod
    def _calculate_student_course_completion_pct(
        db: Session,
        student_id: UUID,
        course_id: UUID,
    ) -> float:
        """Compute 0-100 completion percentage for a student in a course."""
        course = (
            db.execute(
                select(Course)
                .where(Course.id == course_id)
                .options(selectinload(Course.modules).selectinload(CourseModule.lessons))
            )
            .scalars()
            .first()
        )
        if not course:
            return 0.0

        all_lesson_ids = [
            lesson.id for module in course.modules for lesson in module.lessons
        ]
        if not all_lesson_ids:
            return 0.0

        completed_count = (
            db.scalar(
                select(func.count(LessonCompletion.id)).where(
                    LessonCompletion.student_id == student_id,
                    LessonCompletion.lesson_id.in_(all_lesson_ids),
                )
            )
            or 0
        )

        return round((completed_count / len(all_lesson_ids)) * 100.0, 2)

    @classmethod
    def get_teacher_overview(
        cls,
        db: Session,
        teacher_id: UUID,
    ) -> TeacherOverviewResponse:
        """Overview KPI cards and recent student activity feed for teacher."""
        students = cls._get_teacher_students(db, teacher_id)
        total_students = len(students)
        if total_students == 0:
            return TeacherOverviewResponse(
                total_students=0,
                active_students=0,
                avg_course_completion=0.0,
                total_submissions_today=0,
                recent_activity_feed=[],
            )

        student_ids = [s.id for s in students]
        student_map = {s.id: s for s in students}
        now_utc = datetime.now(timezone.utc)
        seven_days_ago = now_utc - timedelta(days=7)
        today_date = now_utc.date()

        # 1. Active students count (completion or submission or access within 7 days)
        active_completers = set(
            db.execute(
                select(LessonCompletion.student_id)
                .where(
                    LessonCompletion.student_id.in_(student_ids),
                    LessonCompletion.completed_at >= seven_days_ago,
                )
                .distinct()
            ).scalars().all()
        )

        active_submitters = set(
            db.execute(
                select(Submission.student_id)
                .where(
                    Submission.student_id.in_(student_ids),
                    Submission.created_at >= seven_days_ago,
                )
                .distinct()
            ).scalars().all()
        )

        active_accessers = set(
            db.execute(
                select(StudentLessonActivity.student_id)
                .where(
                    StudentLessonActivity.student_id.in_(student_ids),
                    StudentLessonActivity.last_accessed_at >= seven_days_ago,
                )
                .distinct()
            ).scalars().all()
        )

        active_students_count = len(active_completers | active_submitters | active_accessers)

        # 2. Average course completion across all enrolled students and courses
        enrollments = (
            db.execute(
                select(CourseEnrollment).where(
                    CourseEnrollment.student_id.in_(student_ids)
                )
            )
            .scalars()
            .all()
        )

        if enrollments:
            total_pct_sum = sum(
                cls._calculate_student_course_completion_pct(
                    db, e.student_id, e.course_id
                )
                for e in enrollments
            )
            avg_course_completion = round(total_pct_sum / len(enrollments), 1)
        else:
            avg_course_completion = 0.0

        # 3. Total submissions today
        total_submissions_today = (
            db.scalar(
                select(func.count(Submission.id)).where(
                    Submission.student_id.in_(student_ids),
                    func.date(Submission.created_at) == today_date,
                )
            )
            or 0
        )

        # 4. Recent activity feed (completions + submissions merged, top 10)
        recent_completions = (
            db.execute(
                select(LessonCompletion, Lesson)
                .join(Lesson, Lesson.id == LessonCompletion.lesson_id)
                .where(LessonCompletion.student_id.in_(student_ids))
                .order_by(desc(LessonCompletion.completed_at))
                .limit(10)
            )
            .all()
        )

        recent_submissions = (
            db.execute(
                select(Submission, Problem)
                .join(Problem, Problem.id == Submission.problem_id)
                .where(Submission.student_id.in_(student_ids))
                .order_by(desc(Submission.created_at))
                .limit(10)
            )
            .all()
        )

        events: list[RecentActivityItem] = []
        for comp, lesson in recent_completions:
            student = student_map.get(comp.student_id)
            name = (
                f"{student.first_name} {student.last_name}".strip()
                if student and (student.first_name or student.last_name)
                else (student.username if student else "Student")
            )
            events.append(
                RecentActivityItem(
                    student_name=name,
                    student_avatar=student.avatar_url if student else None,
                    action_type="COMPLETED_LESSON",
                    item_title=lesson.title,
                    timestamp=comp.completed_at,
                )
            )

        for sub, prob in recent_submissions:
            student = student_map.get(sub.student_id)
            name = (
                f"{student.first_name} {student.last_name}".strip()
                if student and (student.first_name or student.last_name)
                else (student.username if student else "Student")
            )
            events.append(
                RecentActivityItem(
                    student_name=name,
                    student_avatar=student.avatar_url if student else None,
                    action_type=f"SUBMITTED_{sub.verdict}",
                    item_title=prob.title,
                    timestamp=sub.created_at,
                )
            )

        events.sort(key=lambda x: x.timestamp, reverse=True)
        recent_feed = events[:10]

        return TeacherOverviewResponse(
            total_students=total_students,
            active_students=active_students_count,
            avg_course_completion=avg_course_completion,
            total_submissions_today=total_submissions_today,
            recent_activity_feed=recent_feed,
        )

    @classmethod
    def get_student_progress_list(
        cls,
        db: Session,
        teacher_id: UUID,
    ) -> list[StudentProgressResponse]:
        """Detailed progress list for each student linked to teacher."""
        students = cls._get_teacher_students(db, teacher_id)
        if not students:
            return []

        now_utc = datetime.now(timezone.utc)
        seven_days_ago = now_utc - timedelta(days=7)
        fourteen_days_ago = now_utc - timedelta(days=14)

        result: list[StudentProgressResponse] = []
        for student in students:
            # 1. Enrolled courses count
            courses_enrolled = (
                db.scalar(
                    select(func.count(CourseEnrollment.id)).where(
                        CourseEnrollment.student_id == student.id
                    )
                )
                or 0
            )

            # 2. Completed lessons count
            lessons_completed = (
                db.scalar(
                    select(func.count(LessonCompletion.id)).where(
                        LessonCompletion.student_id == student.id
                    )
                )
                or 0
            )

            # 3. Current streak
            current_streak = cls._calculate_student_streak(db, student.id)

            # 4. Last active timestamp
            last_comp_time = db.scalar(
                select(func.max(LessonCompletion.completed_at)).where(
                    LessonCompletion.student_id == student.id
                )
            )
            last_sub_time = db.scalar(
                select(func.max(Submission.created_at)).where(
                    Submission.student_id == student.id
                )
            )
            last_act_time = db.scalar(
                select(func.max(StudentLessonActivity.last_accessed_at)).where(
                    StudentLessonActivity.student_id == student.id
                )
            )

            valid_dates = [
                d for d in (last_comp_time, last_sub_time, last_act_time) if d is not None
            ]
            last_active_at = max(valid_dates) if valid_dates else None

            # 5. Overall completion percentage
            enrollments = (
                db.execute(
                    select(CourseEnrollment).where(
                        CourseEnrollment.student_id == student.id
                    )
                )
                .scalars()
                .all()
            )

            if enrollments:
                total_pct = sum(
                    cls._calculate_student_course_completion_pct(
                        db, student.id, e.course_id
                    )
                    for e in enrollments
                )
                overall_completion_pct = round(total_pct / len(enrollments), 1)
            else:
                overall_completion_pct = 0.0

            # 6. Status determination
            if last_active_at and last_active_at >= seven_days_ago:
                user_status = "active"
            elif last_active_at and last_active_at >= fourteen_days_ago:
                user_status = "at_risk"
            else:
                user_status = "inactive"

            full_name = (
                f"{student.first_name or ''} {student.last_name or ''}".strip()
                or student.username
            )

            result.append(
                StudentProgressResponse(
                    student_id=student.id,
                    student_name=full_name,
                    student_username=student.username,
                    student_email=student.email,
                    student_avatar=student.avatar_url,
                    courses_enrolled=courses_enrolled,
                    lessons_completed=lessons_completed,
                    current_streak=current_streak,
                    last_active_at=last_active_at,
                    overall_completion_pct=overall_completion_pct,
                    status=user_status,
                )
            )

        # Sort active first, then highest completion
        result.sort(key=lambda s: (s.status != "active", -s.overall_completion_pct))
        return result

    @classmethod
    def get_bottleneck_lessons(
        cls,
        db: Session,
        teacher_id: UUID,
    ) -> list[BottleneckLessonResponse]:
        """Aggregate lessons across teacher's students and sort by lowest completion rate."""
        students = cls._get_teacher_students(db, teacher_id)
        if not students:
            return []

        student_ids = [s.id for s in students]

        # Get all distinct courses enrolled by teacher's students
        enrolled_course_ids = (
            db.execute(
                select(CourseEnrollment.course_id)
                .where(CourseEnrollment.student_id.in_(student_ids))
                .distinct()
            )
            .scalars()
            .all()
        )

        if not enrolled_course_ids:
            return []

        # Fetch courses with modules and lessons
        courses = (
            db.execute(
                select(Course)
                .where(Course.id.in_(enrolled_course_ids))
                .options(
                    selectinload(Course.modules).selectinload(CourseModule.lessons)
                )
            )
            .scalars()
            .all()
        )

        bottlenecks: list[BottleneckLessonResponse] = []

        for course in courses:
            # Count how many of this teacher's students are enrolled in this course
            course_enrolled_count = (
                db.scalar(
                    select(func.count(CourseEnrollment.id)).where(
                        CourseEnrollment.course_id == course.id,
                        CourseEnrollment.student_id.in_(student_ids),
                    )
                )
                or 0
            )

            if course_enrolled_count == 0:
                continue

            for module in course.modules:
                for lesson in module.lessons:
                    # Completion count for this lesson among teacher's students
                    completed_count = (
                        db.scalar(
                            select(func.count(LessonCompletion.id)).where(
                                LessonCompletion.lesson_id == lesson.id,
                                LessonCompletion.student_id.in_(student_ids),
                            )
                        )
                        or 0
                    )

                    completion_rate = round(
                        completed_count / course_enrolled_count, 4
                    )

                    # Submissions / attempt metrics for PROBLEM type
                    avg_attempts = 1.0 if completed_count > 0 else 0.0
                    failure_rate = 0.0

                    if lesson.content_type == "PROBLEM":
                        problem = (
                            db.execute(
                                select(Problem).where(Problem.lesson_id == lesson.id)
                            )
                            .scalars()
                            .first()
                        )
                        if problem:
                            subs = (
                                db.execute(
                                    select(Submission).where(
                                        Submission.problem_id == problem.id,
                                        Submission.student_id.in_(student_ids),
                                    )
                                )
                                .scalars()
                                .all()
                            )
                            if subs:
                                submitting_students = {s.student_id for s in subs}
                                avg_attempts = round(
                                    len(subs) / max(1, len(submitting_students)), 1
                                )
                                non_ac_count = sum(
                                    1 for s in subs if s.verdict != "AC"
                                )
                                failure_rate = round(
                                    non_ac_count / len(subs), 4
                                )

                    bottlenecks.append(
                        BottleneckLessonResponse(
                            lesson_id=lesson.id,
                            lesson_slug=lesson.slug,
                            lesson_title=lesson.title,
                            module_title=module.title,
                            course_title=course.title,
                            course_slug=course.slug,
                            content_type=lesson.content_type,
                            total_students_enrolled=course_enrolled_count,
                            completion_count=completed_count,
                            completion_rate=completion_rate,
                            avg_attempts=avg_attempts,
                            failure_rate=failure_rate,
                        )
                    )

        # Sort by completion_rate ascending (lowest completion = biggest bottleneck)
        bottlenecks.sort(key=lambda b: (b.completion_rate, b.completion_count))
        return bottlenecks[:10]

    @classmethod
    def get_concept_performance_matrix(
        cls,
        db: Session,
        teacher_id: UUID,
    ) -> list[ConceptPerformanceResponse]:
        """Aggregate module-level concept mastery across all courses."""
        students = cls._get_teacher_students(db, teacher_id)
        if not students:
            return []

        student_ids = [s.id for s in students]

        enrolled_course_ids = (
            db.execute(
                select(CourseEnrollment.course_id)
                .where(CourseEnrollment.student_id.in_(student_ids))
                .distinct()
            )
            .scalars()
            .all()
        )

        if not enrolled_course_ids:
            return []

        courses = (
            db.execute(
                select(Course)
                .where(Course.id.in_(enrolled_course_ids))
                .options(
                    selectinload(Course.modules).selectinload(CourseModule.lessons)
                )
            )
            .scalars()
            .all()
        )

        matrix: list[ConceptPerformanceResponse] = []

        for course in courses:
            course_enrolled_count = (
                db.scalar(
                    select(func.count(CourseEnrollment.id)).where(
                        CourseEnrollment.course_id == course.id,
                        CourseEnrollment.student_id.in_(student_ids),
                    )
                )
                or 0
            )
            if course_enrolled_count == 0:
                continue

            for module in course.modules:
                if not module.lessons:
                    continue

                lesson_rates: list[float] = []
                weak_count = 0

                for lesson in module.lessons:
                    comp_count = (
                        db.scalar(
                            select(func.count(LessonCompletion.id)).where(
                                LessonCompletion.lesson_id == lesson.id,
                                LessonCompletion.student_id.in_(student_ids),
                            )
                        )
                        or 0
                    )
                    rate = comp_count / course_enrolled_count
                    lesson_rates.append(rate)
                    if rate < 0.50:
                        weak_count += 1

                avg_rate = (
                    round(sum(lesson_rates) / len(lesson_rates), 4)
                    if lesson_rates
                    else 0.0
                )

                if avg_rate >= 0.80:
                    status_str = "strong"
                elif avg_rate >= 0.50:
                    status_str = "moderate"
                else:
                    status_str = "weak"

                matrix.append(
                    ConceptPerformanceResponse(
                        module_id=module.id,
                        module_title=module.title,
                        course_title=course.title,
                        course_slug=course.slug,
                        total_lessons=len(module.lessons),
                        avg_completion_rate=avg_rate,
                        weak_lesson_count=weak_count,
                        status=status_str,
                    )
                )

        return matrix

    @classmethod
    @classmethod
    def create_assignments(
        cls,
        db: Session,
        teacher_id: UUID,
        student_ids: list[UUID],
        lesson_id: UUID | None = None,
        custom_problem_id: UUID | None = None,
        quiz_id: UUID | None = None,
        due_date: datetime | None = None,
        notes: str | None = None,
    ) -> list[AssignmentResponse]:
        """Create homework assignment(s) for students assigned to this teacher."""
        teacher = db.execute(select(User).where(User.id == teacher_id)).scalars().first()
        if not teacher:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Teacher not found.",
            )

        if not lesson_id and not custom_problem_id and not quiz_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Must provide at least one of lesson_id, custom_problem_id, or quiz_id.",
            )

        assignment_type = "LESSON"
        title = ""
        course_title = ""
        course_slug = ""
        lesson_slug = None
        lesson_title = None

        if lesson_id:
            lesson = (
                db.execute(
                    select(Lesson)
                    .where(Lesson.id == lesson_id)
                    .options(selectinload(Lesson.module).selectinload(CourseModule.course))
                )
                .scalars()
                .first()
            )
            if not lesson:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Lesson not found.",
                )
            assignment_type = "LESSON"
            lesson_slug = lesson.slug
            lesson_title = lesson.title
            title = lesson.title
            course_title = lesson.module.course.title if lesson.module and lesson.module.course else "DSA Course"
            course_slug = lesson.module.course.slug if lesson.module and lesson.module.course else "arrays"

        elif custom_problem_id:
            custom_problem = db.scalar(select(CustomProblem).where(CustomProblem.id == custom_problem_id))
            if not custom_problem:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Custom problem not found.",
                )
            assignment_type = "CUSTOM_PROBLEM"
            title = custom_problem.title
            course_title = "Educator Studio"
            course_slug = "custom-problems"

        elif quiz_id:
            quiz = db.scalar(select(Quiz).where(Quiz.id == quiz_id))
            if not quiz:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Quiz not found.",
                )
            assignment_type = "QUIZ"
            title = quiz.title
            course_title = "Live Quiz"
            course_slug = "quizzes"

        # Verify students belong to this teacher
        teacher_student_ids = {s.id for s in cls._get_teacher_students(db, teacher_id)}
        invalid_ids = [sid for sid in student_ids if sid not in teacher_student_ids]
        if invalid_ids:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="One or more students are not assigned to your classroom.",
            )

        teacher_name = (
            f"{teacher.first_name or ''} {teacher.last_name or ''}".strip()
            or teacher.username
        )

        created_responses: list[AssignmentResponse] = []

        for sid in student_ids:
            student = db.execute(select(User).where(User.id == sid)).scalars().first()
            if not student:
                continue

            # Check if student already completed this lesson if LESSON type
            already_completed = False
            if lesson_id:
                already_completed = (
                    db.scalar(
                        select(func.count(LessonCompletion.id)).where(
                            LessonCompletion.student_id == sid,
                            LessonCompletion.lesson_id == lesson_id,
                        )
                    )
                    or 0
                ) > 0

            initial_status = "completed" if already_completed else "pending"
            completed_time = datetime.now(timezone.utc) if already_completed else None

            assignment = Assignment(
                teacher_id=teacher_id,
                student_id=sid,
                lesson_id=lesson_id,
                custom_problem_id=custom_problem_id,
                quiz_id=quiz_id,
                assigned_at=datetime.now(timezone.utc),
                due_date=due_date,
                status=initial_status,
                notes=notes,
                completed_at=completed_time,
            )
            db.add(assignment)
            db.commit()
            db.refresh(assignment)

            # Send dynamic notification to student
            try:
                NotificationService.create_notification(
                    db=db,
                    user_id=sid,
                    title="New Homework Assigned",
                    message=f"Solve: {title}",
                    type="HOMEWORK",
                )
            except Exception as e:
                pass

            student_name = (
                f"{student.first_name or ''} {student.last_name or ''}".strip()
                or student.username
            )


            created_responses.append(
                AssignmentResponse(
                    id=assignment.id,
                    teacher_id=teacher_id,
                    teacher_name=teacher_name,
                    student_id=sid,
                    student_name=student_name,
                    assignment_type=assignment_type,
                    lesson_id=lesson_id,
                    lesson_slug=lesson_slug,
                    lesson_title=lesson_title,
                    course_title=course_title,
                    course_slug=course_slug,
                    custom_problem_id=custom_problem_id,
                    quiz_id=quiz_id,
                    title=title,
                    assigned_at=assignment.assigned_at,
                    due_date=assignment.due_date,
                    status=assignment.status,
                    notes=assignment.notes,
                    completed_at=assignment.completed_at,
                )
            )

        # Award HOMEWORK_ASSIGNED badge to teacher
        try:
            BadgeService.award_badge_if_eligible(db, teacher_id, "HOMEWORK_ASSIGNED")
        except Exception as e:
            pass

        return created_responses

    @classmethod
    def get_teacher_assignments(
        cls,
        db: Session,
        teacher_id: UUID,
    ) -> list[AssignmentResponse]:
        """Fetch all homework assignments created by this teacher."""
        assignments = (
            db.execute(
                select(Assignment)
                .where(Assignment.teacher_id == teacher_id)
                .options(
                    selectinload(Assignment.student),
                    selectinload(Assignment.teacher),
                    selectinload(Assignment.lesson)
                    .selectinload(Lesson.module)
                    .selectinload(CourseModule.course),
                    selectinload(Assignment.custom_problem),
                    selectinload(Assignment.quiz),
                )
                .order_by(desc(Assignment.assigned_at))
            )
            .scalars()
            .all()
        )

        now_utc = datetime.now(timezone.utc)
        result: list[AssignmentResponse] = []

        for a in assignments:
            # Auto-check overdue status
            curr_status = a.status
            if curr_status == "pending" and a.due_date and a.due_date < now_utc:
                curr_status = "overdue"
                a.status = "overdue"
                db.commit()

            t_name = (
                f"{a.teacher.first_name or ''} {a.teacher.last_name or ''}".strip()
                or a.teacher.username
                if a.teacher
                else "Teacher"
            )
            s_name = (
                f"{a.student.first_name or ''} {a.student.last_name or ''}".strip()
                or a.student.username
                if a.student
                else "Student"
            )

            assignment_type = "LESSON"
            l_slug = a.lesson.slug if a.lesson else None
            l_title = a.lesson.title if a.lesson else None
            c_title = (
                a.lesson.module.course.title
                if a.lesson and a.lesson.module and a.lesson.module.course
                else "DSA Course"
            )
            c_slug = (
                a.lesson.module.course.slug
                if a.lesson and a.lesson.module and a.lesson.module.course
                else "arrays"
            )
            title = l_title or ""

            if a.custom_problem_id and a.custom_problem:
                assignment_type = "CUSTOM_PROBLEM"
                title = a.custom_problem.title
                c_title = "Educator Studio"
                c_slug = "custom-problems"
            elif a.quiz_id and a.quiz:
                assignment_type = "QUIZ"
                title = a.quiz.title
                c_title = "Live Quiz"
                c_slug = "quizzes"

            result.append(
                AssignmentResponse(
                    id=a.id,
                    teacher_id=a.teacher_id,
                    teacher_name=t_name,
                    student_id=a.student_id,
                    student_name=s_name,
                    assignment_type=assignment_type,
                    lesson_id=a.lesson_id,
                    lesson_slug=l_slug,
                    lesson_title=l_title,
                    course_title=c_title,
                    course_slug=c_slug,
                    custom_problem_id=a.custom_problem_id,
                    quiz_id=a.quiz_id,
                    title=title,
                    assigned_at=a.assigned_at,
                    due_date=a.due_date,
                    status=curr_status,
                    notes=a.notes,
                    completed_at=a.completed_at,
                )
            )

        return result

    @classmethod
    def get_student_assignments(
        cls,
        db: Session,
        student_id: UUID,
    ) -> list[AssignmentResponse]:
        """Fetch all homework assignments received by this student."""
        assignments = (
            db.execute(
                select(Assignment)
                .where(Assignment.student_id == student_id)
                .options(
                    selectinload(Assignment.student),
                    selectinload(Assignment.teacher),
                    selectinload(Assignment.lesson)
                    .selectinload(Lesson.module)
                    .selectinload(CourseModule.course),
                    selectinload(Assignment.custom_problem),
                    selectinload(Assignment.quiz),
                )
                .order_by(desc(Assignment.assigned_at))
            )
            .scalars()
            .all()
        )

        now_utc = datetime.now(timezone.utc)
        result: list[AssignmentResponse] = []

        for a in assignments:
            curr_status = a.status
            if curr_status == "pending" and a.due_date and a.due_date < now_utc:
                curr_status = "overdue"
                a.status = "overdue"
                db.commit()

            t_name = (
                f"{a.teacher.first_name or ''} {a.teacher.last_name or ''}".strip()
                or a.teacher.username
                if a.teacher
                else "Teacher"
            )
            s_name = (
                f"{a.student.first_name or ''} {a.student.last_name or ''}".strip()
                or a.student.username
                if a.student
                else "Student"
            )

            assignment_type = "LESSON"
            l_slug = a.lesson.slug if a.lesson else None
            l_title = a.lesson.title if a.lesson else None
            c_title = (
                a.lesson.module.course.title
                if a.lesson and a.lesson.module and a.lesson.module.course
                else "DSA Course"
            )
            c_slug = (
                a.lesson.module.course.slug
                if a.lesson and a.lesson.module and a.lesson.module.course
                else "arrays"
            )
            title = l_title or ""

            if a.custom_problem_id and a.custom_problem:
                assignment_type = "CUSTOM_PROBLEM"
                title = a.custom_problem.title
                c_title = "Educator Studio"
                c_slug = "custom-problems"
            elif a.quiz_id and a.quiz:
                assignment_type = "QUIZ"
                title = a.quiz.title
                c_title = "Live Quiz"
                c_slug = "quizzes"

            result.append(
                AssignmentResponse(
                    id=a.id,
                    teacher_id=a.teacher_id,
                    teacher_name=t_name,
                    student_id=a.student_id,
                    student_name=s_name,
                    assignment_type=assignment_type,
                    lesson_id=a.lesson_id,
                    lesson_slug=l_slug,
                    lesson_title=l_title,
                    course_title=c_title,
                    course_slug=c_slug,
                    custom_problem_id=a.custom_problem_id,
                    quiz_id=a.quiz_id,
                    title=title,
                    assigned_at=a.assigned_at,
                    due_date=a.due_date,
                    status=curr_status,
                    notes=a.notes,
                    completed_at=a.completed_at,
                )
            )

        return result
