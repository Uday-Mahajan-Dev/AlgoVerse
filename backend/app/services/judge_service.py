from datetime import datetime, timezone
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import desc, func, select
from sqlalchemy.orm import Session, selectinload

from app.models.assignment import Assignment
from app.models.custom_problem import CustomProblem
from app.models.custom_problem_completion import CustomProblemCompletion
from app.models.lesson import Lesson
from app.models.lesson_completion import LessonCompletion
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
                explanation=tc.explanation,
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
    async def run_trial(
        db: Session,
        problem_id: UUID,
        code: str,
        language: str,
    ) -> TrialResultResponse:
        """Run solution trial against public test cases concurrently (No DB record created)."""
        problem = (
            db.execute(
                select(Problem)
                .where(Problem.id == problem_id)
                .options(selectinload(Problem.test_cases))
            )
            .scalars()
            .first()
        )

        custom_problem = None
        if not problem:
            custom_problem = db.scalar(select(CustomProblem).where(CustomProblem.id == problem_id))

        if not problem and not custom_problem:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Custom problem not found" if not problem else f"Problem with ID '{problem_id}' not found.",
            )

        public_tcs = []
        time_limit_ms = 5000
        memory_limit_mb = 256

        if problem:
            public_tcs = [
                {"input": tc.stdin_input, "expected": tc.expected_stdout}
                for tc in problem.test_cases
                if not tc.is_hidden
            ]
            time_limit_ms = problem.time_limit_ms
            memory_limit_mb = problem.memory_limit_mb
        elif custom_problem:
            raw_tcs = custom_problem.test_cases or getattr(custom_problem, 'test_cases_json', None) or []
            public_tcs = [
                {
                    "input": tc.get("input", "") if isinstance(tc, dict) else getattr(tc, "stdin_input", ""),
                    "expected": tc.get("expected", "") if isinstance(tc, dict) else getattr(tc, "expected_stdout", ""),
                }
                for tc in raw_tcs
                if not (tc.get("is_hidden", False) if isinstance(tc, dict) else getattr(tc, "is_hidden", False))
            ]
            # Fallback: if all test cases were marked hidden or none were flagged public, allow all for trial
            if not public_tcs and raw_tcs:
                public_tcs = [
                    {
                        "input": tc.get("input", "") if isinstance(tc, dict) else getattr(tc, "stdin_input", ""),
                        "expected": tc.get("expected", "") if isinstance(tc, dict) else getattr(tc, "expected_stdout", ""),
                    }
                    for tc in raw_tcs
                ]

        if not public_tcs:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No test cases are defined for this custom problem." if custom_problem else "Problem has no public test cases configured.",
            )

        executor = get_executor()
        test_inputs = [tc["input"] for tc in public_tcs]
        exec_results = await executor.execute_batch_async(
            source_code=code,
            language=language,
            test_inputs=test_inputs,
            time_limit_ms=time_limit_ms,
            memory_limit_mb=memory_limit_mb,
        )

        test_results: list[TestCaseExecutionResult] = []
        passed_count = 0
        total_time_ms = 0
        max_memory_kb = 0
        final_verdict = "AC"
        compile_output = None

        for idx, (tc, exec_res) in enumerate(zip(public_tcs, exec_results), start=1):
            input_val = tc["input"]
            expected_val = tc["expected"]

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
                        stdin_input=input_val,
                        expected_stdout=expected_val,
                        actual_output=None,
                        execution_time_ms=exec_res.execution_time_ms,
                        error_message=exec_res.stderr,
                    )
                )
                break

            if exec_res.timed_out:
                if final_verdict == "AC":
                    final_verdict = "TLE"
                test_results.append(
                    TestCaseExecutionResult(
                        test_index=idx,
                        is_hidden=False,
                        passed=False,
                        stdin_input=input_val,
                        expected_stdout=expected_val,
                        actual_output=None,
                        execution_time_ms=exec_res.execution_time_ms,
                        error_message="Time Limit Exceeded",
                    )
                )
                continue

            if exec_res.exit_code != 0:
                if final_verdict == "AC":
                    final_verdict = "RE"
                test_results.append(
                    TestCaseExecutionResult(
                        test_index=idx,
                        is_hidden=False,
                        passed=False,
                        stdin_input=input_val,
                        expected_stdout=expected_val,
                        actual_output=exec_res.stdout,
                        execution_time_ms=exec_res.execution_time_ms,
                        error_message=exec_res.stderr or "Runtime Error",
                    )
                )
                continue

            # Compare stdout (trimmed of trailing whitespace)
            clean_actual = exec_res.stdout.strip()
            clean_expected = expected_val.strip()

            if clean_actual == clean_expected:
                passed_count += 1
                test_results.append(
                    TestCaseExecutionResult(
                        test_index=idx,
                        is_hidden=False,
                        passed=True,
                        stdin_input=input_val,
                        expected_stdout=expected_val,
                        actual_output=clean_actual,
                        execution_time_ms=exec_res.execution_time_ms,
                        error_message=None,
                    )
                )
            else:
                if final_verdict == "AC":
                    final_verdict = "WA"
                test_results.append(
                    TestCaseExecutionResult(
                        test_index=idx,
                        is_hidden=False,
                        passed=False,
                        stdin_input=input_val,
                        expected_stdout=expected_val,
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
    async def submit_solution(
        db: Session,
        student_id: UUID,
        problem_id: UUID,
        code: str,
        language: str,
    ) -> SubmissionResultResponse:
        """Submit code solution against ALL test cases concurrently and auto-complete lesson/custom assignment on AC."""
        problem = (
            db.execute(
                select(Problem)
                .where(Problem.id == problem_id)
                .options(selectinload(Problem.test_cases))
            )
            .scalars()
            .first()
        )

        custom_problem = None
        if not problem:
            custom_problem = db.scalar(select(CustomProblem).where(CustomProblem.id == problem_id))

        if not problem and not custom_problem:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Custom problem not found" if not problem else f"Problem with ID '{problem_id}' not found.",
            )

        all_tcs = []
        time_limit_ms = 5000
        memory_limit_mb = 256

        if problem:
            all_tcs = [
                {"input": tc.stdin_input, "expected": tc.expected_stdout, "is_hidden": tc.is_hidden}
                for tc in problem.test_cases
            ]
            time_limit_ms = problem.time_limit_ms
            memory_limit_mb = problem.memory_limit_mb
        elif custom_problem:
            raw_tcs = custom_problem.test_cases or getattr(custom_problem, 'test_cases_json', None) or []
            all_tcs = [
                {
                    "input": tc.get("input", "") if isinstance(tc, dict) else getattr(tc, "stdin_input", ""),
                    "expected": tc.get("expected", "") if isinstance(tc, dict) else getattr(tc, "expected_stdout", ""),
                    "is_hidden": tc.get("is_hidden", False) if isinstance(tc, dict) else getattr(tc, "is_hidden", False),
                }
                for tc in raw_tcs
            ]

        if not all_tcs:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No test cases are defined for this custom problem." if custom_problem else "Problem has no test cases configured.",
            )

        executor = get_executor()
        test_inputs = [tc["input"] for tc in all_tcs]
        exec_results = await executor.execute_batch_async(
            source_code=code,
            language=language,
            test_inputs=test_inputs,
            time_limit_ms=time_limit_ms,
            memory_limit_mb=memory_limit_mb,
        )

        passed_count = 0
        total_time_ms = 0
        max_memory_kb = 0
        final_verdict = "AC"
        failed_test_index = None
        error_message = None
        actual_output = None

        for idx, (tc, exec_res) in enumerate(zip(all_tcs, exec_results), start=1):
            input_val = tc["input"]
            expected_val = tc["expected"]
            is_hidden = tc.get("is_hidden", False)

            total_time_ms += exec_res.execution_time_ms
            max_memory_kb = max(max_memory_kb, exec_res.memory_used_kb)

            if exec_res.compile_error:
                if final_verdict == "AC":
                    final_verdict = "CE"
                    failed_test_index = idx
                    error_message = exec_res.stderr
                continue

            if exec_res.timed_out:
                if final_verdict == "AC":
                    final_verdict = "TLE"
                    failed_test_index = idx
                    error_message = "Time Limit Exceeded"
                continue

            if exec_res.exit_code != 0:
                if final_verdict == "AC":
                    final_verdict = "RE"
                    failed_test_index = idx
                    error_message = exec_res.stderr or "Runtime Error"
                    actual_output = exec_res.stdout if not is_hidden else None
                continue

            clean_actual = exec_res.stdout.strip()
            clean_expected = expected_val.strip()

            if clean_actual == clean_expected:
                passed_count += 1
            else:
                if final_verdict == "AC":
                    final_verdict = "WA"
                    failed_test_index = idx
                    error_message = "Wrong Answer"
                    actual_output = clean_actual if not is_hidden else None

        # Handle post-submission actions based on problem type
        is_lesson_completed = False
        sub_id = None
        xp_awarded = 0
        already_completed = False
        is_first_ac = False

        if problem:
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
            sub_id = submission.id

            # If AC -> Auto-complete lesson and award badges!
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

        elif custom_problem:
            existing_completion = db.scalar(
                select(CustomProblemCompletion).where(
                    CustomProblemCompletion.student_id == student_id,
                    CustomProblemCompletion.custom_problem_id == custom_problem.id,
                )
            )

            if existing_completion:
                already_completed = True

            completion_to_add = None
            if final_verdict == "AC":
                if not existing_completion:
                    is_first_ac = True
                    xp_awarded = 50
                    completion_to_add = CustomProblemCompletion(
                        student_id=student_id,
                        custom_problem_id=custom_problem.id,
                        xp_awarded=xp_awarded,
                        completed_at=datetime.now(timezone.utc),
                    )
                    db.add(completion_to_add)
                    db.flush()

            submission = Submission(
                student_id=student_id,
                problem_id=custom_problem.id,
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
                is_first_ac=is_first_ac,
                xp_awarded=xp_awarded,
                created_at=datetime.now(timezone.utc),
            )
            db.add(submission)
            db.commit()
            db.refresh(submission)
            sub_id = submission.id

            if is_first_ac and completion_to_add:
                completion_to_add.first_ac_submission_id = submission.id
                db.commit()

            if final_verdict == "AC":
                # Mark pending assignments as completed
                assignments = db.scalars(
                    select(Assignment).where(
                        Assignment.student_id == student_id,
                        Assignment.custom_problem_id == custom_problem.id,
                        Assignment.status == "pending",
                    )
                ).all()
                for a in assignments:
                    a.status = "completed"
                    a.completed_at = datetime.now(timezone.utc)
                if assignments:
                    db.commit()
                    from app.services.badge_service import BadgeService
                    BadgeService.award_badge_if_eligible(db, student_id, "HOMEWORK_COMPLETE")

                from app.services.badge_service import BadgeService
                BadgeService.award_badge_if_eligible(db, student_id, "FIRST_PROBLEM_SOLVED")

        # Compute dynamic student total XP
        lesson_count = db.scalar(
            select(func.count(LessonCompletion.id)).where(LessonCompletion.student_id == student_id)
        ) or 0
        custom_xp = db.scalar(
            select(func.sum(CustomProblemCompletion.xp_awarded)).where(CustomProblemCompletion.student_id == student_id)
        ) or 0
        total_xp = (lesson_count * 50) + int(custom_xp)

        message = (
            "Accepted! All test cases passed."
            if final_verdict == "AC"
            else f"Submission verdict: {final_verdict} ({passed_count}/{len(all_tcs)} test cases passed)."
        )

        return SubmissionResultResponse(
            submission_id=sub_id,
            verdict=final_verdict,
            passed_count=passed_count,
            total_count=len(all_tcs),
            execution_time_ms=total_time_ms,
            runtime_ms=total_time_ms,
            memory_used_kb=max_memory_kb,
            failed_test_index=failed_test_index,
            message=message,
            is_lesson_completed=is_lesson_completed,
            xp_awarded=xp_awarded,
            already_completed=already_completed,
            is_first_ac=is_first_ac,
            total_xp=total_xp,
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
