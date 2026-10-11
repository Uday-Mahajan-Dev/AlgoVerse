from datetime import date, datetime, timezone
import unittest
from uuid import uuid4

from fastapi import HTTPException
from sqlalchemy import select

from app.db.session import SessionLocal
from app.models.mentorship_request import MentorshipRequest
from app.models.role import Role
from app.models.student_teacher import StudentTeacher
from app.models.teacher_profile import TeacherProfile
from app.models.user import User
from app.services.mentorship_service import MentorshipService
from app.services.teacher_service import TeacherService


class TestMentorshipSystem(unittest.TestCase):
    def setUp(self):
        self.db = SessionLocal()

    def tearDown(self):
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

    def _create_teacher(self, prefix: str, is_verified: bool = True, max_students: int = 100) -> tuple[User, TeacherProfile]:
        teacher = self._create_user("TEACHER", prefix)
        code = f"{prefix[:3].upper()}-{uuid4().hex[:4].upper()}"
        profile = TeacherProfile(
            user_id=teacher.id,
            institution_name="MIT Institute",
            designation="Professor",
            subject_expertise="Algorithms",
            class_code=code,
            is_verified=is_verified,
            max_students=max_students,
            is_accepting_requests=True,
        )
        self.db.add(profile)
        self.db.commit()
        self.db.refresh(profile)
        return teacher, profile

    def test_request_and_approval_flow(self):
        teacher, profile = self._create_teacher("prof_approve")
        student = self._create_user("STUDENT", "student_a")

        # 1. Student creates mentorship request by class code
        req = MentorshipService.create_request(
            db=self.db,
            student_id=student.id,
            class_code=profile.class_code,
            message="Hello Professor, please mentor me!",
        )
        self.assertEqual(req.status, "PENDING")
        self.assertEqual(req.teacher_id, teacher.id)
        self.assertEqual(req.student_id, student.id)

        # 2. Duplicate request blocked
        with self.assertRaises(HTTPException) as ctx:
            MentorshipService.create_request(
                db=self.db,
                student_id=student.id,
                teacher_id=teacher.id,
            )
        self.assertEqual(ctx.exception.status_code, 400)

        # 3. Teacher approves request
        approved_req = MentorshipService.approve_request(
            db=self.db,
            request_id=req.id,
            teacher_id=teacher.id,
        )
        self.assertEqual(approved_req.status, "APPROVED")

        # 4. Verify StudentTeacher link created
        link = self.db.scalar(
            select(StudentTeacher).where(
                StudentTeacher.student_id == student.id,
                StudentTeacher.teacher_id == teacher.id,
            )
        )
        self.assertIsNotNone(link)
        self.assertEqual(link.request_id, req.id)

    def test_capacity_enforcement(self):
        teacher, profile = self._create_teacher("prof_cap", max_students=1)
        student1 = self._create_user("STUDENT", "student_c1")
        student2 = self._create_user("STUDENT", "student_c2")

        # Enroll student 1
        req1 = MentorshipService.create_request(
            db=self.db,
            student_id=student1.id,
            teacher_id=teacher.id,
        )
        MentorshipService.approve_request(
            db=self.db,
            request_id=req1.id,
            teacher_id=teacher.id,
        )

        # Student 2 tries to request when capacity is full
        with self.assertRaises(HTTPException) as ctx:
            MentorshipService.create_request(
                db=self.db,
                student_id=student2.id,
                teacher_id=teacher.id,
            )
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertIn("maximum capacity", ctx.exception.detail.lower())

    def test_multi_professor_support(self):
        prof1, _ = self._create_teacher("prof_m1")
        prof2, _ = self._create_teacher("prof_m2")
        student = self._create_user("STUDENT", "student_multi")

        # Request and approve under Prof 1
        r1 = MentorshipService.create_request(db=self.db, student_id=student.id, teacher_id=prof1.id)
        MentorshipService.approve_request(db=self.db, request_id=r1.id, teacher_id=prof1.id)

        # Request and approve under Prof 2 (Must not violate uniqueness!)
        r2 = MentorshipService.create_request(db=self.db, student_id=student.id, teacher_id=prof2.id)
        MentorshipService.approve_request(db=self.db, request_id=r2.id, teacher_id=prof2.id)

        # Verify student is linked to BOTH professors
        mentors = MentorshipService.get_my_mentors(db=self.db, student_id=student.id)
        teacher_ids = {m.teacher_id for m in mentors}
        self.assertIn(prof1.id, teacher_ids)
        self.assertIn(prof2.id, teacher_ids)

    def test_rejection_flow(self):
        teacher, _ = self._create_teacher("prof_rej")
        student = self._create_user("STUDENT", "student_rej")

        req = MentorshipService.create_request(
            db=self.db,
            student_id=student.id,
            teacher_id=teacher.id,
        )
        rej_req = MentorshipService.reject_request(
            db=self.db,
            request_id=req.id,
            teacher_id=teacher.id,
        )
        self.assertEqual(rej_req.status, "REJECTED")

        # Confirm not in StudentTeacher
        link = self.db.scalar(
            select(StudentTeacher).where(
                StudentTeacher.student_id == student.id,
                StudentTeacher.teacher_id == teacher.id,
            )
        )
        self.assertIsNone(link)

    def test_unverified_teacher_cannot_accept_requests(self):
        unverified_teacher, _ = self._create_teacher("prof_unver", is_verified=False)
        student = self._create_user("STUDENT", "student_gate")

        with self.assertRaises(HTTPException) as ctx:
            MentorshipService.create_request(
                db=self.db,
                student_id=student.id,
                teacher_id=unverified_teacher.id,
            )
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertIn("verification", ctx.exception.detail.lower())


if __name__ == "__main__":
    unittest.main()
