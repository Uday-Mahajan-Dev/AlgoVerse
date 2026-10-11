from datetime import datetime, timezone
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import desc, func, select
from sqlalchemy.orm import Session, joinedload, selectinload

from app.models.course import Course
from app.models.course_enrollment import CourseEnrollment
from app.models.course_module import CourseModule
from app.models.lesson import Lesson
from app.models.lesson_completion import LessonCompletion
from app.models.student_lesson_activity import StudentLessonActivity
from app.schemas.courses import (
    CourseDetailResponse,
    CourseListResponse,
    CourseProgressResponse,
    EnrollmentResponse,
    LessonCompletionResponse,
    LessonResponse,
    LessonSnippetUpdateRequest,
    ModuleResponse,
)
from app.schemas.dashboard import LessonAccessResponse


class CourseService:
    @staticmethod
    def get_published_courses(
        db: Session,
        user_id: UUID | None = None,
    ) -> list[CourseListResponse]:
        """Fetch all published courses with module/lesson counts and user enrollment status."""
        courses = (
            db.execute(
                select(Course)
                .where(Course.is_published.is_(True))
                .options(
                    selectinload(Course.modules).selectinload(CourseModule.lessons),
                    selectinload(Course.enrollments),
                )
                .order_by(Course.created_at.asc())
            )
            .scalars()
            .all()
        )

        user_enrolled_course_ids: set[UUID] = set()
        if user_id:
            enrollments = (
                db.execute(
                    select(CourseEnrollment.course_id).where(
                        CourseEnrollment.student_id == user_id
                    )
                )
                .scalars()
                .all()
            )
            user_enrolled_course_ids = set(enrollments)

        result: list[CourseListResponse] = []
        for course in courses:
            total_lessons = sum(len(module.lessons) for module in course.modules)
            result.append(
                CourseListResponse(
                    id=course.id,
                    title=course.title,
                    slug=course.slug,
                    description=course.description,
                    thumbnail_url=course.thumbnail_url,
                    difficulty=course.difficulty,
                    topic_category=course.topic_category,
                    module_count=len(course.modules),
                    total_lessons=total_lessons,
                    enrollment_count=len(course.enrollments),
                    is_enrolled=course.id in user_enrolled_course_ids,
                )
            )

        return result

    @staticmethod
    def _get_course_by_identifier(
        db: Session,
        identifier: str,
        load_details: bool = False,
    ) -> Course | None:
        """Find course by UUID string or slug."""
        stmt = select(Course)
        if load_details:
            stmt = stmt.options(
                selectinload(Course.modules).selectinload(CourseModule.lessons),
                selectinload(Course.enrollments),
            )
        try:
            val = UUID(identifier)
            course = db.execute(stmt.where(Course.id == val)).scalars().first()
            if course:
                return course
        except (ValueError, AttributeError):
            pass

        return db.execute(stmt.where(Course.slug == identifier)).scalars().first()

    @staticmethod
    def get_course_detail(
        db: Session,
        course_slug: str,
        user_id: UUID | None = None,
    ) -> CourseDetailResponse:
        """Fetch a specific course by slug or ID with explicitly ordered modules and lessons."""
        course = CourseService._get_course_by_identifier(
            db=db,
            identifier=course_slug,
            load_details=True,
        )

        if not course:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Course with identifier '{course_slug}' not found.",
            )

        # Check user enrollment
        is_enrolled = False
        enrolled_at: datetime | None = None
        completed_lesson_ids: set[UUID] = set()

        if user_id:
            enrollment = (
                db.execute(
                    select(CourseEnrollment).where(
                        CourseEnrollment.student_id == user_id,
                        CourseEnrollment.course_id == course.id,
                    )
                )
                .scalars()
                .first()
            )
            if enrollment:
                is_enrolled = True
                enrolled_at = enrollment.enrolled_at

                # Get all completed lesson IDs for this student in this course
                all_lesson_ids = [
                    lesson.id
                    for module in course.modules
                    for lesson in module.lessons
                ]
                if all_lesson_ids:
                    completions = (
                        db.execute(
                            select(LessonCompletion.lesson_id).where(
                                LessonCompletion.student_id == user_id,
                                LessonCompletion.lesson_id.in_(all_lesson_ids),
                            )
                        )
                        .scalars()
                        .all()
                    )
                    completed_lesson_ids = set(completions)

        # Explicitly order modules by order_index and lessons by order_index (Adjustment 1)
        sorted_modules = sorted(course.modules, key=lambda m: m.order_index)
        module_responses: list[ModuleResponse] = []
        total_lessons_count = 0
        completed_lessons_count = 0

        for module in sorted_modules:
            sorted_lessons = sorted(module.lessons, key=lambda l: l.order_index)
            lesson_responses: list[LessonResponse] = []

            for lesson in sorted_lessons:
                total_lessons_count += 1
                is_completed = lesson.id in completed_lesson_ids
                if is_completed:
                    completed_lessons_count += 1

                content_payload = (
                    CourseService.normalize_visualization_content(lesson.content_json)
                    if lesson.content_type == "VISUALIZATION"
                    else (lesson.content_json or {})
                )
                lesson_responses.append(
                    LessonResponse(
                        id=lesson.id,
                        title=lesson.title,
                        slug=lesson.slug,
                        content_type=lesson.content_type,
                        content_json=content_payload,
                        order_index=lesson.order_index,
                        estimated_minutes=lesson.estimated_minutes,
                        is_completed=is_completed,
                    )
                )

            module_responses.append(
                ModuleResponse(
                    id=module.id,
                    title=module.title,
                    order_index=module.order_index,
                    lessons=lesson_responses,
                )
            )

        completion_percentage = (
            round((completed_lessons_count / total_lessons_count) * 100.0, 1)
            if total_lessons_count > 0
            else 0.0
        )

        return CourseDetailResponse(
            id=course.id,
            title=course.title,
            slug=course.slug,
            description=course.description,
            thumbnail_url=course.thumbnail_url,
            difficulty=course.difficulty,
            topic_category=course.topic_category,
            is_published=course.is_published,
            module_count=len(course.modules),
            total_lessons=total_lessons_count,
            completed_lessons=completed_lessons_count,
            completion_percentage=completion_percentage,
            enrollment_count=len(course.enrollments),
            is_enrolled=is_enrolled,
            enrolled_at=enrolled_at,
            modules=module_responses,
            created_at=course.created_at,
        )

    @staticmethod
    def enroll_in_course(
        db: Session,
        student_id: UUID,
        course_slug: str,
    ) -> EnrollmentResponse:
        """Enroll a student in a course (idempotent). Supports slug or ID."""
        course = CourseService._get_course_by_identifier(db, course_slug)

        if not course:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Course with identifier '{course_slug}' not found.",
            )

        if not course.is_published:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot enroll in an unpublished course.",
            )

        existing = (
            db.execute(
                select(CourseEnrollment).where(
                    CourseEnrollment.student_id == student_id,
                    CourseEnrollment.course_id == course.id,
                )
            )
            .scalars()
            .first()
        )

        if existing:
            return EnrollmentResponse(
                course_id=course.id,
                enrolled_at=existing.enrolled_at,
                message="Already enrolled in this course",
            )

        new_enrollment = CourseEnrollment(
            student_id=student_id,
            course_id=course.id,
            enrolled_at=datetime.now(timezone.utc),
        )
        db.add(new_enrollment)
        db.commit()
        db.refresh(new_enrollment)

        from app.services.badge_service import BadgeService
        BadgeService.award_badge_if_eligible(db, student_id, "FIRST_ENROLLMENT")

        return EnrollmentResponse(
            course_id=course.id,
            enrolled_at=new_enrollment.enrolled_at,
            message="Enrolled successfully",
        )

    @staticmethod
    def drop_course(
        db: Session,
        student_id: UUID,
        course_identifier: str,
    ) -> dict[str, str]:
        """Drop / un-enroll from a course."""
        course = CourseService._get_course_by_identifier(db, course_identifier)

        if not course:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Course with identifier '{course_identifier}' not found.",
            )

        enrollment = db.scalar(
            select(CourseEnrollment).where(
                CourseEnrollment.student_id == student_id,
                CourseEnrollment.course_id == course.id,
            )
        )

        if not enrollment:
            return {
                "course_id": str(course.id),
                "message": "Not enrolled in this course",
            }

        db.delete(enrollment)
        db.commit()
        return {
            "course_id": str(course.id),
            "message": "Successfully dropped course",
        }

    @staticmethod
    def get_student_progress(
        db: Session,
        student_id: UUID,
        course_slug: str,
    ) -> CourseProgressResponse:
        """Get learning progress for a specific course for a student. Supports slug or ID."""
        course = CourseService._get_course_by_identifier(
            db=db,
            identifier=course_slug,
            load_details=True,
        )

        if not course:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Course with identifier '{course_slug}' not found.",
            )

        all_lesson_ids = [
            lesson.id
            for module in course.modules
            for lesson in module.lessons
        ]
        total_lessons = len(all_lesson_ids)

        if total_lessons == 0:
            return CourseProgressResponse(
                course_id=course.id,
                course_title=course.title,
                course_slug=course.slug,
                total_lessons=0,
                completed_lessons=0,
                completion_percentage=0.0,
                progress_percentage=0.0,
                completed_lesson_ids=[],
                last_completed_at=None,
            )

        completions = (
            db.execute(
                select(LessonCompletion)
                .where(
                    LessonCompletion.student_id == student_id,
                    LessonCompletion.lesson_id.in_(all_lesson_ids),
                )
                .order_by(desc(LessonCompletion.completed_at))
            )
            .scalars()
            .all()
        )

        completed_count = len(completions)
        completed_ids = [c.lesson_id for c in completions]
        last_completed_at = completions[0].completed_at if completions else None
        completion_percentage = round((completed_count / total_lessons) * 100.0, 1)

        return CourseProgressResponse(
            course_id=course.id,
            course_title=course.title,
            course_slug=course.slug,
            total_lessons=total_lessons,
            completed_lessons=completed_count,
            completion_percentage=completion_percentage,
            progress_percentage=completion_percentage,
            completed_lesson_ids=completed_ids,
            last_completed_at=last_completed_at,
        )

    @staticmethod
    def get_all_student_progress(
        db: Session,
        student_id: UUID,
    ) -> list[CourseProgressResponse]:
        """Get all courses the student is enrolled in with progress details."""
        enrollments = (
            db.execute(
                select(CourseEnrollment)
                .where(CourseEnrollment.student_id == student_id)
                .options(
                    joinedload(CourseEnrollment.course)
                    .selectinload(Course.modules)
                    .selectinload(CourseModule.lessons)
                )
                .order_by(desc(CourseEnrollment.enrolled_at))
            )
            .scalars()
            .all()
        )

        progress_list: list[CourseProgressResponse] = []

        for enrollment in enrollments:
            course = enrollment.course
            if not course:
                continue

            all_lesson_ids = [
                lesson.id
                for module in course.modules
                for lesson in module.lessons
            ]
            total_lessons = len(all_lesson_ids)

            if total_lessons == 0:
                progress_list.append(
                    CourseProgressResponse(
                        course_id=course.id,
                        course_title=course.title,
                        course_slug=course.slug,
                        total_lessons=0,
                        completed_lessons=0,
                        completion_percentage=0.0,
                        progress_percentage=0.0,
                        completed_lesson_ids=[],
                        last_completed_at=None,
                    )
                )
                continue

            completions = (
                db.execute(
                    select(LessonCompletion)
                    .where(
                        LessonCompletion.student_id == student_id,
                        LessonCompletion.lesson_id.in_(all_lesson_ids),
                    )
                    .order_by(desc(LessonCompletion.completed_at))
                )
                .scalars()
                .all()
            )

            completed_count = len(completions)
            completed_ids = [c.lesson_id for c in completions]
            last_completed_at = completions[0].completed_at if completions else None
            completion_percentage = round((completed_count / total_lessons) * 100.0, 1)

            progress_list.append(
                CourseProgressResponse(
                    course_id=course.id,
                    course_title=course.title,
                    course_slug=course.slug,
                    total_lessons=total_lessons,
                    completed_lessons=completed_count,
                    completion_percentage=completion_percentage,
                    progress_percentage=completion_percentage,
                    completed_lesson_ids=completed_ids,
                    last_completed_at=last_completed_at,
                )
            )

        return progress_list

    @staticmethod
    def complete_lesson(
        db: Session,
        student_id: UUID,
        lesson_id: UUID,
    ) -> LessonCompletionResponse:
        """Mark a lesson as completed by student (idempotent)."""
        lesson = (
            db.execute(
                select(Lesson)
                .where(Lesson.id == lesson_id)
                .options(
                    joinedload(Lesson.module).joinedload(CourseModule.course),
                )
            )
            .scalars()
            .first()
        )

        if not lesson:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Lesson with ID '{lesson_id}' not found.",
            )

        course = lesson.module.course if lesson.module else None
        if course:
            # Auto-enroll student if not yet enrolled
            existing_enrollment = (
                db.execute(
                    select(CourseEnrollment).where(
                        CourseEnrollment.student_id == student_id,
                        CourseEnrollment.course_id == course.id,
                    )
                )
                .scalars()
                .first()
            )
            if not existing_enrollment:
                auto_enroll = CourseEnrollment(
                    student_id=student_id,
                    course_id=course.id,
                    enrolled_at=datetime.now(timezone.utc),
                )
                db.add(auto_enroll)
                db.commit()

        # Check existing completion
        existing_completion = (
            db.execute(
                select(LessonCompletion).where(
                    LessonCompletion.student_id == student_id,
                    LessonCompletion.lesson_id == lesson_id,
                )
            )
            .scalars()
            .first()
        )

        if existing_completion:
            return LessonCompletionResponse(
                lesson_id=lesson.id,
                completed_at=existing_completion.completed_at,
                message="Lesson already marked as complete",
            )

        completion = LessonCompletion(
            student_id=student_id,
            lesson_id=lesson.id,
            completed_at=datetime.now(timezone.utc),
        )
        db.add(completion)

        # Also auto-complete any matching pending/overdue assignments for this student and lesson
        from app.models.assignment import Assignment
        matching_assignments = (
            db.execute(
                select(Assignment).where(
                    Assignment.student_id == student_id,
                    Assignment.lesson_id == lesson.id,
                    Assignment.status.in_(["pending", "overdue"]),
                )
            )
            .scalars()
            .all()
        )
        for assign in matching_assignments:
            assign.status = "completed"
            assign.completed_at = completion.completed_at

        db.commit()
        db.refresh(completion)

        from app.services.badge_service import BadgeService

        if lesson.content_type == "VISUALIZATION":
            BadgeService.award_badge_if_eligible(db, student_id, "FIRST_VISUALIZATION")

        if matching_assignments:
            BadgeService.award_badge_if_eligible(db, student_id, "HOMEWORK_COMPLETE")

        # Check module / course completion
        if lesson.module:
            mod_lesson_ids = [l.id for l in lesson.module.lessons]
            mod_completed_count = db.scalar(
                select(func.count(LessonCompletion.id)).where(
                    LessonCompletion.student_id == student_id,
                    LessonCompletion.lesson_id.in_(mod_lesson_ids),
                )
            ) or 0
            if mod_completed_count >= len(mod_lesson_ids) and len(mod_lesson_ids) > 0:
                BadgeService.award_badge_if_eligible(db, student_id, "ARRAYS_MODULE_COMPLETE")

            if lesson.module.course:
                all_course_lesson_ids = []
                for m in lesson.module.course.modules:
                    all_course_lesson_ids.extend([l.id for l in m.lessons])
                course_completed_count = db.scalar(
                    select(func.count(LessonCompletion.id)).where(
                        LessonCompletion.student_id == student_id,
                        LessonCompletion.lesson_id.in_(all_course_lesson_ids),
                    )
                ) or 0
                if course_completed_count >= len(all_course_lesson_ids) and len(all_course_lesson_ids) > 0:
                    BadgeService.award_badge_if_eligible(db, student_id, "ARRAYS_COURSE_COMPLETE")

        return LessonCompletionResponse(
            lesson_id=lesson.id,
            completed_at=completion.completed_at,
            message="Lesson marked as complete",
        )

    @staticmethod
    def record_lesson_access(
        db: Session,
        student_id: UUID,
        lesson_id: UUID,
    ) -> LessonAccessResponse:
        """Record or update student lesson access timestamp (idempotent)."""
        lesson = (
            db.execute(select(Lesson).where(Lesson.id == lesson_id))
            .scalars()
            .first()
        )

        if not lesson:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Lesson with ID '{lesson_id}' not found.",
            )

        activity = (
            db.execute(
                select(StudentLessonActivity).where(
                    StudentLessonActivity.student_id == student_id,
                    StudentLessonActivity.lesson_id == lesson_id,
                )
            )
            .scalars()
            .first()
        )

        now = datetime.now(timezone.utc)
        if activity:
            activity.last_accessed_at = now
        else:
            activity = StudentLessonActivity(
                student_id=student_id,
                lesson_id=lesson_id,
                last_accessed_at=now,
            )
            db.add(activity)

        db.commit()
        db.refresh(activity)

        return LessonAccessResponse(
            lesson_id=lesson_id,
            last_accessed_at=activity.last_accessed_at.isoformat(),
            message="Lesson access recorded",
        )

    @staticmethod
    def normalize_visualization_content(content: dict | None) -> dict:
        """Ensure code_snippets map, default_language, and line_maps exist on visualization content."""
        if not isinstance(content, dict):
            return {}
        res = dict(content)
        code_snippets = res.get("code_snippets")
        if not isinstance(code_snippets, dict):
            single = res.get("code_snippet")
            res["code_snippets"] = {"python": str(single)} if single else {}
        elif res.get("code_snippet") and "python" not in code_snippets:
            res["code_snippets"]["python"] = str(res["code_snippet"])

        if "default_language" not in res:
            res["default_language"] = "python"

        if "line_maps" not in res or not isinstance(res.get("line_maps"), dict):
            single_map = res.get("line_map")
            res["line_maps"] = {"python": single_map} if isinstance(single_map, dict) else {}

        return res

    @staticmethod
    def update_lesson_snippets(
        db: Session,
        lesson_id: UUID,
        payload: LessonSnippetUpdateRequest,
    ) -> LessonResponse:
        """Authoring endpoint: updates multi-language code snippets and line maps on a visualization lesson."""
        lesson = db.scalar(select(Lesson).where(Lesson.id == lesson_id))
        if not lesson:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Lesson {lesson_id} not found",
            )
        current_content = dict(lesson.content_json or {})
        current_content["code_snippets"] = payload.code_snippets
        if payload.line_maps is not None:
            current_content["line_maps"] = payload.line_maps
        current_content["default_language"] = payload.default_language
        if "python" in payload.code_snippets:
            current_content["code_snippet"] = payload.code_snippets["python"]

        lesson.content_json = current_content
        db.commit()
        db.refresh(lesson)
        return LessonResponse(
            id=lesson.id,
            title=lesson.title,
            slug=lesson.slug,
            content_type=lesson.content_type,
            content_json=current_content,
            order_index=lesson.order_index,
            estimated_minutes=lesson.estimated_minutes,
            is_completed=False,
        )

