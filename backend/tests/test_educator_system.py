from datetime import date
import unittest
from uuid import uuid4

from fastapi import HTTPException
from sqlalchemy import select

from app.db.session import SessionLocal
from app.models.role import Role
from app.models.student_teacher import StudentTeacher
from app.models.ta_approval_request import TAApprovalRequest
from app.models.teacher_profile import TeacherProfile
from app.models.user import User
from app.models.user_badge import UserBadge
from app.services.teacher_service import TeacherService


class TestEducatorSystem(unittest.TestCase):
    def setUp(self):
        self.db = SessionLocal()

    def tearDown(self):
        self.db.close()

    def test_educator_registration_and_join_class(self):
        student_role = self.db.scalar(select(Role).where(Role.name == "STUDENT"))
        if not student_role:
            self.skipTest("Student role not configured in DB.")

        unique_suffix = uuid4().hex[:6]

        # Create test users
        teacher_user = User(
            username=f"educator_{unique_suffix}",
            email=f"educator_{unique_suffix}@example.com",
            hashed_password="hashed_pw_test",
            first_name="Prof",
            last_name="Tester",
            role_id=student_role.id,
            is_active=True,
        )
        joiner_student = User(
            username=f"joiner_{unique_suffix}",
            email=f"joiner_{unique_suffix}@example.com",
            hashed_password="hashed_pw_test",
            first_name="Alice",
            last_name="Learner",
            role_id=student_role.id,
            is_active=True,
        )
        ta_applicant = User(
            username=f"ta_{unique_suffix}",
            email=f"ta_{unique_suffix}@example.com",
            hashed_password="hashed_pw_test",
            first_name="Bob",
            last_name="Assistant",
            role_id=student_role.id,
            is_active=True,
        )
        self.db.add_all([teacher_user, joiner_student, ta_applicant])
        self.db.commit()
        self.db.refresh(teacher_user)
        self.db.refresh(joiner_student)
        self.db.refresh(ta_applicant)

        try:
            # 1. Adult Professor Registration (Age >= 25) -> APPROVED
            reg_res = TeacherService.register_educator(
                db=self.db,
                user_id=teacher_user.id,
                institution_name="VIT University",
                designation="Professor",
                subject_expertise="Advanced Data Structures & Algorithms",
                date_of_birth=date(1990, 5, 15),
                bio="Passionate computer science educator.",
            )
            self.assertEqual(reg_res.status, "APPROVED")
            self.assertEqual(reg_res.role, "TEACHER")
            self.assertTrue(reg_res.class_code.startswith("VIT-") or "-" in reg_res.class_code)
            self.assertEqual(reg_res.institution_name, "VIT University")

            # Verify teacher profile is saved in DB
            profile = self.db.scalar(select(TeacherProfile).where(TeacherProfile.user_id == teacher_user.id))
            self.assertIsNotNone(profile)
            self.assertEqual(profile.class_code, reg_res.class_code)

            # Verify user's role was updated to TEACHER
            self.db.refresh(teacher_user)
            self.assertEqual(teacher_user.role.name, "TEACHER")

            # 2. Age-Gate rejection test: Under 25 trying to register directly as Professor
            with self.assertRaises(HTTPException) as ctx:
                TeacherService.register_educator(
                    db=self.db,
                    user_id=ta_applicant.id,
                    institution_name="VIT University",
                    designation="Professor",
                    subject_expertise="Data Structures",
                    date_of_birth=date(2005, 1, 1), # Age < 25
                )
            self.assertEqual(ctx.exception.status_code, 400)

            # 3. Under 25 TA application with supervisor email -> PENDING_SUPERVISOR_APPROVAL
            ta_res = TeacherService.register_educator(
                db=self.db,
                user_id=ta_applicant.id,
                institution_name="VIT University",
                designation="Teaching Assistant",
                subject_expertise="Data Structures",
                date_of_birth=date(2005, 1, 1),
                supervisor_email=teacher_user.email,
                bio="Eager student TA.",
            )
            self.assertEqual(ta_res.status, "PENDING_SUPERVISOR_APPROVAL")
            self.db.refresh(ta_applicant)
            self.assertEqual(ta_applicant.role.name, "STUDENT")

            # 4. Supervisor sees TA request and approves
            ta_requests = TeacherService.get_ta_requests(db=self.db, teacher_id=teacher_user.id)
            self.assertTrue(len(ta_requests) >= 1)
            matching_req = [r for r in ta_requests if r.applicant_id == ta_applicant.id][0]

            respond_res = TeacherService.respond_to_ta_request(
                db=self.db,
                teacher_id=teacher_user.id,
                request_id=matching_req.id,
                action="APPROVE",
            )
            self.assertEqual(respond_res.status, "APPROVED")

            # TA applicant is now TEACHER
            self.db.refresh(ta_applicant)
            self.assertEqual(ta_applicant.role.name, "TEACHER")

            # 5. Student joins class using class code
            join_res = TeacherService.join_class_by_code(
                db=self.db,
                student_id=joiner_student.id,
                class_code=reg_res.class_code.lower(),  # Test case insensitivity
            )
            self.assertEqual(join_res.teacher_id, teacher_user.id)
            self.assertEqual(join_res.class_code, reg_res.class_code)

            # 6. Verify student is paired in student_teachers table
            pair = self.db.scalar(
                select(StudentTeacher).where(
                    StudentTeacher.student_id == joiner_student.id,
                    StudentTeacher.teacher_id == teacher_user.id,
                )
            )
            self.assertIsNotNone(pair)

            # 7. Verify get_my_teacher returns the teacher
            my_teacher = TeacherService.get_my_teacher(db=self.db, student_id=joiner_student.id)
            self.assertTrue(my_teacher.has_teacher)
            self.assertEqual(my_teacher.teacher.id, teacher_user.id)
            self.assertEqual(my_teacher.teacher.class_code, reg_res.class_code)

        finally:
            # Cleanup test records
            self.db.query(UserBadge).filter(
                UserBadge.user_id.in_([teacher_user.id, joiner_student.id, ta_applicant.id])
            ).delete(synchronize_session=False)
            self.db.query(TAApprovalRequest).filter(
                (TAApprovalRequest.applicant_id == ta_applicant.id) | (TAApprovalRequest.supervisor_id == teacher_user.id)
            ).delete(synchronize_session=False)
            self.db.query(StudentTeacher).filter(
                (StudentTeacher.student_id == joiner_student.id) | (StudentTeacher.teacher_id == teacher_user.id)
            ).delete(synchronize_session=False)
            self.db.query(TeacherProfile).filter(
                (TeacherProfile.user_id == teacher_user.id) | (TeacherProfile.user_id == ta_applicant.id)
            ).delete(synchronize_session=False)
            self.db.delete(teacher_user)
            self.db.delete(joiner_student)
            self.db.delete(ta_applicant)
            self.db.commit()


if __name__ == "__main__":
    unittest.main()
