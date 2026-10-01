import unittest
import uuid
from unittest.mock import MagicMock, patch

from app.core.config import settings
from app.services.ai_tutor_service import (
    AITutorService,
    FALLBACK_MESSAGE,
    SOCRATIC_HINT_SYSTEM_PROMPT,
    ERROR_EXPLAINER_SYSTEM_PROMPT,
)
from app.schemas.ai_tutor import RecommendationItem


class TestAITutorService(unittest.TestCase):
    def setUp(self):
        AITutorService._rate_limit_history.clear()
        AITutorService._hints_used_per_lesson.clear()

    def test_unconfigured_fallback(self):
        """When AI is not configured or has placeholder key, return fallback message gracefully."""
        with patch.object(settings, "AI_API_KEY", "your_api_key_here"):
            self.assertFalse(AITutorService.is_configured())
            status = AITutorService.get_status()
            self.assertFalse(status.configured)
            self.assertEqual(status.message, FALLBACK_MESSAGE)

            db_mock = MagicMock()
            student_id = uuid.uuid4()
            lesson_id = uuid.uuid4()

            hint_text, remaining = AITutorService.get_hint(
                db=db_mock,
                student_id=student_id,
                lesson_id=lesson_id,
                hint_level=1,
            )
            self.assertEqual(hint_text, FALLBACK_MESSAGE)
            self.assertEqual(remaining, settings.AI_MAX_HINTS_PER_LESSON)

    def test_rate_limiting_per_minute(self):
        """Enforce rate limit of AI_RATE_LIMIT_PER_MINUTE per student."""
        student_id = uuid.uuid4()
        with patch.object(settings, "AI_RATE_LIMIT_PER_MINUTE", 2):
            self.assertTrue(AITutorService._check_rate_limit(student_id))
            self.assertTrue(AITutorService._check_rate_limit(student_id))
            # 3rd request in same minute should be rejected
            self.assertFalse(AITutorService._check_rate_limit(student_id))

    def test_hints_remaining_tracking(self):
        """Ensure hint count decrements and limits properly."""
        student_id = uuid.uuid4()
        lesson_id = uuid.uuid4()
        db_mock = MagicMock()

        with patch.object(settings, "AI_API_KEY", "test-valid-key"):
            with patch.object(AITutorService, "_call_llm", return_value="Here is a level 1 guiding question."):
                hint_text, remaining = AITutorService.get_hint(
                    db=db_mock,
                    student_id=student_id,
                    lesson_id=lesson_id,
                    hint_level=1,
                )
                self.assertEqual(hint_text, "Here is a level 1 guiding question.")
                self.assertEqual(remaining, settings.AI_MAX_HINTS_PER_LESSON - 1)

    def test_socratic_prompt_and_error_explainer(self):
        """Verify prompt templates enforce Socratic method and no solution leakage."""
        self.assertIn("NEVER reveal the complete solution", SOCRATIC_HINT_SYSTEM_PROMPT)
        self.assertIn("NEVER write code for the student", SOCRATIC_HINT_SYSTEM_PROMPT)
        self.assertIn("HINT LEVELS", SOCRATIC_HINT_SYSTEM_PROMPT)
        self.assertIn("DSA error explainer", ERROR_EXPLAINER_SYSTEM_PROMPT)
        self.assertIn("do NOT provide the corrected code", ERROR_EXPLAINER_SYSTEM_PROMPT)


if __name__ == "__main__":
    unittest.main()
