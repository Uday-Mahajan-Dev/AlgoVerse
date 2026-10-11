import unittest
from datetime import datetime, timezone
from uuid import uuid4

from fastapi import HTTPException
from sqlalchemy import select

from app.db.session import SessionLocal
from app.models.course import Course
from app.models.course_module import CourseModule
from app.models.custom_problem import CustomProblem
from app.models.lesson import Lesson
from app.models.lesson_feedback import LessonFeedback
from app.models.problem import Problem
from app.models.problem_feedback import ProblemFeedback
from app.models.professor_rating import ProfessorRating
from app.models.role import Role
from app.models.student_teacher import StudentTeacher
from app.models.teacher_profile import TeacherProfile
from app.models.user import User
from app.schemas.feedback import (
    LessonFeedbackCreate,
    ProblemFeedbackCreate,
    ProfessorRatingCreate,
)
from app.services.feedback_service import FeedbackService
from app.services.mentorship_service import MentorshipService


class TestFeedbackAndRatings(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.db = SessionLocal()

    @classmethod
    def tearDownClass(cls):
        cls.db.close()

    def setUp(self):
        # Roles
        self.student_role = self.db.scalar(select(Role).where(Role.name == "STUDENT"))
        if not self.student_role:
            self.student_role = Role(name="STUDENT")
            self.db.add(self.student_role)
            self.db.commit()

        self.teacher_role = self.db.scalar(select(Role).where(Role.name == "TEACHER"))
        if not self.teacher_role:
            self.teacher_role = Role(name="TEACHER")
            self.db.add(self.teacher_role)
            self.db.commit()

        suffix = uuid4().hex[:6]
        # Create student 1
        self.student = User(
            id=uuid4(),
            email=f"feedback_student_{suffix}@example.com",
            username=f"fb_student_{suffix}",
            hashed_password="hashed_pw_test",
            role_id=self.student_role.id,
            is_active=True,
            first_name="Alice",
            last_name="Student",
        )
        self.db.add(self.student)

        # Create student 2
        self.student2 = User(
            id=uuid4(),
            email=f"feedback_student2_{suffix}@example.com",
            username=f"fb_student2_{suffix}",
            hashed_password="hashed_pw_test",
            role_id=self.student_role.id,
            is_active=True,
            first_name="Bob",
            last_name="Learner",
        )
        self.db.add(self.student2)

        # Create teacher
        self.teacher = User(
            id=uuid4(),
            email=f"feedback_teacher_{suffix}@example.com",
            username=f"fb_teacher_{suffix}",
            hashed_password="hashed_pw_test",
            role_id=self.teacher_role.id,
            is_active=True,
            first_name="Alan",
            last_name="Turing",
        )
        self.db.add(self.teacher)
        self.db.commit()

        self.teacher_profile = TeacherProfile(
            user_id=self.teacher.id,
            institution_name="Stanford University",
            designation="Professor",
            subject_expertise="Graph Theory",
            class_code=f"GT-{suffix[:4].upper()}",
            is_verified=True,
            max_students=50,
            is_accepting_requests=True,
        )
        self.db.add(self.teacher_profile)

        # Create course + module + lesson
        self.course = Course(
            id=uuid4(),
            title=f"Feedback Course {suffix}",
            slug=f"feedback-course-{suffix}",
            description="Testing ratings",
            difficulty="INTERMEDIATE",
            topic_category="TREES",
            is_published=True,
        )
        self.db.add(self.course)
        self.db.commit()

        self.module = CourseModule(
            id=uuid4(),
            course_id=self.course.id,
            title="Tree Traversals",
            order_index=1,
        )
        self.db.add(self.module)
        self.db.commit()

        self.lesson = Lesson(
            id=uuid4(),
            module_id=self.module.id,
            title="Inorder Traversal",
            slug=f"inorder-traversal-{suffix}",
            content_type="CONCEPT",
            content_json={"text": "Traversal logic"},
            order_index=1,
            estimated_minutes=15,
        )
        self.db.add(self.lesson)
        self.db.commit()

        # Create course problem
        self.problem = Problem(
            id=uuid4(),
            lesson_id=self.lesson.id,
            title="Inorder Traversal Problem",
            description="Perform traversal",
            function_name="inorder",
            starter_code_python="def inorder(): pass",
            starter_code_java="class Solution {}",
            starter_code_cpp="void solve() {}",
            solution_code_python="def inorder(): return [1]",
            solution_code_java="class Solution {}",
            solution_code_cpp="void solve() {}",
        )
        self.db.add(self.problem)
        self.db.commit()

        # Create custom problem
        self.custom_problem = CustomProblem(
            id=uuid4(),
            teacher_id=self.teacher.id,
            title="Custom Tree Challenge",
            description="Count leaves",
            starter_code="def solve(): pass",
            test_cases=[{"input": "1", "expected": "1", "is_hidden": False}],
            visibility="PUBLIC",
        )
        self.db.add(self.custom_problem)
        self.db.commit()

    def tearDown(self):
        self.db.rollback()
        self.db.query(ProfessorRating).filter(
            ProfessorRating.teacher_id == self.teacher.id
        ).delete()
        self.db.query(StudentTeacher).filter(
            StudentTeacher.teacher_id == self.teacher.id
        ).delete()
        self.db.query(ProblemFeedback).filter(
            ProblemFeedback.student_id.in_([self.student.id, self.student2.id])
        ).delete()
        self.db.query(LessonFeedback).filter(
            LessonFeedback.lesson_id == self.lesson.id
        ).delete()
        self.db.query(CustomProblem).filter(
            CustomProblem.id == self.custom_problem.id
        ).delete()
        self.db.query(Problem).filter(Problem.id == self.problem.id).delete()
        self.db.query(Lesson).filter(Lesson.id == self.lesson.id).delete()
        self.db.query(CourseModule).filter(CourseModule.id == self.module.id).delete()
        self.db.query(Course).filter(Course.id == self.course.id).delete()
        self.db.query(TeacherProfile).filter(
            TeacherProfile.user_id == self.teacher.id
        ).delete()
        self.db.query(User).filter(
            User.id.in_([self.student.id, self.student2.id, self.teacher.id])
        ).delete()
        self.db.commit()

    def test_lesson_feedback_flow(self):
        """Test submitting and updating lesson feedback, and verifying summary stats."""
        # 1. Submit rating 5
        res = FeedbackService.submit_lesson_feedback(
            db=self.db,
            student_id=self.student.id,
            lesson_id=self.lesson.id,
            data=LessonFeedbackCreate(rating=5, comment="Amazing visualization!"),
        )
        self.assertEqual(res.rating, 5)
        self.assertEqual(res.comment, "Amazing visualization!")

        # 2. Check summary
        summary = FeedbackService.get_lesson_feedback_summary(
            db=self.db,
            lesson_id=self.lesson.id,
            student_id=self.student.id,
        )
        self.assertEqual(summary.avg_rating, 5.0)
        self.assertEqual(summary.rating_count, 1)
        self.assertEqual(summary.my_rating, 5)
        self.assertEqual(summary.my_comment, "Amazing visualization!")

        # 3. Idempotent update (re-rating to 4)
        FeedbackService.submit_lesson_feedback(
            db=self.db,
            student_id=self.student.id,
            lesson_id=self.lesson.id,
            data=LessonFeedbackCreate(rating=4, comment="Updated review"),
        )
        summary_updated = FeedbackService.get_lesson_feedback_summary(
            db=self.db,
            lesson_id=self.lesson.id,
            student_id=self.student.id,
        )
        self.assertEqual(summary_updated.avg_rating, 4.0)
        self.assertEqual(summary_updated.rating_count, 1)
        self.assertEqual(summary_updated.my_rating, 4)

    def test_problem_feedback_flow(self):
        """Test submitting problem feedback for course and custom problems."""
        # Course problem feedback
        res_course = FeedbackService.submit_problem_feedback(
            db=self.db,
            student_id=self.student.id,
            problem_id=self.problem.id,
            data=ProblemFeedbackCreate(problem_kind="course", rating=4, comment="Good challenge"),
        )
        self.assertEqual(res_course.rating, 4)
        self.assertEqual(res_course.problem_kind, "course")

        sum_course = FeedbackService.get_problem_feedback_summary(
            db=self.db,
            problem_id=self.problem.id,
            problem_kind="course",
            student_id=self.student.id,
        )
        self.assertEqual(sum_course.avg_rating, 4.0)
        self.assertEqual(sum_course.rating_count, 1)

        # Custom problem feedback
        res_custom = FeedbackService.submit_problem_feedback(
            db=self.db,
            student_id=self.student.id,
            problem_id=self.custom_problem.id,
            data=ProblemFeedbackCreate(problem_kind="custom", rating=5, comment="Love the test cases"),
        )
        self.assertEqual(res_custom.rating, 5)
        self.assertEqual(res_custom.problem_kind, "custom")

        sum_custom = FeedbackService.get_problem_feedback_summary(
            db=self.db,
            problem_id=self.custom_problem.id,
            problem_kind="custom",
            student_id=self.student.id,
        )
        self.assertEqual(sum_custom.avg_rating, 5.0)
        self.assertEqual(sum_custom.rating_count, 1)

    def test_professor_rating_mentorship_gate_and_directory_stats(self):
        """Test 403 gate for non-mentees, successful rating for mentees, and live directory update."""
        # 1. Non-mentee tries to rate -> MUST raise 403 Forbidden
        with self.assertRaises(HTTPException) as ctx:
            FeedbackService.submit_professor_rating(
                db=self.db,
                student_id=self.student.id,
                teacher_id=self.teacher.id,
                data=ProfessorRatingCreate(rating=5, comment="Great teacher"),
            )
        self.assertEqual(ctx.exception.status_code, 403)
        self.assertIn("Only approved classroom mentees", ctx.exception.detail)

        # 2. Approve mentorship for Student 1
        link1 = StudentTeacher(
            student_id=self.student.id,
            teacher_id=self.teacher.id,
        )
        self.db.add(link1)
        self.db.commit()

        # 3. Now Student 1 rates 5 stars
        res1 = FeedbackService.submit_professor_rating(
            db=self.db,
            student_id=self.student.id,
            teacher_id=self.teacher.id,
            data=ProfessorRatingCreate(rating=5, comment="Very inspiring mentor"),
        )
        self.assertEqual(res1.avg_rating, 5.0)
        self.assertEqual(res1.rating_count, 1)
        self.assertEqual(res1.my_rating, 5)

        # 4. Approve mentorship for Student 2 and rate 3 stars
        link2 = StudentTeacher(
            student_id=self.student2.id,
            teacher_id=self.teacher.id,
        )
        self.db.add(link2)
        self.db.commit()

        res2 = FeedbackService.submit_professor_rating(
            db=self.db,
            student_id=self.student2.id,
            teacher_id=self.teacher.id,
            data=ProfessorRatingCreate(rating=3, comment="Good feedback on homework"),
        )
        # (5 + 3) / 2 = 4.0 avg rating
        self.assertEqual(res2.avg_rating, 4.0)
        self.assertEqual(res2.rating_count, 2)

        # 5. Verify dynamic rating calculation on Professor Directory
        directory = MentorshipService.get_professors_directory(
            db=self.db,
            search_query=self.teacher.username,
            verified_only=False,
        )
        self.assertTrue(len(directory) > 0)
        matching_prof = next(p for p in directory if p.id == self.teacher.id)
        self.assertEqual(matching_prof.avg_rating, 4.0)
        self.assertEqual(matching_prof.rating_count, 2)


if __name__ == "__main__":
    unittest.main()
