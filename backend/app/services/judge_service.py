from datetime import datetime, timezone
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import desc, select
from sqlalchemy.orm import Session, selectinload

from app.models.lesson import Lesson
from app.models.problem import Problem
from app.models.submission import Submission
from app.models.test_case import TestCase
from app.schemas.problem import (
    ProblemDetailResponse,
    PublicTestCaseResponse,
    SubmissionResultResponse,
    SubmissionSummaryResponse,
    TestCaseExecutionResult,
    TrialResultResponse,
)
from app.services.code_execution.executor_factory import get_executor
from app.services.course_service import CourseService


class JudgeService:

    @staticmethod
    def get_problem_by_lesson_slug(
        db: Session,
        lesson_slug: str,
    ) -> ProblemDetailResponse:
        lesson = (
            db.execute(select(Lesson).where(Lesson.slug == lesson_slug))
            .scalars()
            .first()
        )

        if not lesson and lesson_slug == "remove-duplicates":
            lesson = (
                db.execute(select(Lesson).where(Lesson.slug == "remove-duplicates-sorted-array"))
                .scalars()
                .first()
            )

        if not lesson:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Lesson with slug '{lesson_slug}' not found.",
            )

        problem = (
            db.execute(
                select(Problem)
                .where(Problem.lesson_id == lesson.id)
                .options(
                    selectinload(Problem.test_cases),
                )
            )
            .scalars()
            .first()
        )

        if not problem:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"No interactive coding problem associated with lesson '{lesson_slug}'.",
            )

        public_tcs = [
            PublicTestCaseResponse(
                id=tc.id,
                stdin_input=tc.stdin_input,
                expected_stdout=tc.expected_stdout,
                order_index=tc.order_index,
            )
            for tc in problem.test_cases
            if not tc.is_hidden
        ]

        return ProblemDetailResponse(
            id=problem.id,
            lesson_id=problem.lesson_id,
            lesson_slug=lesson.slug,
            title=problem.title,
            description=problem.description,
            function_name=problem.function_name,
            starter_code_python=problem.starter_code_python,
            starter_code_java=problem.starter_code_java,
            starter_code_cpp=problem.starter_code_cpp,
            time_limit_ms=problem.time_limit_ms,
            memory_limit_mb=problem.memory_limit_mb,
            public_test_cases=public_tcs,
        )

    @staticmethod
    def run_trial(
        db: Session,
        problem_id: UUID,
        code: str,
        language: str,
    ) -> TrialResultResponse:
        """Run solution trial against public test cases only (No DB record created)."""
        problem = (
            db.execute(
                select(Problem)
                .where(Problem.id == problem_id)
                .options(selectinload(Problem.test_cases))
            )
            .scalars()
            .first()
        )

        if not problem:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Problem with ID '{problem_id}' not found.",
            )

        public_tcs = [tc for tc in problem.test_cases if not tc.is_hidden]
        if not public_tcs:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Problem has no public test cases configured.",
            )

        executor = get_executor()
        test_results: list[TestCaseExecutionResult] = []
        passed_count = 0
        total_time_ms = 0
        max_memory_kb = 0
        final_verdict = "AC"
        compile_output = None

        for idx, tc in enumerate(public_tcs, start=1):
            exec_res = executor.execute(
                source_code=code,
                language=language,
                stdin_input=tc.stdin_input,
                time_limit_ms=problem.time_limit_ms,
                memory_limit_mb=problem.memory_limit_mb,
            )

            total_time_ms += exec_res.execution_time_ms
            max_memory_kb = max(max_memory_kb, exec_res.memory_used_kb)

            if exec_res.compile_error:
                final_verdict = "CE"
                compile_output = exec_res.stderr
                test_results.append(
                    TestCaseExecutionResult(
                        test_index=idx,
                        is_hidden=False,
                        passed=False,
                        stdin_input=tc.stdin_input,
                        expected_stdout=tc.expected_stdout,
                        actual_output=None,
                        execution_time_ms=exec_res.execution_time_ms,
                        error_message=exec_res.stderr,
                    )
                )
                break

            if exec_res.timed_out:
                final_verdict = "TLE"
                test_results.append(
                    TestCaseExecutionResult(
                        test_index=idx,
                        is_hidden=False,
                        passed=False,
                        stdin_input=tc.stdin_input,
                        expected_stdout=tc.expected_stdout,
                        actual_output=None,
                        execution_time_ms=exec_res.execution_time_ms,
                        error_message="Time Limit Exceeded",
                    )
                )
                break

            if exec_res.exit_code != 0:
                final_verdict = "RE"
                test_results.append(
                    TestCaseExecutionResult(
                        test_index=idx,
                        is_hidden=False,
                        passed=False,
                        stdin_input=tc.stdin_input,
                        expected_stdout=tc.expected_stdout,
                        actual_output=exec_res.stdout,
                        execution_time_ms=exec_res.execution_time_ms,
                        error_message=exec_res.stderr or "Runtime Error",
                    )
                )
                break

            # Compare stdout (trimmed of trailing whitespace)
            clean_actual = exec_res.stdout.strip()
            clean_expected = tc.expected_stdout.strip()

            if clean_actual == clean_expected:
                passed_count += 1
                test_results.append(
                    TestCaseExecutionResult(
                        test_index=idx,
                        is_hidden=False,
                        passed=True,
                        stdin_input=tc.stdin_input,
                        expected_stdout=tc.expected_stdout,
                        actual_output=clean_actual,
                        execution_time_ms=exec_res.execution_time_ms,
                        error_message=None,
                    )
                )
            else:
                final_verdict = "WA"
                test_results.append(
                    TestCaseExecutionResult(
                        test_index=idx,
                        is_hidden=False,
                        passed=False,
                        stdin_input=tc.stdin_input,
                        expected_stdout=tc.expected_stdout,
                        actual_output=clean_actual,
                        execution_time_ms=exec_res.execution_time_ms,
                        error_message="Wrong Answer",
                    )
                )

        return TrialResultResponse(
            verdict=final_verdict,
            passed_count=passed_count,
            total_count=len(public_tcs),
            execution_time_ms=total_time_ms,
            memory_used_kb=max_memory_kb,
            test_results=test_results,
            compile_output=compile_output,
        )

    @staticmethod
    def submit_solution(
        db: Session,
        student_id: UUID,
        problem_id: UUID,
        code: str,
        language: str,
    ) -> SubmissionResultResponse:
        """Submit code solution against ALL test cases (public + hidden) and auto-complete lesson on AC."""
        problem = (
            db.execute(
                select(Problem)
                .where(Problem.id == problem_id)
                .options(selectinload(Problem.test_cases))
            )
            .scalars()
            .first()
        )

        if not problem:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Problem with ID '{problem_id}' not found.",
            )

        all_tcs = list(problem.test_cases)
        if not all_tcs:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Problem has no test cases configured.",
            )

        executor = get_executor()
        passed_count = 0
        total_time_ms = 0
        max_memory_kb = 0
        final_verdict = "AC"
        failed_test_index = None
        error_message = None
        actual_output = None

        for idx, tc in enumerate(all_tcs, start=1):
            exec_res = executor.execute(
                source_code=code,
                language=language,
                stdin_input=tc.stdin_input,
                time_limit_ms=problem.time_limit_ms,
                memory_limit_mb=problem.memory_limit_mb,
            )

            total_time_ms += exec_res.execution_time_ms
            max_memory_kb = max(max_memory_kb, exec_res.memory_used_kb)

            if exec_res.compile_error:
                final_verdict = "CE"
                failed_test_index = idx
                error_message = exec_res.stderr
                break

            if exec_res.timed_out:
                final_verdict = "TLE"
                failed_test_index = idx
                error_message = "Time Limit Exceeded"
                break

            if exec_res.exit_code != 0:
                final_verdict = "RE"
                failed_test_index = idx
                error_message = exec_res.stderr or "Runtime Error"
                actual_output = exec_res.stdout if not tc.is_hidden else None
                break

            clean_actual = exec_res.stdout.strip()
            clean_expected = tc.expected_stdout.strip()

            if clean_actual == clean_expected:
                passed_count += 1
            else:
                final_verdict = "WA"
                failed_test_index = idx
                error_message = "Wrong Answer"
                actual_output = clean_actual if not tc.is_hidden else None
                break

        # Save Submission record
        submission = Submission(
            student_id=student_id,
            problem_id=problem.id,
            code=code,
            language=language.lower(),
            verdict=final_verdict,
            execution_time_ms=total_time_ms,
            memory_used_kb=max_memory_kb,
            passed_count=passed_count,
            total_count=len(all_tcs),
            failed_test_index=failed_test_index,
            actual_output=actual_output,
            error_message=error_message,
            created_at=datetime.now(timezone.utc),
        )
        db.add(submission)
        db.commit()
        db.refresh(submission)

        # If AC -> Auto-complete lesson and award badges!
        is_lesson_completed = False
        if final_verdict == "AC":
            CourseService.complete_lesson(
                db=db,
                student_id=student_id,
                lesson_id=problem.lesson_id,
            )
            is_lesson_completed = True

            from app.services.badge_service import BadgeService
            BadgeService.award_badge_if_eligible(db, student_id, "FIRST_PROBLEM_SOLVED")

            # Check if solved in 2+ distinct languages
            distinct_langs = db.scalars(
                select(Submission.language)
                .where(
                    Submission.student_id == student_id,
                    Submission.verdict == "AC",
                )
                .distinct()
            ).all()
            if len(set(distinct_langs)) >= 2:
                BadgeService.award_badge_if_eligible(db, student_id, "MULTILANG_CODER")

        message = (
            "Accepted! All test cases passed."
            if final_verdict == "AC"
            else f"Submission verdict: {final_verdict} ({passed_count}/{len(all_tcs)} test cases passed)."
        )

        return SubmissionResultResponse(
            submission_id=submission.id,
            verdict=final_verdict,
            passed_count=passed_count,
            total_count=len(all_tcs),
            execution_time_ms=total_time_ms,
            memory_used_kb=max_memory_kb,
            failed_test_index=failed_test_index,
            message=message,
            is_lesson_completed=is_lesson_completed,
        )

    @staticmethod
    def get_submissions(
        db: Session,
        student_id: UUID,
        problem_id: UUID,
    ) -> list[SubmissionSummaryResponse]:
        """Fetch all submissions made by student for a given problem."""
        submissions = (
            db.execute(
                select(Submission)
                .where(
                    Submission.student_id == student_id,
                    Submission.problem_id == problem_id,
                )
                .order_by(desc(Submission.created_at))
            )
            .scalars()
            .all()
        )

        return [
            SubmissionSummaryResponse(
                id=s.id,
                problem_id=s.problem_id,
                language=s.language,
                verdict=s.verdict,
                execution_time_ms=s.execution_time_ms,
                memory_used_kb=s.memory_used_kb,
                passed_count=s.passed_count,
                total_count=s.total_count,
                created_at=s.created_at,
            )
            for s in submissions
        ]
