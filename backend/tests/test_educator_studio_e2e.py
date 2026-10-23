import unittest
from uuid import uuid4
from fastapi.testclient import TestClient

from app.main import app
from app.db.session import SessionLocal
from app.models.user import User
from app.models.role import Role
from app.models.teacher_profile import TeacherProfile
from app.core.security import get_password_hash, create_access_token


class TestEducatorStudioE2E(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = TestClient(app)
        cls.db = SessionLocal()

        # Ensure TEACHER and STUDENT roles exist
        cls.teacher_role = cls.db.query(Role).filter(Role.name == "TEACHER").first()
        if not cls.teacher_role:
            cls.teacher_role = Role(name="TEACHER", description="Teacher")
            cls.db.add(cls.teacher_role)
            cls.db.commit()

        cls.student_role = cls.db.query(Role).filter(Role.name == "STUDENT").first()
        if not cls.student_role:
            cls.student_role = Role(name="STUDENT", description="Student")
            cls.db.add(cls.student_role)
            cls.db.commit()

        # Create Verified Teacher
        cls.teacher_id = uuid4()
        cls.teacher_email = f"prof_e2e_{uuid4().hex[:6]}@algoverse.dev"
        cls.teacher_user = User(
            id=cls.teacher_id,
            email=cls.teacher_email,
            username=f"profe2e_{uuid4().hex[:6]}",
            hashed_password=get_password_hash("Prof@1234"),
            role_id=cls.teacher_role.id,
            is_active=True,
            email_verified=True,
            first_name="Alan",
            last_name="Turing",
        )
        cls.db.add(cls.teacher_user)
        cls.db.commit()

        # Create Verified TeacherProfile with unique class code
        cls.class_code = f"CODE{uuid4().hex[:4].upper()}"
        cls.teacher_profile = TeacherProfile(
            user_id=cls.teacher_id,
            class_code=cls.class_code,
            institution_name="Cambridge Dept of Computing",
            designation="Professor",
            subject_expertise="Algorithms & Complexity",
            is_verified=True,
        )
        cls.db.add(cls.teacher_profile)
        cls.db.commit()

        # Create Student
        cls.student_id = uuid4()
        cls.student_email = f"student_e2e_{uuid4().hex[:6]}@algoverse.dev"
        cls.student_user = User(
            id=cls.student_id,
            email=cls.student_email,
            username=f"studente2e_{uuid4().hex[:6]}",
            hashed_password=get_password_hash("Student@1234"),
            role_id=cls.student_role.id,
            is_active=True,
            email_verified=True,
            first_name="Ada",
            last_name="Lovelace",
        )
        cls.db.add(cls.student_user)
        cls.db.commit()

        # Generate tokens
        cls.teacher_token = create_access_token(subject=str(cls.teacher_id))
        cls.student_token = create_access_token(subject=str(cls.student_id))

    @classmethod
    def tearDownClass(cls):
        cls.db.close()

    def test_01_create_draft_custom_problem(self):
        """Teacher creates a custom problem in Educator Studio with multiple language starter templates."""
        headers = {"Authorization": f"Bearer {self.teacher_token}"}
        payload = {
            "title": "Reverse Words in a String",
            "description": "Given an input string s, reverse the order of the words.",
            "starter_code_python": "def reverseWords(s: str) -> str:\n    # TODO\n    pass",
            "starter_code_java": "public class Main {\n    public static void main(String[] args) {\n        // TODO\n    }\n}",
            "starter_code_cpp": "#include <iostream>\nusing namespace std;\nint main() {\n    // TODO\n    return 0;\n}",
            "test_cases": [
                {
                    "input": "the sky is blue",
                    "expected": "blue is sky the",
                    "is_hidden": False,
                    "explanation": "Words separated by spaces reversed"
                },
                {
                    "input": "  hello world  ",
                    "expected": "world hello",
                    "is_hidden": True,
                    "explanation": "Multiple spaces stripped"
                }
            ],
            "visibility": "DRAFT"
        }
        resp = self.client.post("/api/v1/teachers/custom-problems", headers=headers, json=payload)
        self.assertEqual(resp.status_code, 201, f"Failed to create problem: {resp.text}")
        data = resp.json()
        self.assertEqual(data["title"], "Reverse Words in a String")
        self.assertEqual(data["visibility"], "DRAFT")
        self.assertEqual(len(data["test_cases"]), 2)
        self.__class__.problem_id = data["id"]

    def test_02_publish_problem(self):
        """Teacher publishes the draft problem so it becomes available to students."""
        headers = {"Authorization": f"Bearer {self.teacher_token}"}
        resp = self.client.post(
            f"/api/v1/teachers/custom-problems/{self.problem_id}/publish",
            headers=headers,
            json={"visibility": "CLASS_ONLY"}
        )
        self.assertEqual(resp.status_code, 200, f"Failed to publish problem: {resp.text}")
        data = resp.json()
        self.assertEqual(data["visibility"], "CLASS_ONLY")

    def test_03_teacher_list_shows_published_problem(self):
        """Teacher sees the published problem in their Educator Studio dashboard."""
        headers = {"Authorization": f"Bearer {self.teacher_token}"}
        resp = self.client.get("/api/v1/teachers/custom-problems", headers=headers)
        self.assertEqual(resp.status_code, 200)
        problems = resp.json()
        found = [p for p in problems if p["id"] == self.problem_id]
        self.assertTrue(len(found) > 0, "Problem not found in teacher's list")
        self.assertEqual(found[0]["visibility"], "CLASS_ONLY")

    def test_04_student_joins_teacher_class_and_sees_challenge(self):
        """Student enters class code, teacher approves, and student sees the challenge on student dashboard."""
        student_headers = {"Authorization": f"Bearer {self.student_token}"}
        teacher_headers = {"Authorization": f"Bearer {self.teacher_token}"}

        # 1. Student requests to join classroom using class code
        join_resp = self.client.post(
            "/api/v1/teachers/join-class",
            headers=student_headers,
            json={"class_code": self.class_code}
        )
        self.assertEqual(join_resp.status_code, 200, f"Join class failed: {join_resp.text}")

        # 2. Teacher sees pending mentorship request and approves it
        requests_resp = self.client.get(
            "/api/v1/teachers/me/mentorship-requests?status=PENDING",
            headers=teacher_headers
        )
        self.assertEqual(requests_resp.status_code, 200)
        reqs = requests_resp.json()
        matching_req = [r for r in reqs if r["student_id"] == str(self.student_id)]
        self.assertTrue(len(matching_req) > 0, "Mentorship request not found in teacher's queue")
        req_id = matching_req[0]["id"]

        approve_resp = self.client.post(
            f"/api/v1/teachers/me/mentorship-requests/{req_id}/approve",
            headers=teacher_headers
        )
        self.assertEqual(approve_resp.status_code, 200, f"Approve mentorship request failed: {approve_resp.text}")

        # 3. Query mentor challenges (powers 'CHALLENGES FROM YOUR MENTOR' on Student Dashboard)
        mentor_prob_resp = self.client.get("/api/v1/students/me/mentor-problems", headers=student_headers)
        self.assertEqual(mentor_prob_resp.status_code, 200)
        challenges = mentor_prob_resp.json()
        found = [c for c in challenges if c["id"] == self.problem_id]
        self.assertTrue(len(found) > 0, "Published problem did not appear in student's mentor challenges")
        prob = found[0]
        self.assertEqual(prob["title"], "Reverse Words in a String")
        self.assertEqual(prob["teacher_name"], "Alan Turing")
        # Hidden test case should be masked for students
        hidden_cases = [tc for tc in prob["test_cases"] if tc.get("is_hidden") is True]
        self.assertTrue(len(hidden_cases) > 0, "Hidden test case not flagged")
        self.assertNotIn("the sky is blue", str(hidden_cases[0].get("input", "")), "Hidden input must not leak")

    def test_05_public_teacher_profile_custom_problems_endpoint(self):
        """Student visiting teacher profile sees published challenges under 'Custom Problems by Teacher'."""
        headers = {"Authorization": f"Bearer {self.student_token}"}
        resp = self.client.get(f"/api/v1/teachers/{self.teacher_id}/custom-problems", headers=headers)
        self.assertEqual(resp.status_code, 200)
        probs = resp.json()
        found = [p for p in probs if p["id"] == self.problem_id]
        self.assertTrue(len(found) > 0, "Problem not listed on public teacher profile")


if __name__ == "__main__":
    unittest.main()
