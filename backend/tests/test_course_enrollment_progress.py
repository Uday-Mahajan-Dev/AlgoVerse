import unittest
from datetime import datetime, timezone
from uuid import uuid4

from sqlalchemy import select

from app.db.session import SessionLocal
from app.models.course import Course
from app.models.course_enrollment import CourseEnrollment
from app.models.course_module import CourseModule
from app.models.lesson import Lesson
from app.models.lesson_completion import LessonCompletion
from app.models.problem import Problem
from app.models.role import Role
from app.models.user import User
from app.services.course_service import CourseService
from app.services.judge_service import JudgeService


class TestCourseEnrollmentProgress(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.db = SessionLocal()

    @classmethod
    def tearDownClass(cls):
        cls.db.close()

    def setUp(self):
        # Create student role if missing
        self.student_role = self.db.scalar(select(Role).where(Role.name == "STUDENT"))
        if not self.student_role:
            self.student_role = Role(name="STUDENT")
            self.db.add(self.student_role)
            self.db.commit()

        # Create unique student with NO mentor
        suffix = uuid4().hex[:6]
        self.student = User(
            id=uuid4(),
            email=f"solo_student_{suffix}@example.com",
            username=f"solostudent_{suffix}",
            hashed_password="hashed_pw_test",
            role_id=self.student_role.id,
            is_active=True,
            first_name="Solo",
            last_name="Learner",
        )
        self.db.add(self.student)
        self.db.commit()
        self.db.refresh(self.student)

        # Create test course with 1 module and 4 lessons
        self.course_slug = f"test-algo-course-{suffix}"
        self.course = Course(
            id=uuid4(),
            title=f"Test Algo Course {suffix}",
            slug=self.course_slug,
            description="Testing enrollment and progress tracking",
            difficulty="BEGINNER",
            topic_category="ALGORITHMS",
            is_published=True,
        )
        self.db.add(self.course)
        self.db.commit()
        self.db.refresh(self.course)

        self.module = CourseModule(
            id=uuid4(),
            course_id=self.course.id,
            title="Module 1: Foundations",
            order_index=1,
        )
        self.db.add(self.module)
        self.db.commit()
        self.db.refresh(self.module)

        self.lessons = []
        for i in range(1, 5):
            content_type = "PROBLEM" if i == 4 else "CONCEPT"
            lesson = Lesson(
                id=uuid4(),
                module_id=self.module.id,
                title=f"Lesson {i}",
                slug=f"lesson-{i}-{suffix}",
                content_type=content_type,
                content_json={"text": f"Content for lesson {i}"},
                order_index=i,
                estimated_minutes=10,
            )
            self.db.add(lesson)
            self.lessons.append(lesson)
        self.db.commit()
        for lesson in self.lessons:
            self.db.refresh(lesson)

    def tearDown(self):
        # Clean up records created in this test
        self.db.query(LessonCompletion).filter(
            LessonCompletion.student_id == self.student.id
        ).delete()
        self.db.query(CourseEnrollment).filter(
            CourseEnrollment.student_id == self.student.id
        ).delete()
        for lesson in self.lessons:
            self.db.query(Problem).filter(Problem.lesson_id == lesson.id).delete()
            self.db.query(Lesson).filter(Lesson.id == lesson.id).delete()
        self.db.query(CourseModule).filter(CourseModule.id == self.module.id).delete()
        self.db.query(Course).filter(Course.id == self.course.id).delete()
        self.db.query(User).filter(User.id == self.student.id).delete()
        self.db.commit()

    def test_independent_course_enrollment_and_drop(self):
        """Verify student can enroll and drop courses independently of any mentor/teacher."""
        # 1. Enroll by slug
        res = CourseService.enroll_in_course(
            db=self.db,
            student_id=self.student.id,
            course_slug=self.course_slug,
        )
        self.assertEqual(res.course_id, self.course.id)
        self.assertEqual(res.message, "Enrolled successfully")

        # Verify record in DB
        enrollment = self.db.scalar(
            select(CourseEnrollment).where(
                CourseEnrollment.student_id == self.student.id,
                CourseEnrollment.course_id == self.course.id,
            )
        )
        self.assertIsNotNone(enrollment)

        # 2. Idempotent enrollment
        res_repeat = CourseService.enroll_in_course(
            db=self.db,
            student_id=self.student.id,
            course_slug=self.course_slug,
        )
        self.assertEqual(res_repeat.message, "Already enrolled in this course")

        # 3. Drop course by UUID string
        drop_res = CourseService.drop_course(
            db=self.db,
            student_id=self.student.id,
            course_identifier=str(self.course.id),
        )
        self.assertEqual(drop_res["message"], "Successfully dropped course")

        # Verify record removed
        enrollment_after = self.db.scalar(
            select(CourseEnrollment).where(
                CourseEnrollment.student_id == self.student.id,
                CourseEnrollment.course_id == self.course.id,
            )
        )
        self.assertIsNone(enrollment_after)

    def test_lesson_completion_and_dynamic_progress(self):
        """Verify lesson completion is idempotent and progress calculations update dynamically."""
        # Enroll first
        CourseService.enroll_in_course(
            db=self.db,
            student_id=self.student.id,
            course_slug=self.course_slug,
        )

        # 0 completed lessons initially
        progress_0 = CourseService.get_student_progress(
            db=self.db,
            student_id=self.student.id,
            course_slug=self.course_slug,
        )
        self.assertEqual(progress_0.total_lessons, 4)
        self.assertEqual(progress_0.completed_lessons, 0)
        self.assertEqual(progress_0.progress_percentage, 0.0)
        self.assertEqual(len(progress_0.completed_lesson_ids), 0)

        # Complete lesson 1
        comp_1 = CourseService.complete_lesson(
            db=self.db,
            student_id=self.student.id,
            lesson_id=self.lessons[0].id,
        )
        self.assertEqual(comp_1.lesson_id, self.lessons[0].id)
        self.assertEqual(comp_1.message, "Lesson marked as complete")

        # Verify idempotency
        comp_1_repeat = CourseService.complete_lesson(
            db=self.db,
            student_id=self.student.id,
            lesson_id=self.lessons[0].id,
        )
        self.assertEqual(comp_1_repeat.message, "Lesson already marked as complete")

        # Check progress -> 1 / 4 = 25.0%
        progress_1 = CourseService.get_student_progress(
            db=self.db,
            student_id=self.student.id,
            course_slug=str(self.course.id),  # Test resolution by UUID string
        )
        self.assertEqual(progress_1.completed_lessons, 1)
        self.assertEqual(progress_1.progress_percentage, 25.0)
        self.assertIn(self.lessons[0].id, progress_1.completed_lesson_ids)

        # Complete lesson 2 -> 2 / 4 = 50.0%
        CourseService.complete_lesson(
            db=self.db,
            student_id=self.student.id,
            lesson_id=self.lessons[1].id,
        )
        progress_2 = CourseService.get_student_progress(
            db=self.db,
            student_id=self.student.id,
            course_slug=self.course_slug,
        )
        self.assertEqual(progress_2.completed_lessons, 2)
        self.assertEqual(progress_2.progress_percentage, 50.0)
        self.assertIn(self.lessons[0].id, progress_2.completed_lesson_ids)
        self.assertIn(self.lessons[1].id, progress_2.completed_lesson_ids)

    def test_auto_completion_on_problem_ac(self):
        """Verify that solving a problem linked to a lesson auto-completes the lesson."""
        problem_lesson = self.lessons[3]
        problem = Problem(
            id=uuid4(),
            lesson_id=problem_lesson.id,
            title="Sum Problem",
            description="Add two numbers",
            function_name="solve",
            starter_code_python="def solve():\n    pass\n",
            starter_code_java="class Solution { public static void solve() {} }",
            starter_code_cpp="void solve() {}",
            solution_code_python="def solve():\n    return 3\n",
            solution_code_java="class Solution { public static void solve() {} }",
            solution_code_cpp="void solve() {}",
        )
        self.db.add(problem)
        self.db.commit()
        self.db.refresh(problem)

        # Direct call simulating AC in judge workflow
        CourseService.complete_lesson(
            db=self.db,
            student_id=self.student.id,
            lesson_id=problem.lesson_id,
        )

        progress = CourseService.get_student_progress(
            db=self.db,
            student_id=self.student.id,
            course_slug=self.course_slug,
        )
        self.assertIn(problem_lesson.id, progress.completed_lesson_ids)
        self.assertEqual(progress.completed_lessons, 1)
        self.assertEqual(progress.progress_percentage, 25.0)


if __name__ == "__main__":
    unittest.main()
