import time
from typing import Any
from uuid import UUID
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.core.config import settings
from app.models.lesson import Lesson
from app.models.course import Course
from app.models.course_module import CourseModule
from app.models.course_enrollment import CourseEnrollment
from app.models.lesson_completion import LessonCompletion
from app.models.submission import Submission
from app.models.problem import Problem
from app.schemas.ai_tutor import RecommendationItem, AIStatusResponse


SOCRATIC_HINT_SYSTEM_PROMPT = """You are a Socratic DSA tutor for the AlgoVerse platform.

RULES:
1. NEVER reveal the complete solution or full code.
2. NEVER write code for the student.
3. Guide with questions and incremental hints.
4. Reference the specific visualization state when relevant.
5. Keep responses under 150 words.
6. Use simple language appropriate for undergraduate students.

HINT LEVELS:
- Level 1: Ask a guiding question about the current step.
  Example: "Look at pointer i in the visualization. What value is arr[i] at this step, and how does it compare to the target?"
- Level 2: Point to the specific concept or line causing trouble.
  Example: "Your loop condition on line 3 checks i < len(arr), but notice in the visualization that the right pointer is already at index 2. What should the stopping condition be?"
- Level 3: Reveal the approach without code.
  Example: "Try using two pointers — one starting from the left and one from the right. Move them inward until they meet, swapping elements at each step."
"""

ERROR_EXPLAINER_SYSTEM_PROMPT = """You are a DSA error explainer for the AlgoVerse platform. Analyze the student's code and the failed test case. Explain WHAT went wrong and WHY, but do NOT provide the corrected code. Point to the specific line or logic that caused the wrong output. Keep under 100 words."""

FALLBACK_MESSAGE = "AI mentorship is not configured. Please ask your teacher for help."


class AITutorService:
    # Note: In-memory dictionary rate limiter resets when the server process restarts.
    # This is suitable for development and demonstration; a production deployment would use Redis.
    _rate_limit_history: dict[UUID, list[float]] = {}
    _hints_used_per_lesson: dict[tuple[UUID, UUID], int] = {}

    @classmethod
    def is_configured(cls) -> bool:
        """Check if AI provider is enabled and a valid API key is present."""
        if not settings.AI_PROVIDER or settings.AI_PROVIDER.lower() == "disabled":
            return False
        key = (settings.AI_API_KEY or "").strip()
        if not key or key in ("your_api_key_here", "none", "placeholder"):
            return False
        return True

    @classmethod
    def get_status(cls) -> AIStatusResponse:
        configured = cls.is_configured()
        provider = settings.AI_PROVIDER or "disabled"
        model = settings.AI_MODEL or "default"
        if configured:
            message = f"AI Tutor active using {provider.capitalize()} ({model})."
        else:
            message = FALLBACK_MESSAGE
        return AIStatusResponse(
            configured=configured,
            provider=provider,
            model=model,
            message=message,
        )

    @classmethod
    def _check_rate_limit(cls, student_id: UUID) -> bool:
        """Enforce AI_RATE_LIMIT_PER_MINUTE requests per minute per student."""
        now = time.time()
        window = 60.0  # 1 minute
        history = cls._rate_limit_history.setdefault(student_id, [])
        # Prune older than 1 minute
        cls._rate_limit_history[student_id] = [t for t in history if now - t < window]
        if len(cls._rate_limit_history[student_id]) >= settings.AI_RATE_LIMIT_PER_MINUTE:
            return False
        cls._rate_limit_history[student_id].append(now)
        return True

    @classmethod
    def _get_hints_remaining(cls, student_id: UUID, lesson_id: UUID) -> int:
        used = cls._hints_used_per_lesson.get((student_id, lesson_id), 0)
        return max(0, settings.AI_MAX_HINTS_PER_LESSON - used)

    @classmethod
    def _record_hint_used(cls, student_id: UUID, lesson_id: UUID) -> None:
        key = (student_id, lesson_id)
        cls._hints_used_per_lesson[key] = cls._hints_used_per_lesson.get(key, 0) + 1

    @classmethod
    def _call_llm(cls, system_prompt: str, user_prompt: str) -> str:
        """Execute the LLM call using configured provider (Gemini or OpenAI)."""
        provider = (settings.AI_PROVIDER or "").lower()
        if provider == "gemini":
            import google.generativeai as genai
            genai.configure(api_key=settings.AI_API_KEY)
            model = genai.GenerativeModel(
                model_name=settings.AI_MODEL or "gemini-1.5-flash",
                system_instruction=system_prompt,
                generation_config={"temperature": 0.4},
            )
            response = model.generate_content(user_prompt)
            if response and response.text:
                return response.text.strip()
            return "Unable to generate a hint at this moment. Please try again."

        elif provider == "openai":
            import openai
            client = openai.OpenAI(api_key=settings.AI_API_KEY)
            response = client.chat.completions.create(
                model=settings.AI_MODEL or "gpt-4o-mini",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=0.4,
            )
            if response.choices and response.choices[0].message.content:
                return response.choices[0].message.content.strip()
            return "Unable to generate a hint at this moment. Please try again."

        return FALLBACK_MESSAGE

    @classmethod
    def get_hint(
        cls,
        db: Session,
        student_id: UUID,
        lesson_id: UUID,
        hint_level: int,
        visualization_state: dict[str, Any] | None = None,
        code: str | None = None,
        error_info: str | None = None,
    ) -> tuple[str, int]:
        """Generate a contextual, Socratic hint grounded in visualization state or code."""
        remaining = cls._get_hints_remaining(student_id, lesson_id)

        if not cls._check_rate_limit(student_id):
            return "Please wait a moment before requesting another hint.", remaining

        if remaining <= 0:
            return (
                "You've used all hints for this lesson. Try revisiting the visualization or asking your teacher.",
                0,
            )

        if not cls.is_configured():
            return FALLBACK_MESSAGE, remaining

        # Retrieve lesson details
        lesson = db.query(Lesson).filter(Lesson.id == lesson_id).first()
        lesson_title = lesson.title if lesson else "Current Lesson"
        lesson_type = lesson.content_type.value if lesson and lesson.content_type else "VISUALIZATION"

        # Construct contextual prompt
        prompt_parts = [
            f"Lesson: {lesson_title} (Type: {lesson_type})",
            f"Requested Hint Level: Level {hint_level}",
        ]

        if visualization_state:
            prompt_parts.append(
                f"Current Visualization Step State: {visualization_state}"
            )
        if code:
            prompt_parts.append(f"Student's Current Code:\n```\n{code}\n```")
        if error_info:
            prompt_parts.append(f"Submission / Test Error Details: {error_info}")

        user_prompt = "\n\n".join(prompt_parts)

        try:
            hint_text = cls._call_llm(SOCRATIC_HINT_SYSTEM_PROMPT, user_prompt)
            cls._record_hint_used(student_id, lesson_id)
            new_remaining = cls._get_hints_remaining(student_id, lesson_id)
            return hint_text, new_remaining
        except Exception as e:
            return f"Error communicating with AI tutor: {str(e)}", remaining

    @classmethod
    def explain_error(
        cls,
        db: Session,
        student_id: UUID,
        submission_id: UUID,
    ) -> tuple[str, str | None]:
        """Explain a submission error without providing the full solution code."""
        if not cls._check_rate_limit(student_id):
            return "Please wait a moment before requesting another explanation.", None

        if not cls.is_configured():
            return FALLBACK_MESSAGE, None

        submission = (
            db.query(Submission)
            .filter(Submission.id == submission_id, Submission.student_id == student_id)
            .first()
        )
        if not submission:
            return "Submission not found or unauthorized.", None

        problem = submission.problem
        problem_title = problem.title if problem else "Problem"
        problem_desc = problem.description if problem else ""

        failed_summary = (
            f"Verdict: {submission.verdict} | Passed: {submission.passed_count}/{submission.total_count} tests"
        )
        if submission.error_message:
            failed_summary += f" | Error: {submission.error_message}"
        elif submission.actual_output:
            failed_summary += f" | Output: {submission.actual_output}"

        user_prompt = (
            f"Problem: {problem_title}\n"
            f"Description: {problem_desc}\n"
            f"Language: {submission.language}\n"
            f"Verdict: {submission.verdict}\n"
            f"Failed Summary: {failed_summary}\n\n"
            f"Student's Code:\n```\n{submission.code}\n```\n\n"
            "Explain the bug clearly and what caused the incorrect result."
        )

        try:
            explanation = cls._call_llm(ERROR_EXPLAINER_SYSTEM_PROMPT, user_prompt)
            return explanation, failed_summary
        except Exception as e:
            return f"Error communicating with AI tutor: {str(e)}", failed_summary

    @classmethod
    def recommend_next(
        cls,
        db: Session,
        student_id: UUID,
    ) -> list[RecommendationItem]:
        """Recommend 3 targeted lessons based on weak areas, failed submissions, and syllabus progress."""
        recommendations: list[RecommendationItem] = []

        # 1. Check recent failed submissions
        failed_subs = (
            db.query(Submission)
            .filter(
                Submission.student_id == student_id,
                Submission.verdict != "AC",
            )
            .order_by(Submission.created_at.desc())
            .limit(5)
            .all()
        )

        completed_lesson_ids = {
            c.lesson_id
            for c in db.query(LessonCompletion)
            .filter(LessonCompletion.student_id == student_id)
            .all()
        }

        # Priority 1: Failed problem lessons not yet completed
        for sub in failed_subs:
            if sub.problem and sub.problem.lesson_id not in completed_lesson_ids:
                lesson = db.query(Lesson).filter(Lesson.id == sub.problem.lesson_id).first()
                if lesson:
                    module = lesson.module
                    course = module.course if module else None
                    recommendations.append(
                        RecommendationItem(
                            lesson_id=lesson.id,
                            lesson_title=lesson.title,
                            course_title=course.title if course else "DSA Course",
                            reason=f"You had trouble with {sub.verdict} on this problem — revisit and refine your logic!",
                            priority="high",
                        )
                    )
                    if len(recommendations) >= 3:
                        return recommendations

        # Priority 2: Next incomplete lesson in enrolled courses
        enrollments = (
            db.query(CourseEnrollment)
            .filter(CourseEnrollment.student_id == student_id)
            .all()
        )
        for enrollment in enrollments:
            course = enrollment.course
            if not course:
                continue
            for module in course.modules:
                for lesson in module.lessons:
                    if lesson.id not in completed_lesson_ids:
                        # Avoid duplicates
                        if not any(r.lesson_id == lesson.id for r in recommendations):
                            recommendations.append(
                                RecommendationItem(
                                    lesson_id=lesson.id,
                                    lesson_title=lesson.title,
                                    course_title=course.title,
                                    reason=f"Next recommended step in your {course.title} learning roadmap",
                                    priority="medium" if len(recommendations) > 0 else "high",
                                )
                            )
                        if len(recommendations) >= 3:
                            return recommendations

        # Priority 3: Fallback introductory lessons if catalog has unattempted lessons
        all_lessons = (
            db.query(Lesson)
            .join(CourseModule, Lesson.module_id == CourseModule.id)
            .join(Course, CourseModule.course_id == Course.id)
            .order_by(CourseModule.order_index, Lesson.order_index)
            .limit(10)
            .all()
        )
        for lesson in all_lessons:
            if lesson.id not in completed_lesson_ids and not any(r.lesson_id == lesson.id for r in recommendations):
                course = lesson.module.course if lesson.module else None
                recommendations.append(
                    RecommendationItem(
                        lesson_id=lesson.id,
                        lesson_title=lesson.title,
                        course_title=course.title if course else "DSA Course",
                        reason="Explore this fundamental algorithm to strengthen your core concepts",
                        priority="low",
                    )
                )
            if len(recommendations) >= 3:
                break

        return recommendations
