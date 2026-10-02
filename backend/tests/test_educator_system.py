import unittest
from uuid import uuid4

from app.db.session import SessionLocal
from app.models.role import Role
from app.models.student_teacher import StudentTeacher
from app.models.teacher_profile import TeacherProfile
from app.models.user import User
from app.services.teacher_service import TeacherService
from sqlalchemy import select


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

        # Create two test student users
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
        self.db.add_all([teacher_user, joiner_student])
        self.db.commit()
        self.db.refresh(teacher_user)
        self.db.refresh(joiner_student)

        try:
            # 1. Register as Educator
            reg_res = TeacherService.register_educator(
                db=self.db,
                user_id=teacher_user.id,
                institution_name="VIT University",
                subject_expertise="Advanced Data Structures & Algorithms",
                bio="Passionate computer science educator.",
            )
            self.assertEqual(reg_res.role, "TEACHER")
            self.assertTrue(reg_res.class_code.startswith("VIT-") or "-" in reg_res.class_code)
            self.assertEqual(reg_res.institution_name, "VIT University")

            # Verify teacher profile is saved in DB
            profile = self.db.scalar(select(TeacherProfile).where(TeacherProfile.user_id == teacher_user.id))
            self.assertIsNotNone(profile)
            self.assertEqual(profile.class_code, reg_res.class_code)

            # Verify user's role was updated
            self.db.refresh(teacher_user)
            self.assertEqual(teacher_user.role.name, "TEACHER")

            # 2. Student joins class using class code
            join_res = TeacherService.join_class_by_code(
                db=self.db,
                student_id=joiner_student.id,
                class_code=reg_res.class_code.lower(),  # Test case insensitivity
            )
            self.assertEqual(join_res.teacher_id, teacher_user.id)
            self.assertEqual(join_res.class_code, reg_res.class_code)

            # 3. Verify student is paired in student_teachers table
            pair = self.db.scalar(
                select(StudentTeacher).where(
                    StudentTeacher.student_id == joiner_student.id,
                    StudentTeacher.teacher_id == teacher_user.id,
                )
            )
            self.assertIsNotNone(pair)

            # 4. Verify get_my_teacher returns the teacher
            my_teacher = TeacherService.get_my_teacher(db=self.db, student_id=joiner_student.id)
            self.assertTrue(my_teacher.has_teacher)
            self.assertEqual(my_teacher.teacher.id, teacher_user.id)
            self.assertEqual(my_teacher.teacher.class_code, reg_res.class_code)

        finally:
            # Cleanup test records
            self.db.query(StudentTeacher).filter(
                (StudentTeacher.student_id == joiner_student.id) | (StudentTeacher.teacher_id == teacher_user.id)
            ).delete()
            self.db.query(TeacherProfile).filter(TeacherProfile.user_id == teacher_user.id).delete()
            self.db.delete(teacher_user)
            self.db.delete(joiner_student)
            self.db.commit()


if __name__ == "__main__":
    unittest.main()
