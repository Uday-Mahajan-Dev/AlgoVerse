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
    def get_course_detail(
        db: Session,
        course_slug: str,
        user_id: UUID | None = None,
    ) -> CourseDetailResponse:
        """Fetch a specific course by slug with explicitly ordered modules and lessons."""
        course = (
            db.execute(
                select(Course)
                .where(Course.slug == course_slug)
                .options(
                    selectinload(Course.modules).selectinload(CourseModule.lessons),
                    selectinload(Course.enrollments),
                )
            )
            .scalars()
            .first()
        )

        if not course:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Course with slug '{course_slug}' not found.",
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

                lesson_responses.append(
                    LessonResponse(
                        id=lesson.id,
                        title=lesson.title,
                        slug=lesson.slug,
                        content_type=lesson.content_type,
                        content_json=lesson.content_json or {},
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
        """Enroll a student in a course (idempotent)."""
        course = (
            db.execute(select(Course).where(Course.slug == course_slug))
            .scalars()
            .first()
        )

        if not course:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Course with slug '{course_slug}' not found.",
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

        return EnrollmentResponse(
            course_id=course.id,
            enrolled_at=new_enrollment.enrolled_at,
            message="Enrolled successfully",
        )

    @staticmethod
    def get_student_progress(
        db: Session,
        student_id: UUID,
        course_slug: str,
    ) -> CourseProgressResponse:
        """Get learning progress for a specific course for a student."""
        course = (
            db.execute(
                select(Course)
                .where(Course.slug == course_slug)
                .options(
                    selectinload(Course.modules).selectinload(CourseModule.lessons),
                )
            )
            .scalars()
            .first()
        )

        if not course:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Course with slug '{course_slug}' not found.",
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
        last_completed_at = completions[0].completed_at if completions else None
        completion_percentage = round((completed_count / total_lessons) * 100.0, 1)

        return CourseProgressResponse(
            course_id=course.id,
            course_title=course.title,
            course_slug=course.slug,
            total_lessons=total_lessons,
            completed_lessons=completed_count,
            completion_percentage=completion_percentage,
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
        db.commit()
        db.refresh(completion)

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

