import unittest
from uuid import uuid4

from fastapi import HTTPException
from sqlalchemy import select

from app.db.session import SessionLocal
from app.models.mentorship_request import MentorshipRequest
from app.models.role import Role
from app.models.teacher_profile import TeacherProfile
from app.models.user import User
from app.schemas.custom_problem import CustomProblemCreate, TestCaseItem
from app.services.admin_educator_service import AdminEducatorService
from app.services.custom_problem_service import CustomProblemService
from app.services.mentorship_service import MentorshipService


class TestFacultyVerificationGate(unittest.TestCase):
    def setUp(self):
        self.db = SessionLocal()

    def tearDown(self):
        try:
            self.db.rollback()
        except Exception:
            pass
        self.db.close()

    def _create_user(self, role_name: str, prefix: str) -> User:
        role = self.db.scalar(select(Role).where(Role.name == role_name))
        suffix = uuid4().hex[:6]
        user = User(
            username=f"{prefix}_{suffix}",
            email=f"{prefix}_{suffix}@example.com",
            hashed_password="hashed_pw_test",
            first_name=prefix.capitalize(),
            last_name="Tester",
            role_id=role.id,
            is_active=True,
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def _create_teacher(self, prefix: str, is_verified: bool = False) -> tuple[User, TeacherProfile]:
        teacher = self._create_user("TEACHER", prefix)
        code = f"{prefix[:3].upper()}-{uuid4().hex[:4].upper()}"
        profile = TeacherProfile(
            user_id=teacher.id,
            institution_name="Tech University",
            designation="Assistant Professor",
            subject_expertise="Data Structures",
            class_code=code,
            is_verified=is_verified,
            max_students=50,
            is_accepting_requests=True,
        )
        self.db.add(profile)
        self.db.commit()
        self.db.refresh(profile)
        return teacher, profile

    def test_unverified_teacher_blocked_from_publishing_custom_problem(self):
        teacher, profile = self._create_teacher("unv_prob", is_verified=False)

        problem_data = CustomProblemCreate(
            title=f"Sample Problem {uuid4().hex[:4]}",
            description="Sample description here with enough length",
            starter_code="def solve():\n    pass\n",
            starter_code_python="def solve():\n    pass\n",
            starter_code_java="public class Main {}",
            starter_code_cpp="int main() { return 0; }",
            visibility="CLASS_ONLY",
            test_cases=[
                TestCaseItem(
                    input="1 2",
                    expected="3",
                    is_hidden=False,
                    explanation="Sum of numbers",
                )
            ],
        )

        # Unverified teacher attempting to create with visibility=CLASS_ONLY must be rejected with 403
        with self.assertRaises(HTTPException) as cm:
            CustomProblemService.create_custom_problem(self.db, teacher.id, problem_data)
        self.assertEqual(cm.exception.status_code, 403)

        # Draft problem creation should succeed
        problem_data.visibility = "DRAFT"
        draft_problem = CustomProblemService.create_custom_problem(self.db, teacher.id, problem_data)
        self.assertEqual(draft_problem.visibility, "DRAFT")

        # Attempting to publish via publish endpoint should fail with 403
        with self.assertRaises(HTTPException) as cm:
            CustomProblemService.publish_problem(self.db, teacher, draft_problem.id)
        self.assertEqual(cm.exception.status_code, 403)

    def test_unverified_teacher_joining_and_approval_gate(self):
        teacher, profile = self._create_teacher("unv_teach", is_verified=False)
        student = self._create_user("STUDENT", "stud_unv")

        # Student cannot join via code of unverified teacher
        with self.assertRaises(HTTPException) as cm:
            MentorshipService.create_request(self.db, student_id=student.id, class_code=profile.class_code)
        self.assertEqual(cm.exception.status_code, 400)
        self.assertIn("verification", cm.exception.detail.lower())

        # If a pending request existed, unverified teacher cannot approve it
        req = MentorshipRequest(
            student_id=student.id,
            teacher_id=teacher.id,
            status="PENDING",
        )
        self.db.add(req)
        self.db.commit()
        self.db.refresh(req)

        with self.assertRaises(HTTPException) as cm:
            MentorshipService.approve_request(self.db, req.id, teacher.id)
        self.assertEqual(cm.exception.status_code, 403)

    def test_admin_verify_and_revoke_lifecycle(self):
        teacher, profile = self._create_teacher("admin_ver", is_verified=False)

        # Admin educator service lists educator in pending list
        pending = AdminEducatorService.get_pending_educators(self.db, include_all=False)
        pending_ids = [p.user_id for p in pending]
        self.assertIn(teacher.id, pending_ids)

        # Admin verifies teacher
        verified_item = AdminEducatorService.verify_educator(self.db, teacher.id)
        self.assertTrue(verified_item.is_verified)

        # Check in DB
        self.db.refresh(profile)
        self.assertTrue(profile.is_verified)

        # Now custom problem publishing succeeds for the verified teacher
        problem_data = CustomProblemCreate(
            title=f"Verified Problem {uuid4().hex[:4]}",
            description="Testing verified educator publishing with sufficient length",
            starter_code="def solve():\n    pass\n",
            starter_code_python="def solve():\n    pass\n",
            starter_code_java="public class Main {}",
            starter_code_cpp="int main() { return 0; }",
            visibility="CLASS_ONLY",
            test_cases=[
                TestCaseItem(
                    input="abc",
                    expected="cba",
                    is_hidden=False,
                    explanation="Reversed string explanation",
                )
            ],
        )
        published_problem = CustomProblemService.create_custom_problem(self.db, teacher.id, problem_data)
        self.assertEqual(published_problem.visibility, "CLASS_ONLY")

        # Admin revokes verification
        revoked_item = AdminEducatorService.revoke_educator(self.db, teacher.id)
        self.assertFalse(revoked_item.is_verified)

        self.db.refresh(profile)
        self.assertFalse(profile.is_verified)

        # Now publishing is blocked again
        problem_data.title = f"Blocked Problem {uuid4().hex[:4]}"
        with self.assertRaises(HTTPException) as cm:
            CustomProblemService.create_custom_problem(self.db, teacher.id, problem_data)
        self.assertEqual(cm.exception.status_code, 403)


if __name__ == "__main__":
    unittest.main()
