import json
import logging
import re
from uuid import UUID
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.assignment import Assignment
from app.models.custom_problem import CustomProblem
from app.models.custom_problem_completion import CustomProblemCompletion
from app.models.student_teacher import StudentTeacher
from app.models.submission import Submission
from app.models.teacher_profile import TeacherProfile
from app.models.user import User
from app.schemas.custom_problem import (
    CustomProblemCreate,
    CustomProblemUpdate,
    CustomProblemResponse,
    CustomProblemStatsResponse,
    CustomProblemSubmissionItem,
    CustomProblemSubmissionsResponse,
)
from app.services.ai_tutor_service import AITutorService
from app.services.badge_service import BadgeService
from app.services.notification_service import NotificationService

logger = logging.getLogger(__name__)



class CustomProblemService:

    @staticmethod
    def mask_test_cases_for_student(test_cases: list[dict[str, Any]]) -> list[dict[str, Any]]:
        sanitized = []
        for idx, tc in enumerate(test_cases, start=1):
            is_hidden = tc.get("is_hidden", True)
            if is_hidden:
                sanitized.append({
                    "test_index": idx,
                    "name": f"Hidden Test #{idx}",
                    "is_hidden": True,
                })
            else:
                sanitized.append({
                    "test_index": idx,
                    "name": f"Test Case #{idx}",
                    "input": tc.get("input", ""),
                    "expected": tc.get("expected", ""),
                    "is_hidden": False,
                    "explanation": tc.get("explanation", ""),
                })
        return sanitized

    @staticmethod
    def auto_generate_starter_codes(code: str, source_lang: str = "python") -> dict[str, str]:
        """
        Auto-generate starter code templates for Python, Java, and C++ from single teacher input.
        Uses AI (Gemini/OpenAI) if configured, with smart regex parser fallback.
        """
        clean_code = (code or "").strip()
        lang = (source_lang or "python").lower()

        # 1. Try AI Generation if configured
        if AITutorService.is_configured() and clean_code:
            system_prompt = (
                "You are an expert programming language template generator for algorithmic coding problems on AlgoVerse. "
                "Given a starter code skeleton in one language, generate standard, clean starter code templates for Python 3, Java, and C++. "
                "Output ONLY a raw, valid JSON object with exact keys: 'python', 'java', 'cpp'. "
                "Rules:\n"
                "- Do NOT implement full solutions.\n"
                "- Include standard I/O (Scanner in Java, cin/cout in C++, input/sys.stdin in Python) or matching function skeletons.\n"
                "- Java must use 'public class Main' with a public static void main(String[] args) method.\n"
                "- C++ must use #include <iostream>, using namespace std;, and int main().\n"
                "- Python must include standard def solve()/def solution() with if __name__ == '__main__': entry point."
            )
            user_prompt = f"Source Language: {lang}\nStarter Code:\n{clean_code}\n\nGenerate equivalent starter code templates for Python, Java, and C++. Output valid JSON only."
            try:
                ai_resp = AITutorService._call_llm(system_prompt, user_prompt)
                if ai_resp and "{" in ai_resp:
                    json_str = ai_resp
                    if "```json" in json_str:
                        json_str = json_str.split("```json")[1].split("```")[0].strip()
                    elif "```" in json_str:
                        json_str = json_str.split("```")[1].split("```")[0].strip()

                    data = json.loads(json_str)
                    if isinstance(data, dict) and "python" in data and "java" in data and "cpp" in data:
                        return {
                            "starter_code_python": data["python"].strip(),
                            "starter_code_java": data["java"].strip(),
                            "starter_code_cpp": data["cpp"].strip(),
                        }
            except Exception as e:
                logger.warning(f"AI starter code generation failed, using smart fallback: {e}")

        # 2. Smart Regex Fallback Parser
        func_name = "solve"
        params_list = []

        # Parse function signature from Python: def func(a, b):
        py_match = re.search(r"def\s+([a-zA-Z0-9_]+)\s*\((.*?)\)", clean_code)
        if py_match:
            func_name = py_match.group(1)
            raw_params = py_match.group(2)
            params_list = [p.strip().split(":")[0].strip() for p in raw_params.split(",") if p.strip()]

        # Parse from Java/C++: void func(...) or int func(...)
        cpp_java_match = re.search(
            r"(?:public\s+|static\s+)*(?:void|int|long|double|String|bool|vector<[^>]+>|int\[\]|boolean)\s+([a-zA-Z0-9_]+)\s*\((.*?)\)",
            clean_code,
        )
        if cpp_java_match and not py_match:
            func_name = cpp_java_match.group(1)

        # Build clean Python template
        py_params = ", ".join(params_list) if params_list else ""
        if lang == "python" and clean_code:
            py_template = clean_code
        else:
            py_template = (
                f"def {func_name}({py_params}):\n"
                f"    # Write your solution here\n"
                f"    pass\n\n"
                f"if __name__ == '__main__':\n"
                f"    # Read input from standard input if needed\n"
                f"    pass"
            )

        # Build clean Java template
        if lang == "java" and clean_code:
            java_template = clean_code
        else:
            java_template = (
                f"import java.util.*;\n\n"
                f"public class Main {{\n"
                f"    // Solution method\n"
                f"    public static void {func_name}() {{\n"
                f"        // TODO: Implement solution\n"
                f"    }}\n\n"
                f"    public static void main(String[] args) {{\n"
                f"        Scanner scanner = new Scanner(System.in);\n"
                f"        // Read input and execute solution\n"
                f"    }}\n"
                f"}}"
            )

        # Build clean C++ template
        if lang == "cpp" and clean_code:
            cpp_template = clean_code
        else:
            cpp_template = (
                f"#include <iostream>\n"
                f"#include <vector>\n"
                f"#include <string>\n"
                f"#include <algorithm>\n"
                f"using namespace std;\n\n"
                f"// Solution function\n"
                f"void {func_name}() {{\n"
                f"    // TODO: Implement solution\n"
                f"}}\n\n"
                f"int main() {{\n"
                f"    // Fast I/O\n"
                f"    ios_base::sync_with_stdio(false);\n"
                f"    cin.tie(NULL);\n\n"
                f"    // Read input and execute solution\n"
                f"    return 0;\n"
                f"}}"
            )

        return {
            "starter_code_python": py_template,
            "starter_code_java": java_template,
            "starter_code_cpp": cpp_template,
        }

    @staticmethod
    def create_custom_problem(
        db: Session,
        teacher_id: UUID,
        data: CustomProblemCreate,
    ) -> CustomProblemResponse:
        test_cases_dicts = [tc.model_dump() for tc in data.test_cases]

        py_code = data.starter_code_python if data.starter_code_python is not None else (data.starter_code or "")
        java_code = data.starter_code_java or ""
        cpp_code = data.starter_code_cpp or ""

        # Auto-generate missing templates if Java or C++ were omitted
        if not java_code or not cpp_code or not py_code:
            source_code = py_code or java_code or cpp_code or data.starter_code or ""
            source_lang = "python" if py_code else ("java" if java_code else "cpp")
            generated = CustomProblemService.auto_generate_starter_codes(source_code, source_lang)
            if not py_code:
                py_code = generated["starter_code_python"]
            if not java_code:
                java_code = generated["starter_code_java"]
            if not cpp_code:
                cpp_code = generated["starter_code_cpp"]

        # Check teacher verification if publishing directly
        if (data.visibility or "").upper() in ("CLASS_ONLY", "PUBLIC"):
            profile = db.scalar(select(TeacherProfile).where(TeacherProfile.user_id == teacher_id))
            if not profile or not profile.is_verified:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Faculty account requires administrator verification before publishing problems to students.",
                )

        problem = CustomProblem(
            teacher_id=teacher_id,
            title=data.title.strip(),
            description=data.description.strip(),
            starter_code=py_code,
            starter_code_python=py_code,
            starter_code_java=java_code,
            starter_code_cpp=cpp_code,
            test_cases=test_cases_dicts,
            visibility=data.visibility.upper(),
        )
        db.add(problem)
        db.commit()
        db.refresh(problem)

        # Award PROBLEM_SETTER badge to teacher
        try:
            BadgeService.award_badge_if_eligible(db, teacher_id, "PROBLEM_SETTER")
        except Exception as e:
            logger.warning(f"Error awarding PROBLEM_SETTER badge: {e}")

        # Fetch teacher info
        teacher = db.scalar(select(User).where(User.id == teacher_id))
        teacher_name = (f"{teacher.first_name or ''} {teacher.last_name or ''}".strip() or teacher.username) if teacher else "Educator"

        # Send notifications to linked classroom students if class-only
        try:
            student_links = db.scalars(select(StudentTeacher).where(StudentTeacher.teacher_id == teacher_id)).all()
            student_ids = [sl.student_id for sl in student_links]
            if student_ids:
                NotificationService.create_notifications_bulk(
                    db=db,
                    user_ids=student_ids,
                    title="New Mentor Challenge",
                    message=f"{teacher_name} posted a challenge: {problem.title}!",
                    type="HOMEWORK",
                )
        except Exception as e:
            logger.warning(f"Error sending custom problem notifications: {e}")

        return CustomProblemResponse(
            id=problem.id,
            teacher_id=problem.teacher_id,
            teacher_name=teacher_name,
            title=problem.title,
            description=problem.description,
            starter_code=problem.starter_code or problem.starter_code_python or "",
            starter_code_python=problem.starter_code_python or problem.starter_code or "",
            starter_code_java=problem.starter_code_java or "",
            starter_code_cpp=problem.starter_code_cpp or "",
            test_cases=problem.test_cases or [],
            visibility=problem.visibility,
            created_at=problem.created_at,
            total_submissions=0,
            accepted_submissions=0,
        )

    @staticmethod
    def get_teacher_custom_problems(
        db: Session,
        teacher_id: UUID,
    ) -> list[CustomProblemResponse]:
        problems = db.scalars(
            select(CustomProblem)
            .where(CustomProblem.teacher_id == teacher_id)
            .order_by(CustomProblem.created_at.desc())
        ).all()

        teacher = db.scalar(select(User).where(User.id == teacher_id))
        teacher_name = (f"{teacher.first_name or ''} {teacher.last_name or ''}".strip() or teacher.username) if teacher else "Educator"

        result = []
        for p in problems:
            # Count actual submissions/ACs for this custom problem
            total_subs = db.scalar(
                select(func.count(Submission.id)).where(Submission.problem_id == p.id)
            ) or 0
            accepted_subs = db.scalar(
                select(func.count(Submission.id)).where(
                    Submission.problem_id == p.id,
                    Submission.verdict == "AC",
                )
            ) or 0

            result.append(
                CustomProblemResponse(
                    id=p.id,
                    teacher_id=p.teacher_id,
                    teacher_name=teacher_name,
                    title=p.title,
                    description=p.description,
                    starter_code=p.starter_code or p.starter_code_python or "",
                    starter_code_python=p.starter_code_python or p.starter_code or "",
                    starter_code_java=p.starter_code_java or "",
                    starter_code_cpp=p.starter_code_cpp or "",
                    test_cases=p.test_cases or [],
                    visibility=p.visibility,
                    created_at=p.created_at,
                    total_submissions=total_subs,
                    accepted_submissions=accepted_subs,
                )
            )
        return result

    @staticmethod
    def get_mentor_custom_problems(
        db: Session,
        student_id: UUID,
    ) -> list[CustomProblemResponse]:
        """Fetch custom problems created by this student's linked mentor teacher(s)."""
        teacher_ids = list(
            db.scalars(
                select(StudentTeacher.teacher_id).where(StudentTeacher.student_id == student_id)
            ).all()
        )
        if not teacher_ids:
            return []

        problems = db.scalars(
            select(CustomProblem)
            .where(CustomProblem.teacher_id.in_(teacher_ids))
            .order_by(CustomProblem.created_at.desc())
        ).all()

        result = []
        for p in problems:
            teacher = db.scalar(select(User).where(User.id == p.teacher_id))
            teacher_name = (f"{teacher.first_name or ''} {teacher.last_name or ''}".strip() or teacher.username) if teacher else "Mentor"

            # Check if this student solved it (via CustomProblemCompletion or AC submission)
            is_comp = (
                db.scalar(
                    select(func.count(CustomProblemCompletion.id)).where(
                        CustomProblemCompletion.custom_problem_id == p.id,
                        CustomProblemCompletion.student_id == student_id,
                    )
                )
                or 0
            )
            has_ac_sub = (
                db.scalar(
                    select(func.count(Submission.id)).where(
                        Submission.problem_id == p.id,
                        Submission.student_id == student_id,
                        Submission.verdict == "AC",
                    )
                )
                or 0
            )
            is_completed = (is_comp > 0) or (has_ac_sub > 0)

            # Determine best/latest verdict
            latest_sub = db.scalar(
                select(Submission)
                .where(
                    Submission.problem_id == p.id,
                    Submission.student_id == student_id,
                )
                .order_by(Submission.created_at.desc())
            )
            best_verdict = "AC" if is_completed else (latest_sub.verdict if latest_sub else None)

            # Available languages
            langs = []
            if (p.starter_code_python and p.starter_code_python.strip()) or (p.starter_code and p.starter_code.strip()):
                langs.append("python")
            if p.starter_code_java and p.starter_code_java.strip():
                langs.append("java")
            if p.starter_code_cpp and p.starter_code_cpp.strip():
                langs.append("cpp")
            if not langs:
                langs = ["python", "java", "cpp"]

            result.append(
                CustomProblemResponse(
                    id=p.id,
                    teacher_id=p.teacher_id,
                    teacher_name=teacher_name,
                    title=p.title,
                    description=p.description,
                    starter_code=p.starter_code or p.starter_code_python or "",
                    starter_code_python=p.starter_code_python or p.starter_code or "",
                    starter_code_java=p.starter_code_java or "",
                    starter_code_cpp=p.starter_code_cpp or "",
                    test_cases=p.test_cases or [],
                    visibility=p.visibility,
                    created_at=p.created_at,
                    total_submissions=1 if is_completed else (1 if latest_sub else 0),
                    accepted_submissions=1 if is_completed else 0,
                    is_completed=is_completed,
                    xp_reward=50,
                    best_verdict=best_verdict,
                    languages=langs,
                )
            )
        return result

    @staticmethod
    def get_teacher_published_custom_problems(
        db: Session,
        teacher_id: UUID,
    ) -> list[CustomProblemResponse]:
        """Fetch custom problems for a public mentor profile."""
        problems = db.scalars(
            select(CustomProblem)
            .where(CustomProblem.teacher_id == teacher_id)
            .order_by(CustomProblem.created_at.desc())
        ).all()

        teacher = db.scalar(select(User).where(User.id == teacher_id))
        teacher_name = (f"{teacher.first_name or ''} {teacher.last_name or ''}".strip() or teacher.username) if teacher else "Educator"

        result = []
        for p in problems:
            result.append(
                CustomProblemResponse(
                    id=p.id,
                    teacher_id=p.teacher_id,
                    teacher_name=teacher_name,
                    title=p.title,
                    description=p.description,
                    starter_code=p.starter_code or p.starter_code_python or "",
                    starter_code_python=p.starter_code_python or p.starter_code or "",
                    starter_code_java=p.starter_code_java or "",
                    starter_code_cpp=p.starter_code_cpp or "",
                    test_cases=p.test_cases or [],
                    visibility=p.visibility,
                    created_at=p.created_at,
                    total_submissions=0,
                    accepted_submissions=0,
                )
            )
        return result

    @staticmethod
    def get_custom_problem_by_id(
        db: Session,
        problem_id: UUID,
        user_id: UUID,
    ) -> CustomProblemResponse:
        problem = db.scalar(select(CustomProblem).where(CustomProblem.id == problem_id))
        if not problem:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Custom problem not found",
            )

        # Check access if CLASS_ONLY
        if problem.visibility == "CLASS_ONLY" and problem.teacher_id != user_id:
            st = db.scalar(
                select(StudentTeacher).where(
                    StudentTeacher.student_id == user_id,
                    StudentTeacher.teacher_id == problem.teacher_id,
                )
            )
            if not st:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="This problem is restricted to classroom students of the creator.",
                )

        teacher = db.scalar(select(User).where(User.id == problem.teacher_id))
        teacher_name = (f"{teacher.first_name or ''} {teacher.last_name or ''}".strip() or teacher.username) if teacher else "Educator"

        is_owner = (problem.teacher_id == user_id)
        test_cases_to_return = problem.test_cases if is_owner else CustomProblemService.mask_test_cases_for_student(problem.test_cases or [])

        return CustomProblemResponse(
            id=problem.id,
            teacher_id=problem.teacher_id,
            teacher_name=teacher_name,
            title=problem.title,
            description=problem.description,
            starter_code=problem.starter_code or problem.starter_code_python or "",
            starter_code_python=problem.starter_code_python or problem.starter_code or "",
            starter_code_java=problem.starter_code_java or "",
            starter_code_cpp=problem.starter_code_cpp or "",
            test_cases=test_cases_to_return,
            visibility=problem.visibility,
            created_at=problem.created_at,
            total_submissions=0,
            accepted_submissions=0,
        )

    @staticmethod
    def update_custom_problem(
        db: Session,
        problem_id: UUID,
        teacher_id: UUID,
        data: CustomProblemUpdate,
    ) -> CustomProblemResponse:
        problem = db.scalar(select(CustomProblem).where(CustomProblem.id == problem_id))
        if not problem:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Custom problem not found")
        if problem.teacher_id != teacher_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You can only edit problems you created.")

        if data.title is not None:
            problem.title = data.title.strip()
        if data.description is not None:
            problem.description = data.description.strip()
        if data.starter_code_python is not None:
            problem.starter_code_python = data.starter_code_python
            problem.starter_code = data.starter_code_python
        elif data.starter_code is not None:
            problem.starter_code = data.starter_code
            problem.starter_code_python = data.starter_code
        if data.starter_code_java is not None:
            problem.starter_code_java = data.starter_code_java
        if data.starter_code_cpp is not None:
            problem.starter_code_cpp = data.starter_code_cpp
        if data.visibility is not None:
            new_vis = data.visibility.upper()
            if new_vis in ("CLASS_ONLY", "PUBLIC") and problem.visibility != new_vis:
                profile = db.scalar(select(TeacherProfile).where(TeacherProfile.user_id == teacher_id))
                if not profile or not profile.is_verified:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Faculty account requires administrator verification before publishing problems to students.",
                    )
            problem.visibility = new_vis
        if data.test_cases is not None:
            problem.test_cases = [tc.model_dump() for tc in data.test_cases]

        db.commit()
        db.refresh(problem)
        return CustomProblemService.get_custom_problem_by_id(db, problem.id, teacher_id)

    @staticmethod
    def publish_problem(
        db: Session,
        teacher: User,
        problem_id: UUID,
    ) -> CustomProblemResponse:
        profile = db.scalar(select(TeacherProfile).where(TeacherProfile.user_id == teacher.id))
        if not profile or not profile.is_verified:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Faculty account requires administrator verification before publishing problems to students.",
            )
        return CustomProblemService.update_custom_problem(
            db=db,
            problem_id=problem_id,
            teacher_id=teacher.id,
            data=CustomProblemUpdate(visibility="CLASS_ONLY"),
        )

    @staticmethod
    def get_custom_problem_stats(
        db: Session,
        problem_id: UUID,
        teacher_id: UUID,
    ) -> CustomProblemStatsResponse:
        problem = db.scalar(select(CustomProblem).where(CustomProblem.id == problem_id))
        if not problem:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Custom problem not found",
            )

        if problem.teacher_id != teacher_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only view stats for problems you created.",
            )

        # Count ALL submissions directly for this custom problem created by the teacher
        total_attempts = db.scalar(
            select(func.count(Submission.id)).where(Submission.problem_id == problem.id)
        ) or 0

        successful_ac = db.scalar(
            select(func.count(Submission.id)).where(
                Submission.problem_id == problem.id,
                Submission.verdict == "AC",
            )
        ) or 0

        pass_rate = (successful_ac / total_attempts * 100.0) if total_attempts > 0 else 0.0

        # Teacher's class students
        class_student_ids = set(
            db.scalars(
                select(StudentTeacher.student_id).where(StudentTeacher.teacher_id == teacher_id)
            ).all()
        )

        assignments = db.scalars(
            select(Assignment).where(Assignment.custom_problem_id == problem.id)
        ).all()

        roster_stats = []
        for a in assignments:
            student = db.scalar(select(User).where(User.id == a.student_id))
            is_class_student = a.student_id in class_student_ids
            
            student_name = (f"{student.first_name or ''} {student.last_name or ''}".strip() or student.username) if student else "Student"
            
            roster_stats.append({
                "assignment_id": str(a.id),
                "student_id": str(a.student_id),
                "student_name": student_name,
                "is_class_student": is_class_student,
                "status": a.status,
                "due_date": a.due_date.isoformat() if a.due_date else None,
                "completed_at": a.completed_at.isoformat() if a.completed_at else None,
            })

        # Fetch recent submissions history with student code
        subs = db.scalars(
            select(Submission)
            .where(Submission.problem_id == problem.id)
            .order_by(Submission.created_at.desc())
            .limit(50)
        ).all()

        submission_items = []
        for s in subs:
            student = db.scalar(select(User).where(User.id == s.student_id))
            student_name = (f"{student.first_name or ''} {student.last_name or ''}".strip() or student.username) if student else "Student"
            student_email = student.email if student else None
            submission_items.append(
                CustomProblemSubmissionItem(
                    submission_id=s.id,
                    student_id=s.student_id,
                    student_name=student_name,
                    student_email=student_email,
                    verdict=s.verdict,
                    language=s.language,
                    runtime_ms=s.execution_time_ms,
                    xp_awarded=getattr(s, "xp_awarded", 0) or (50 if s.verdict == "AC" and getattr(s, "is_first_ac", False) else 0),
                    is_first_ac=getattr(s, "is_first_ac", False),
                    created_at=s.created_at,
                    code=s.code,
                )
            )

        return CustomProblemStatsResponse(
            id=problem.id,
            title=problem.title,
            visibility=problem.visibility,
            total_attempts=total_attempts,
            successful_submissions=successful_ac,
            success_rate=round(pass_rate, 1),
            pass_rate=round(pass_rate, 1),
            class_roster_stats=roster_stats,
            submissions=submission_items,
            public_stats_count=total_attempts if problem.visibility == "PUBLIC" else 0,
        )

    @staticmethod
    def get_custom_problem_submissions(
        db: Session,
        problem_id: UUID,
        teacher_id: UUID,
    ) -> CustomProblemSubmissionsResponse:
        problem = db.scalar(select(CustomProblem).where(CustomProblem.id == problem_id))
        if not problem:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Custom problem not found",
            )
        if problem.teacher_id != teacher_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only view submissions for problems you created.",
            )

        subs = db.scalars(
            select(Submission)
            .where(Submission.problem_id == problem.id)
            .order_by(Submission.created_at.desc())
        ).all()

        items = []
        successful_ac = 0
        for s in subs:
            if s.verdict == "AC":
                successful_ac += 1
            student = db.scalar(select(User).where(User.id == s.student_id))
            student_name = (f"{student.first_name or ''} {student.last_name or ''}".strip() or student.username) if student else "Student"
            student_email = student.email if student else None
            items.append(
                CustomProblemSubmissionItem(
                    submission_id=s.id,
                    student_id=s.student_id,
                    student_name=student_name,
                    student_email=student_email,
                    verdict=s.verdict,
                    language=s.language,
                    runtime_ms=s.execution_time_ms,
                    xp_awarded=getattr(s, "xp_awarded", 0) or (50 if s.verdict == "AC" and getattr(s, "is_first_ac", False) else 0),
                    is_first_ac=getattr(s, "is_first_ac", False),
                    created_at=s.created_at,
                    code=s.code,
                )
            )

        total_attempts = len(subs)
        pass_rate = (successful_ac / total_attempts * 100.0) if total_attempts > 0 else 0.0

        return CustomProblemSubmissionsResponse(
            items=items,
            total_attempts=total_attempts,
            successful_ac=successful_ac,
            pass_rate=round(pass_rate, 1),
        )

