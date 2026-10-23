import unittest
from datetime import date, timedelta
from uuid import uuid4
from fastapi.testclient import TestClient
from sqlalchemy import select

from app.core.security import create_access_token
from app.db.session import SessionLocal
from app.main import app
from app.models.educator_application import EducatorApplication
from app.models.role import Role
from app.models.teacher_profile import TeacherProfile
from app.models.user import User


class TestEducatorApplicationSystem(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = TestClient(app)
        cls.db = SessionLocal()

        # Ensure roles exist
        cls.student_role = cls.db.scalar(select(Role).where(Role.name == "STUDENT"))
        if not cls.student_role:
            cls.student_role = Role(name="STUDENT")
            cls.db.add(cls.student_role)
            cls.db.commit()

        cls.teacher_role = cls.db.scalar(select(Role).where(Role.name == "TEACHER"))
        if not cls.teacher_role:
            cls.teacher_role = Role(name="TEACHER")
            cls.db.add(cls.teacher_role)
            cls.db.commit()

        cls.admin_role = cls.db.scalar(select(Role).where(Role.name == "ADMIN"))
        if not cls.admin_role:
            cls.admin_role = Role(name="ADMIN")
            cls.db.add(cls.admin_role)
            cls.db.commit()

    @classmethod
    def tearDownClass(cls):
        cls.db.close()

    def _create_user(self, role_name: str, prefix: str, dob: date | None = None) -> tuple[User, str]:
        role = self.student_role if role_name == "STUDENT" else (self.admin_role if role_name == "ADMIN" else self.teacher_role)
        suffix = uuid4().hex[:6]
        user = User(
            username=f"{prefix}_{suffix}",
            email=f"{prefix}_{suffix}@example.com",
            hashed_password="hashed_pw_test",
            first_name=prefix.capitalize(),
            last_name="Tester",
            role_id=role.id,
            is_active=True,
            date_of_birth=dob,
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        token = create_access_token(subject=str(user.id))
        return user, token

    def test_application_lifecycle_pending_and_student_role(self):
        """Application creates PENDING; role stays STUDENT; no class code active."""
        today = date.today()
        dob_30 = date(today.year - 30, today.month, today.day)
        user, token = self._create_user("STUDENT", "student_pending", dob=dob_30)

        headers = {"Authorization": f"Bearer {token}"}
        payload = {
            "requested_role": "PROFESSOR",
            "date_of_birth": dob_30.isoformat(),
            "institution_name": "MIT",
            "designation": "Associate Professor",
            "subject_expertise": "Algorithms",
            "bio": "Experienced educator",
        }
        resp = self.client.post("/api/v1/educator-applications", json=payload, headers=headers)
        self.assertEqual(resp.status_code, 201, resp.text)
        data = resp.json()
        self.assertEqual(data["status"], "PENDING")
        self.assertEqual(data["requested_role"], "PROFESSOR")
        self.assertEqual(data["age_at_application"], 30)

        # Verify user role is still STUDENT
        self.db.refresh(user)
        self.assertEqual(user.role.name, "STUDENT")

        # Verify no active teacher profile or class code exists
        tp = self.db.scalar(select(TeacherProfile).where(TeacherProfile.user_id == user.id))
        self.assertIsNone(tp)

        # GET /api/v1/educator-applications/me
        me_resp = self.client.get("/api/v1/educator-applications/me", headers=headers)
        self.assertEqual(me_resp.status_code, 200)
        self.assertEqual(me_resp.json()["id"], data["id"])
        self.assertEqual(me_resp.json()["status"], "PENDING")

    def test_age_gate_under_25_professor_rejected(self):
        """Age 24 requesting PROFESSOR -> 400; age 30 PROFESSOR -> OK."""
        today = date.today()
        dob_24 = date(today.year - 24, today.month, today.day)
        user, token = self._create_user("STUDENT", "student_24", dob=dob_24)

        headers = {"Authorization": f"Bearer {token}"}
        payload = {
            "requested_role": "PROFESSOR",
            "date_of_birth": dob_24.isoformat(),
            "institution_name": "Stanford",
            "designation": "Instructor",
            "subject_expertise": "Data Structures",
        }
        # Age 24 requesting PROFESSOR -> 400
        resp = self.client.post("/api/v1/educator-applications", json=payload, headers=headers)
        self.assertEqual(resp.status_code, 400)
        self.assertIn("25", resp.text)

        # Age 24 requesting ASSISTANT -> OK (201)
        payload["requested_role"] = "ASSISTANT"
        resp_asst = self.client.post("/api/v1/educator-applications", json=payload, headers=headers)
        self.assertEqual(resp_asst.status_code, 201)
        self.assertEqual(resp_asst.json()["status"], "PENDING")

    def test_dob_bounds_16_and_81_rejected(self):
        """DOB 16 years ago -> 400; DOB 81 years ago -> 400."""
        today = date.today()
        user, token = self._create_user("STUDENT", "student_bounds")
        headers = {"Authorization": f"Bearer {token}"}

        # DOB 16 years ago
        dob_16 = date(today.year - 16, today.month, today.day)
        resp_16 = self.client.post(
            "/api/v1/educator-applications",
            json={
                "requested_role": "ASSISTANT",
                "date_of_birth": dob_16.isoformat(),
                "institution_name": "Harvard",
                "designation": "TA",
                "subject_expertise": "Math",
            },
            headers=headers,
        )
        self.assertEqual(resp_16.status_code, 400)
        self.assertIn("17", resp_16.text)

        # DOB 81 years ago
        dob_81 = date(today.year - 81, today.month, today.day)
        resp_81 = self.client.post(
            "/api/v1/educator-applications",
            json={
                "requested_role": "PROFESSOR",
                "date_of_birth": dob_81.isoformat(),
                "institution_name": "Harvard",
                "designation": "Professor Emeritus",
                "subject_expertise": "Math",
            },
            headers=headers,
        )
        self.assertEqual(resp_81.status_code, 400)
        self.assertIn("80", resp_81.text)

    def test_duplicate_pending_application_conflict(self):
        """Second pending application -> 409."""
        today = date.today()
        dob_28 = date(today.year - 28, today.month, today.day)
        user, token = self._create_user("STUDENT", "student_dup", dob=dob_28)
        headers = {"Authorization": f"Bearer {token}"}

        payload = {
            "requested_role": "PROFESSOR",
            "date_of_birth": dob_28.isoformat(),
            "institution_name": "CMU",
            "designation": "Assistant Professor",
            "subject_expertise": "Operating Systems",
        }
        first = self.client.post("/api/v1/educator-applications", json=payload, headers=headers)
        self.assertEqual(first.status_code, 201)

        # Second pending application -> 409
        second = self.client.post("/api/v1/educator-applications", json=payload, headers=headers)
        self.assertEqual(second.status_code, 409)

    def test_admin_approve_and_reject_flow(self):
        """Admin approve -> role switched, teacher profile verified; reject -> stays STUDENT, can reapply."""
        today = date.today()
        dob_32 = date(today.year - 32, today.month, today.day)
        user_app, student_token = self._create_user("STUDENT", "student_review", dob=dob_32)
        admin_user, admin_token = self._create_user("ADMIN", "admin_reviewer")

        # 1. Submit application
        res = self.client.post(
            "/api/v1/educator-applications",
            json={
                "requested_role": "PROFESSOR",
                "date_of_birth": dob_32.isoformat(),
                "institution_name": "Oxford",
                "designation": "Reader",
                "subject_expertise": "Theory of Computation",
            },
            headers={"Authorization": f"Bearer {student_token}"},
        )
        self.assertEqual(res.status_code, 201)
        app_id = res.json()["id"]

        # 2. Admin approves
        approve_res = self.client.post(
            f"/api/v1/admin/educator-applications/{app_id}/approve",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        self.assertEqual(approve_res.status_code, 200)
        self.assertEqual(approve_res.json()["status"], "APPROVED")

        # Verify applicant is now TEACHER and teacher profile is verified
        self.db.refresh(user_app)
        self.assertEqual(user_app.role.name, "TEACHER")
        tp = self.db.scalar(select(TeacherProfile).where(TeacherProfile.user_id == user_app.id))
        self.assertIsNotNone(tp)
        self.assertTrue(tp.is_verified)
        self.assertIsNotNone(tp.class_code)

        # 3. Test Reject flow with a separate user
        user_rej, token_rej = self._create_user("STUDENT", "student_rej", dob=dob_32)
        res_rej_submit = self.client.post(
            "/api/v1/educator-applications",
            json={
                "requested_role": "PROFESSOR",
                "date_of_birth": dob_32.isoformat(),
                "institution_name": "Cambridge",
                "designation": "Lecturer",
                "subject_expertise": "Databases",
            },
            headers={"Authorization": f"Bearer {token_rej}"},
        )
        self.assertEqual(res_rej_submit.status_code, 201)
        rej_app_id = res_rej_submit.json()["id"]

        # Admin rejects
        reject_res = self.client.post(
            f"/api/v1/admin/educator-applications/{rej_app_id}/reject",
            json={"admin_note": "Please submit verified institutional email credentials."},
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        self.assertEqual(reject_res.status_code, 200)
        self.assertEqual(reject_res.json()["status"], "REJECTED")
        self.assertEqual(reject_res.json()["admin_note"], "Please submit verified institutional email credentials.")

        # Stays STUDENT
        self.db.refresh(user_rej)
        self.assertEqual(user_rej.role.name, "STUDENT")

        # User can reapply after rejection
        reapply_res = self.client.post(
            "/api/v1/educator-applications",
            json={
                "requested_role": "PROFESSOR",
                "date_of_birth": dob_32.isoformat(),
                "institution_name": "Cambridge University",
                "designation": "Senior Lecturer",
                "subject_expertise": "Distributed Databases",
            },
            headers={"Authorization": f"Bearer {token_rej}"},
        )
        self.assertEqual(reapply_res.status_code, 201)
        self.assertEqual(reapply_res.json()["status"], "PENDING")

    def test_dob_edit_locked_while_pending(self):
        """DOB edit while PENDING -> 409."""
        today = date.today()
        dob_27 = date(today.year - 27, today.month, today.day)
        user, token = self._create_user("STUDENT", "student_lock", dob=dob_27)
        headers = {"Authorization": f"Bearer {token}"}

        # Apply as educator
        res = self.client.post(
            "/api/v1/educator-applications",
            json={
                "requested_role": "PROFESSOR",
                "date_of_birth": dob_27.isoformat(),
                "institution_name": "Princeton",
                "designation": "Assistant Professor",
                "subject_expertise": "Cryptography",
            },
            headers=headers,
        )
        self.assertEqual(res.status_code, 201)

        # Attempt to modify DOB via PATCH /api/v1/users/me -> 409
        dob_new = date(today.year - 29, today.month, today.day)
        patch_res = self.client.patch(
            "/api/v1/users/me",
            json={"date_of_birth": dob_new.isoformat()},
            headers=headers,
        )
        self.assertEqual(patch_res.status_code, 409)
        self.assertIn("locked", patch_res.text.lower())

    def test_non_admin_calling_admin_endpoints_forbidden(self):
        """Non-admin calling admin endpoints -> 403."""
        user, token = self._create_user("STUDENT", "student_no_admin")
        headers = {"Authorization": f"Bearer {token}"}

        list_res = self.client.get("/api/v1/admin/educator-applications", headers=headers)
        self.assertEqual(list_res.status_code, 403)

        fake_id = uuid4()
        appr_res = self.client.post(f"/api/v1/admin/educator-applications/{fake_id}/approve", headers=headers)
        self.assertEqual(appr_res.status_code, 403)

        rej_res = self.client.post(
            f"/api/v1/admin/educator-applications/{fake_id}/reject",
            json={"admin_note": "denied"},
            headers=headers,
        )
        self.assertEqual(rej_res.status_code, 403)


if __name__ == "__main__":
    unittest.main()
