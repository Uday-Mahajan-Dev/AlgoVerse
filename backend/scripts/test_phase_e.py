import os
import sys
import uuid

# Add parent directory to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from sqlalchemy import select
from app.db.session import SessionLocal
from app.models.user import User
from app.models.role import Role
from app.models.course import Course
from app.models.course_module import CourseModule
from app.models.lesson import Lesson
from app.models.course_enrollment import CourseEnrollment
from app.models.lesson_completion import LessonCompletion
from app.services.course_service import CourseService
from app.services.dashboard_service import DashboardService


def test_phase_e():
    db = SessionLocal()
    try:
        # Find or create student user
        student = db.execute(select(User)).scalars().first()
        if not student:
            student_role = db.execute(select(Role).where(Role.name == "STUDENT")).scalars().first()
            if not student_role:
                student_role = Role(name="STUDENT", description="Student Role")
                db.add(student_role)
                db.commit()
                db.refresh(student_role)
            student = User(
                username=f"student_{uuid.uuid4().hex[:6]}",
                email=f"teststudent_{uuid.uuid4().hex[:6]}@algoverse.dev",
                hashed_password="hashed_test_password",
                first_name="Test",
                last_name="Student",
                role_id=student_role.id,
                is_active=True,
                email_verified=True,
            )
            db.add(student)
            db.commit()
            db.refresh(student)

        print(f"Testing with student: {student.email} ({student.id})")

        # 1. Enroll student in arrays course
        arrays_course = db.execute(select(Course).where(Course.slug == "arrays")).scalars().first()
        assert arrays_course is not None, "Arrays course not found in DB!"
        
        CourseService.enroll_in_course(db, student.id, "arrays")
        print(f"Enrolled in course: {arrays_course.title}")

        # 2. Test get_student_metrics
        metrics = DashboardService.get_student_metrics(db, student.id)
        print("Student Metrics:")
        print(f"  Total Courses Enrolled: {metrics.total_courses_enrolled}")
        print(f"  Total Lessons Completed: {metrics.total_lessons_completed}")
        print(f"  Total Visualizations: {metrics.total_visualizations_completed}")
        print(f"  Total Problems: {metrics.total_problems_solved}")
        print(f"  Current Streak: {metrics.current_streak}")

        # 3. Test get_continue_learning (Priority 2 check)
        cl_res = DashboardService.get_continue_learning(db, student.id)
        assert cl_res is not None, "Expected ContinueLearningResponse for enrolled student!"
        print("Continue Learning (Before Access):")
        print(f"  Lesson: {cl_res.lesson_title} ({cl_res.lesson_slug})")
        print(f"  Module: {cl_res.module_title}")
        print(f"  Course: {cl_res.course_title} ({cl_res.course_completion_pct}%)")

        # 4. Record access on a specific incomplete lesson (e.g. 5th lesson)
        target_lesson = db.execute(
            select(Lesson)
            .join(CourseModule, Lesson.module_id == CourseModule.id)
            .where(CourseModule.course_id == arrays_course.id)
            .order_by(CourseModule.order_index.asc(), Lesson.order_index.asc())
            .offset(3)
            .limit(1)
        ).scalars().first()

        assert target_lesson is not None, "Expected target lesson in arrays course!"
        access_res = CourseService.record_lesson_access(db, student.id, target_lesson.id)
        print(f"Recorded Access on: {target_lesson.title} at {access_res.last_accessed_at}")

        # 5. Test get_continue_learning (Priority 1 check)
        cl_res2 = DashboardService.get_continue_learning(db, student.id)
        assert cl_res2 is not None, "Expected ContinueLearningResponse after access!"
        print("Continue Learning (After Access - Priority 1):")
        print(f"  Lesson: {cl_res2.lesson_title} ({cl_res2.lesson_slug})")
        print(f"  Course: {cl_res2.course_title} ({cl_res2.course_completion_pct}%)")
        assert cl_res2.lesson_id == target_lesson.id, "Priority 1 failed to resolve most recently accessed incomplete lesson!"
        print(">>> Priority 1 assertion PASSED!")

        # 6. Complete a lesson and test metrics updates
        CourseService.complete_lesson(db, student.id, target_lesson.id)
        metrics_after = DashboardService.get_student_metrics(db, student.id)
        print("Student Metrics (After Lesson Completion):")
        print(f"  Total Lessons Completed: {metrics_after.total_lessons_completed}")
        print(f"  Current Streak: {metrics_after.current_streak}")
        assert metrics_after.total_lessons_completed >= 1, "Lesson completion count did not increase!"
        assert metrics_after.current_streak >= 1, "Streak calculation failed to register today's completion!"
        print(">>> Metrics & Streak assertion PASSED!")

        print("\nAll Phase E backend service tests PASSED successfully!")
    finally:
        db.close()


if __name__ == "__main__":
    test_phase_e()
