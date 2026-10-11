import unittest
from uuid import uuid4
from sqlalchemy import select

from app.db.session import SessionLocal
from app.models.course import Course
from app.models.course_module import CourseModule
from app.models.lesson import Lesson
from app.schemas.courses import LessonSnippetUpdateRequest
from app.services.course_service import CourseService


class TestMultiLanguageVisualization(unittest.TestCase):
    def setUp(self):
        self.db = SessionLocal()

    def tearDown(self):
        self.db.close()

    def test_normalize_visualization_content(self):
        # 1. Single snippet without code_snippets map
        raw_content = {
            "algorithm_name": "linearSearch",
            "code_snippet": "def linear_search(): pass",
            "line_map": {"1": 1, "2": 2},
        }
        normalized = CourseService.normalize_visualization_content(raw_content)
        self.assertIn("code_snippets", normalized)
        self.assertEqual(normalized["code_snippets"]["python"], "def linear_search(): pass")
        self.assertEqual(normalized["default_language"], "python")
        self.assertIn("line_maps", normalized)
        self.assertEqual(normalized["line_maps"]["python"], {"1": 1, "2": 2})

    def test_authoring_and_serialization_of_multi_language_snippets(self):
        suffix = uuid4().hex[:6]
        course = Course(
            title=f"Multi-Lang Course {suffix}",
            slug=f"multi-lang-course-{suffix}",
            description="Testing multi language snippets",
            difficulty="BEGINNER",
            topic_category="ARRAYS",
            is_published=True,
        )
        module = CourseModule(
            course=course,
            title="Module 1",
            order_index=1,
        )
        lesson = Lesson(
            module=module,
            title="Search Lesson",
            slug=f"search-lesson-{suffix}",
            content_type="VISUALIZATION",
            content_json={
                "algorithm_name": "linearSearch",
                "code_snippet": "def search(): pass",
            },
            order_index=1,
            estimated_minutes=15,
        )
        self.db.add_all([course, module, lesson])
        self.db.commit()

        # Update snippets via authoring service
        update_payload = LessonSnippetUpdateRequest(
            code_snippets={
                "python": "def search(arr): pass",
                "java": "int search(int[] arr) { return 0; }",
                "cpp": "int search(vector<int>& arr) { return 0; }",
            },
            line_maps={
                "python": {"1": 1},
                "java": {"1": 1},
            },
            default_language="python",
        )
        updated_res = CourseService.update_lesson_snippets(self.db, lesson.id, update_payload)
        self.assertEqual(len(updated_res.content_json["code_snippets"]), 3)
        self.assertEqual(updated_res.content_json["default_language"], "python")

        # Fetch course detail and ensure serialization includes code_snippets and default_language
        detail = CourseService.get_course_detail(self.db, course.slug)
        lesson_out = detail.modules[0].lessons[0]
        self.assertEqual(lesson_out.content_json["default_language"], "python")
        self.assertIn("java", lesson_out.content_json["code_snippets"])
        self.assertIn("cpp", lesson_out.content_json["code_snippets"])


if __name__ == "__main__":
    unittest.main()
