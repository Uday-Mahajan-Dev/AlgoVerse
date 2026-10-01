import unittest
from datetime import datetime, timezone
from uuid import uuid4

from app.db.session import SessionLocal
from app.models.assignment import Assignment
from app.models.course import Course
from app.models.lesson import Lesson
from app.models.role import Role
from app.models.student_teacher import StudentTeacher
from app.models.user import User
from app.services.teacher_analytics_service import TeacherAnalyticsService
from sqlalchemy import select


class TestTeacherAnalytics(unittest.TestCase):
    def setUp(self):
        self.db = SessionLocal()

    def tearDown(self):
        self.db.close()

    def test_analytics_service_methods(self):
        # Find a teacher user
        teacher = (
            self.db.execute(
                select(User)
                .join(Role, Role.id == User.role_id)
                .where(Role.name == "TEACHER")
            )
            .scalars()
            .first()
        )
        if not teacher:
            self.skipTest("No teacher user found in database.")

        overview = TeacherAnalyticsService.get_teacher_overview(
            db=self.db,
            teacher_id=teacher.id,
        )
        self.assertIsNotNone(overview)
        self.assertIsInstance(overview.total_students, int)
        self.assertIsInstance(overview.active_students, int)
        self.assertIsInstance(overview.avg_course_completion, float)
        self.assertIsInstance(overview.recent_activity_feed, list)

        students = TeacherAnalyticsService.get_student_progress_list(
            db=self.db,
            teacher_id=teacher.id,
        )
        self.assertIsInstance(students, list)

        bottlenecks = TeacherAnalyticsService.get_bottleneck_lessons(
            db=self.db,
            teacher_id=teacher.id,
        )
        self.assertIsInstance(bottlenecks, list)

        concepts = TeacherAnalyticsService.get_concept_performance_matrix(
            db=self.db,
            teacher_id=teacher.id,
        )
        self.assertIsInstance(concepts, list)

        assignments = TeacherAnalyticsService.get_teacher_assignments(
            db=self.db,
            teacher_id=teacher.id,
        )
        self.assertIsInstance(assignments, list)

    def test_assignment_workflow(self):
        teacher = (
            self.db.execute(
                select(User)
                .join(Role, Role.id == User.role_id)
                .where(Role.name == "TEACHER")
            )
            .scalars()
            .first()
        )
        student = (
            self.db.execute(
                select(User)
                .join(Role, Role.id == User.role_id)
                .where(Role.name == "STUDENT")
            )
            .scalars()
            .first()
        )
        lesson = self.db.execute(select(Lesson)).scalars().first()

        if not teacher or not student or not lesson:
            self.skipTest("Required entities missing for assignment workflow test.")

        # Ensure student is paired with teacher
        pair = self.db.execute(
            select(StudentTeacher).where(
                StudentTeacher.student_id == student.id,
                StudentTeacher.teacher_id == teacher.id,
            )
        ).scalars().first()
        if not pair:
            # Delete any existing pairing for student
            existing_pair = self.db.execute(
                select(StudentTeacher).where(StudentTeacher.student_id == student.id)
            ).scalars().first()
            if existing_pair:
                self.db.delete(existing_pair)
                self.db.commit()

            new_pair = StudentTeacher(student_id=student.id, teacher_id=teacher.id)
            self.db.add(new_pair)
            self.db.commit()

        # Create assignment
        created = TeacherAnalyticsService.create_assignments(
            db=self.db,
            teacher_id=teacher.id,
            student_ids=[student.id],
            lesson_id=lesson.id,
            due_date=datetime.now(timezone.utc),
            notes="Please complete this homework exercise.",
        )
        self.assertEqual(len(created), 1)
        self.assertEqual(created[0].lesson_id, lesson.id)

        # Retrieve for student
        student_hw = TeacherAnalyticsService.get_student_assignments(
            db=self.db,
            student_id=student.id,
        )
        self.assertTrue(any(a.id == created[0].id for a in student_hw))


if __name__ == "__main__":
    unittest.main()
