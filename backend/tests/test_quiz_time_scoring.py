import unittest
from uuid import uuid4
from fastapi import HTTPException
from sqlalchemy import select

from app.db.session import SessionLocal
from app.models.role import Role
from app.models.user import User
from app.schemas.quiz import QuizCreate, QuizQuestionCreate, QuizSubmitRequest, QuizAnswerItem
from app.services.quiz_service import QuizService


class TestQuizTimeScoring(unittest.TestCase):
    def setUp(self):
        self.db = SessionLocal()

    def tearDown(self):
        self.db.close()

    def test_quiz_time_multiplier_and_anti_cheat(self):
        student_role = self.db.scalar(select(Role).where(Role.name == "STUDENT"))
        if not student_role:
            self.skipTest("Student role not configured in DB.")

        suffix = uuid4().hex[:6]
        teacher = User(
            username=f"quiz_prof_{suffix}",
            email=f"quiz_prof_{suffix}@example.com",
            hashed_password="pw",
            first_name="Prof",
            last_name="Scorer",
            role_id=student_role.id,
            is_active=True,
        )
        fast_student = User(
            username=f"fast_stu_{suffix}",
            email=f"fast_stu_{suffix}@example.com",
            hashed_password="pw",
            first_name="Fast",
            last_name="Runner",
            role_id=student_role.id,
            is_active=True,
        )
        slow_student = User(
            username=f"slow_stu_{suffix}",
            email=f"slow_stu_{suffix}@example.com",
            hashed_password="pw",
            first_name="Slow",
            last_name="Walker",
            role_id=student_role.id,
            is_active=True,
        )
        late_student = User(
            username=f"late_stu_{suffix}",
            email=f"late_stu_{suffix}@example.com",
            hashed_password="pw",
            first_name="Late",
            last_name="Cheater",
            role_id=student_role.id,
            is_active=True,
        )
        self.db.add_all([teacher, fast_student, slow_student, late_student])
        self.db.commit()

        # Create Quiz with TIME_MULTIPLIER and 100s time limit
        quiz_data = QuizCreate(
            title=f"Speed Blitz {suffix}",
            description="Testing time decay multiplier",
            visibility="PUBLIC",
            time_per_question_seconds=30,
            scoring_mode="TIME_MULTIPLIER",
            time_limit_seconds=100,
            min_multiplier=0.5,
            decay=0.5,
            questions=[
                QuizQuestionCreate(
                    question_text="What is time complexity of binary search?",
                    options=["O(N)", "O(log N)", "O(1)", "O(N^2)"],
                    correct_option_index=1,
                    order_index=0,
                ),
                QuizQuestionCreate(
                    question_text="What is time complexity of quicksort average case?",
                    options=["O(N log N)", "O(N^2)", "O(log N)", "O(N)"],
                    correct_option_index=0,
                    order_index=1,
                ),
            ],
        )

        quiz = QuizService.create_quiz(self.db, teacher.id, quiz_data)
        self.assertEqual(quiz.scoring_mode, "TIME_MULTIPLIER")
        self.assertEqual(quiz.time_limit_seconds, 100)

        q1_id = quiz.questions[0].id
        q2_id = quiz.questions[1].id

        # 1. Fast Student finishes in 10s (10% of time)
        fast_submit = QuizSubmitRequest(
            answers=[
                QuizAnswerItem(question_id=q1_id, selected_index=1, time_taken_seconds=5),
                QuizAnswerItem(question_id=q2_id, selected_index=0, time_taken_seconds=5),
            ]
        )
        fast_res = QuizService.submit_quiz(self.db, quiz.id, fast_student.id, fast_submit)
        self.assertAlmostEqual(fast_res.multiplier_applied, 0.95, places=2)
        self.assertEqual(fast_res.final_score, int(round(fast_res.raw_score * 0.95)))

        # 2. Slow Student finishes in 90s (90% of time)
        slow_submit = QuizSubmitRequest(
            answers=[
                QuizAnswerItem(question_id=q1_id, selected_index=1, time_taken_seconds=45),
                QuizAnswerItem(question_id=q2_id, selected_index=0, time_taken_seconds=45),
            ]
        )
        slow_res = QuizService.submit_quiz(self.db, quiz.id, slow_student.id, slow_submit)
        self.assertAlmostEqual(slow_res.multiplier_applied, 0.55, places=2)
        self.assertEqual(slow_res.final_score, int(round(slow_res.raw_score * 0.55)))

        # Assert fast student final score > slow student final score
        self.assertGreater(fast_res.final_score, slow_res.final_score)

        # 3. Late submitter (> 100 * 1.25 = 125s, e.g. 130s total) should be rejected with 400
        late_submit = QuizSubmitRequest(
            answers=[
                QuizAnswerItem(question_id=q1_id, selected_index=1, time_taken_seconds=70),
                QuizAnswerItem(question_id=q2_id, selected_index=0, time_taken_seconds=60),
            ]
        )
        with self.assertRaises(HTTPException) as ctx:
            QuizService.submit_quiz(self.db, quiz.id, late_student.id, late_submit)
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertIn("Quiz time limit", ctx.exception.detail)

        # 4. Verify Leaderboard ranks fast student (#1) above slow student (#2)
        leaderboard = QuizService.get_quiz_leaderboard(self.db, quiz.id, fast_student)
        self.assertGreaterEqual(len(leaderboard), 2)
        self.assertEqual(leaderboard[0].student_id, fast_student.id)
        self.assertEqual(leaderboard[0].final_score, fast_res.final_score)
        self.assertEqual(leaderboard[1].student_id, slow_student.id)
        self.assertEqual(leaderboard[1].final_score, slow_res.final_score)


if __name__ == "__main__":
    unittest.main()
