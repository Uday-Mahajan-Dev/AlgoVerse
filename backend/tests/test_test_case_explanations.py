import unittest
from uuid import uuid4
from pydantic import ValidationError
from sqlalchemy import select

from app.db.session import SessionLocal
from app.models.role import Role
from app.models.student_teacher import StudentTeacher
from app.models.user import User
from app.schemas.custom_problem import CustomProblemCreate, TestCaseItem
from app.services.custom_problem_service import CustomProblemService


class TestTestCaseExplanations(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.db = SessionLocal()

        teacher_role = cls.db.scalar(select(Role).where(Role.name == "TEACHER"))
        if not teacher_role:
            teacher_role = Role(name="TEACHER")
            cls.db.add(teacher_role)
            cls.db.commit()

        student_role = cls.db.scalar(select(Role).where(Role.name == "STUDENT"))
        if not student_role:
            student_role = Role(name="STUDENT")
            cls.db.add(student_role)
            cls.db.commit()

        cls.teacher = User(
            id=uuid4(),
            email=f"explanation_teacher_{uuid4().hex[:6]}@example.com",
            username=f"exp_teacher_{uuid4().hex[:6]}",
            hashed_password="pw",
            role_id=teacher_role.id,
            is_active=True,
            first_name="Exp",
            last_name="Teacher",
        )
        cls.student = User(
            id=uuid4(),
            email=f"explanation_student_{uuid4().hex[:6]}@example.com",
            username=f"exp_student_{uuid4().hex[:6]}",
            hashed_password="pw",
            role_id=student_role.id,
            is_active=True,
            first_name="Exp",
            last_name="Student",
        )
        cls.db.add_all([cls.teacher, cls.student])
        cls.db.commit()

        # Add verified teacher profile
        from app.models.teacher_profile import TeacherProfile
        profile = TeacherProfile(
            user_id=cls.teacher.id,
            institution_name="MIT",
            designation="Professor",
            class_code=f"EXP-{uuid4().hex[:4].upper()}",
            is_verified=True,
            is_accepting_requests=True,
        )
        cls.db.add(profile)
        cls.db.commit()

        # Link student to teacher classroom
        st = StudentTeacher(student_id=cls.student.id, teacher_id=cls.teacher.id)
        cls.db.add(st)
        cls.db.commit()

    @classmethod
    def tearDownClass(cls):
        cls.db.close()

    def test_visible_test_requires_explanation(self):
        # 1. Default is_hidden is True, no explanation needed
        hidden_case = TestCaseItem(input="5", expected="25")
        self.assertTrue(hidden_case.is_hidden)
        self.assertIsNone(hidden_case.explanation)

        # 2. Visible test case without explanation must fail validation
        with self.assertRaises(ValidationError):
            TestCaseItem(input="5", expected="25", is_hidden=False)

        with self.assertRaises(ValidationError):
            TestCaseItem(input="5", expected="25", is_hidden=False, explanation="   ")

        # 3. Visible test case with valid explanation succeeds
        visible_case = TestCaseItem(
            input="5",
            expected="25",
            is_hidden=False,
            explanation="5 squared equals 25",
        )
        self.assertFalse(visible_case.is_hidden)
        self.assertEqual(visible_case.explanation, "5 squared equals 25")

        # 4. Explanation longer than 200 chars must fail validation
        with self.assertRaises(ValidationError):
            TestCaseItem(
                input="5",
                expected="25",
                is_hidden=False,
                explanation="x" * 201,
            )

    def test_hidden_test_payload_omits_sensitive_fields_for_students(self):
        # Create problem with 1 hidden test and 1 visible test with explanation
        problem_data = CustomProblemCreate(
            title=f"Square Problem {uuid4().hex[:4]}",
            description="Calculate square of a number",
            starter_code="def solve(): pass",
            starter_code_python="def solve(): pass",
            starter_code_java="public class Main {}",
            starter_code_cpp="int main() { return 0; }",
            test_cases=[
                TestCaseItem(
                    input="2",
                    expected="4",
                    is_hidden=False,
                    explanation="2 * 2 = 4 (Visible Sample)",
                ),
                TestCaseItem(
                    input="100",
                    expected="10000",
                    is_hidden=True,
                ),
            ],
            visibility="CLASS_ONLY",
        )

        problem_resp = CustomProblemService.create_custom_problem(
            db=self.db,
            teacher_id=self.teacher.id,
            data=problem_data,
        )

        # Student fetches problem
        student_view = CustomProblemService.get_custom_problem_by_id(
            db=self.db,
            problem_id=problem_resp.id,
            user_id=self.student.id,
        )

        self.assertEqual(len(student_view.test_cases), 2)

        # Case 1: Visible test case
        visible_tc = student_view.test_cases[0]
        self.assertFalse(visible_tc.get("is_hidden"))
        self.assertEqual(visible_tc.get("input"), "2")
        self.assertEqual(visible_tc.get("expected"), "4")
        self.assertEqual(visible_tc.get("explanation"), "2 * 2 = 4 (Visible Sample)")

        # Case 2: Hidden test case — sensitive fields OMITTED
        hidden_tc = student_view.test_cases[1]
        self.assertTrue(hidden_tc.get("is_hidden"))
        self.assertNotIn("input", hidden_tc)
        self.assertNotIn("expected", hidden_tc)
        self.assertNotIn("explanation", hidden_tc)
        self.assertEqual(hidden_tc.get("name"), "Hidden Test #2")

        # Teacher fetches problem — receives full test cases for editing
        teacher_view = CustomProblemService.get_custom_problem_by_id(
            db=self.db,
            problem_id=problem_resp.id,
            user_id=self.teacher.id,
        )
        self.assertEqual(teacher_view.test_cases[1].get("input"), "100")
        self.assertEqual(teacher_view.test_cases[1].get("expected"), "10000")
