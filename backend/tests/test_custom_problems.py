import asyncio
import unittest
from datetime import datetime, timezone
from uuid import uuid4

from sqlalchemy import select

from app.models.custom_problem import CustomProblem
from app.models.role import Role
from app.models.student_teacher import StudentTeacher
from app.models.user import User
from app.schemas.custom_problem import CustomProblemCreate, TestCaseItem
from app.services.custom_problem_service import CustomProblemService
from app.services.judge_service import JudgeService
from app.services.teacher_analytics_service import TeacherAnalyticsService


class TestCustomProblems(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        from app.db.session import SessionLocal

        cls.db = SessionLocal()

    @classmethod
    def tearDownClass(cls):
        cls.db.close()

    def test_custom_problem_creation_and_evaluation(self):
        # Create a test teacher user
        teacher_role = self.db.scalar(select(Role).where(Role.name == "TEACHER"))
        if not teacher_role:
            teacher_role = Role(name="TEACHER")
            self.db.add(teacher_role)
            self.db.commit()

        student_role = self.db.scalar(select(Role).where(Role.name == "STUDENT"))
        if not student_role:
            student_role = Role(name="STUDENT")
            self.db.add(student_role)
            self.db.commit()

        teacher = User(
            id=uuid4(),
            email=f"custom_prob_teacher_{uuid4().hex[:6]}@example.com",
            username=f"cp_teacher_{uuid4().hex[:6]}",
            hashed_password="hashed_pw",
            role_id=teacher_role.id,
            is_active=True,
            first_name="Custom",
            last_name="Teacher",
        )
        student = User(
            id=uuid4(),
            email=f"custom_prob_student_{uuid4().hex[:6]}@example.com",
            username=f"cp_student_{uuid4().hex[:6]}",
            hashed_password="hashed_pw",
            role_id=student_role.id,
            is_active=True,
            first_name="Custom",
            last_name="Student",
        )
        self.db.add(teacher)
        self.db.add(student)
        self.db.commit()

        # Teacher profile with is_verified=True
        from app.models.teacher_profile import TeacherProfile
        profile = TeacherProfile(
            user_id=teacher.id,
            institution_name="MIT",
            designation="Professor",
            class_code=f"CP-{uuid4().hex[:4].upper()}",
            is_verified=True,
            is_accepting_requests=True,
        )
        self.db.add(profile)
        self.db.commit()

        # Link student to teacher
        link = StudentTeacher(student_id=student.id, teacher_id=teacher.id)
        self.db.add(link)
        self.db.commit()

        # Create Custom Problem with test cases
        create_data = CustomProblemCreate(
            title="Add Two Numbers Test",
            description="Given two integers a and b, return their sum.",
            starter_code="def solve():\n    pass\n",
            starter_code_python="def solve():\n    pass\n",
            starter_code_java="public class Main {}",
            starter_code_cpp="int main() { return 0; }",
            test_cases=[
                TestCaseItem(input="3 5", expected="8", is_hidden=False, explanation="3 + 5 = 8"),
                TestCaseItem(input="10 20", expected="30", is_hidden=True),
            ],
            visibility="PUBLIC",
        )

        problem_res = CustomProblemService.create_custom_problem(
            db=self.db,
            teacher_id=teacher.id,
            data=create_data,
        )

        self.assertEqual(problem_res.title, "Add Two Numbers Test")
        self.assertEqual(len(problem_res.test_cases), 2)
        self.assertEqual(problem_res.test_cases[0]["input"], "3 5")
        self.assertEqual(problem_res.test_cases[0]["expected"], "8")

        # 1. Test WA submission
        wa_solution = """
import sys
print(0)
"""
        wa_res = asyncio.run(
            JudgeService.submit_solution(
                db=self.db,
                student_id=student.id,
                problem_id=problem_res.id,
                code=wa_solution,
                language="python",
            )
        )
        self.assertEqual(wa_res.verdict, "WA")
        self.assertEqual(wa_res.xp_awarded, 0)
        self.assertFalse(wa_res.is_first_ac)
        self.assertFalse(wa_res.already_completed)

        # Check mentor challenges list for student before AC
        challenges_before = CustomProblemService.get_mentor_custom_problems(
            db=self.db,
            student_id=student.id,
        )
        matching_before = [c for c in challenges_before if c.id == problem_res.id]
        self.assertTrue(len(matching_before) > 0)
        self.assertFalse(matching_before[0].is_completed)

        # 2. Test First AC submission
        py_solution = """
import sys
nums = sys.stdin.read().split()
if nums:
    a, b = int(nums[0]), int(nums[1])
    print(a + b)
"""
        first_ac_res = asyncio.run(
            JudgeService.submit_solution(
                db=self.db,
                student_id=student.id,
                problem_id=problem_res.id,
                code=py_solution,
                language="python",
            )
        )

        self.assertEqual(first_ac_res.verdict, "AC")
        self.assertEqual(first_ac_res.passed_count, 2)
        self.assertTrue(first_ac_res.is_first_ac)
        self.assertEqual(first_ac_res.xp_awarded, 50)
        self.assertFalse(first_ac_res.already_completed)
        self.assertGreaterEqual(first_ac_res.total_xp, 50)

        # Check mentor challenges list for student after AC -> should have is_completed == True
        challenges_after = CustomProblemService.get_mentor_custom_problems(
            db=self.db,
            student_id=student.id,
        )
        matching_after = [c for c in challenges_after if c.id == problem_res.id]
        self.assertTrue(len(matching_after) > 0)
        self.assertTrue(matching_after[0].is_completed)

        # 3. Test Second AC submission (practice resubmit)
        second_ac_res = asyncio.run(
            JudgeService.submit_solution(
                db=self.db,
                student_id=student.id,
                problem_id=problem_res.id,
                code=py_solution,
                language="python",
            )
        )
        self.assertEqual(second_ac_res.verdict, "AC")
        self.assertFalse(second_ac_res.is_first_ac)
        self.assertEqual(second_ac_res.xp_awarded, 0)
        self.assertTrue(second_ac_res.already_completed)

        # 4. Test Teacher Submissions List & Code View
        teacher_subs = CustomProblemService.get_custom_problem_submissions(
            db=self.db,
            problem_id=problem_res.id,
            teacher_id=teacher.id,
        )
        self.assertGreaterEqual(len(teacher_subs.items), 3)
        self.assertEqual(teacher_subs.successful_ac, 2)
        self.assertTrue(any("print(a + b)" in s.code for s in teacher_subs.items))

        # 5. Test Teacher Overview submissions today
        overview = TeacherAnalyticsService.get_teacher_overview(
            db=self.db,
            teacher_id=teacher.id,
        )
        self.assertGreaterEqual(overview.total_submissions_today, 3)


if __name__ == "__main__":
    unittest.main()
