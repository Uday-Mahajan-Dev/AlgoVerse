import logging
from datetime import datetime, timezone
from typing import Any
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import desc, func, select
from sqlalchemy.orm import Session, selectinload

from app.models.assignment import Assignment
from app.models.quiz import Quiz
from app.models.quiz_attempt import QuizAttempt
from app.models.quiz_question import QuizQuestion
from app.models.student_teacher import StudentTeacher
from app.models.user import User
from app.schemas.quiz import (
    QuizAttemptDetail,
    QuizCreate,
    QuizLeaderboardEntry,
    QuizQuestionResponse,
    QuizResponse,
    QuizStatsResponse,
    QuizSubmitRequest,
    QuizSubmitResponse,
)
from app.services.badge_service import BadgeService
from app.services.notification_service import NotificationService

logger = logging.getLogger(__name__)


class QuizService:

    @staticmethod
    def create_quiz(
        db: Session,
        teacher_id: UUID,
        data: QuizCreate,
    ) -> QuizResponse:
        quiz = Quiz(
            teacher_id=teacher_id,
            title=data.title.strip(),
            description=data.description.strip() if data.description else "",
            visibility=data.visibility.upper(),
            time_per_question_seconds=data.time_per_question_seconds,
        )
        db.add(quiz)
        db.flush()

        for idx, q_data in enumerate(data.questions):
            question = QuizQuestion(
                quiz_id=quiz.id,
                question_text=q_data.question_text.strip(),
                options=q_data.options,
                correct_option_index=q_data.correct_option_index,
                order_index=idx,
            )
            db.add(question)

        db.commit()
        db.refresh(quiz)

        # Award QUIZ_MASTER badge to teacher
        try:
            BadgeService.award_badge_if_eligible(db, teacher_id, "QUIZ_MASTER")
        except Exception as e:
            logger.warning(f"Error awarding QUIZ_MASTER badge: {e}")

        teacher = db.scalar(select(User).where(User.id == teacher_id))
        teacher_name = (f"{teacher.first_name or ''} {teacher.last_name or ''}".strip() or teacher.username) if teacher else "Educator"

        # Send notifications to linked classroom students
        try:
            student_links = db.scalars(select(StudentTeacher).where(StudentTeacher.teacher_id == teacher_id)).all()
            student_ids = [sl.student_id for sl in student_links]
            if student_ids:
                NotificationService.create_notifications_bulk(
                    db=db,
                    user_ids=student_ids,
                    title="New Live Quiz",
                    message=f"{teacher_name} started a new quiz: {quiz.title}!",
                    type="QUIZ",
                )
        except Exception as e:
            logger.warning(f"Error sending quiz notifications: {e}")

        questions = db.scalars(
            select(QuizQuestion).where(QuizQuestion.quiz_id == quiz.id).order_by(QuizQuestion.order_index)
        ).all()


        return QuizResponse(
            id=quiz.id,
            teacher_id=quiz.teacher_id,
            teacher_name=teacher_name,
            title=quiz.title,
            description=quiz.description,
            visibility=quiz.visibility,
            time_per_question_seconds=quiz.time_per_question_seconds,
            question_count=len(questions),
            created_at=quiz.created_at,
            questions=[
                QuizQuestionResponse(
                    id=q.id,
                    quiz_id=q.quiz_id,
                    question_text=q.question_text,
                    options=q.options or [],
                    correct_option_index=q.correct_option_index,
                    order_index=q.order_index,
                )
                for q in questions
            ],
        )

    @staticmethod
    def get_teacher_quizzes(
        db: Session,
        teacher_id: UUID,
    ) -> list[QuizResponse]:
        quizzes = db.scalars(
            select(Quiz)
            .where(Quiz.teacher_id == teacher_id)
            .options(selectinload(Quiz.questions), selectinload(Quiz.teacher))
            .order_by(Quiz.created_at.desc())
        ).all()

        results = []
        for q in quizzes:
            t_name = (f"{q.teacher.first_name or ''} {q.teacher.last_name or ''}".strip() or q.teacher.username) if q.teacher else "Educator"
            results.append(
                QuizResponse(
                    id=q.id,
                    teacher_id=q.teacher_id,
                    teacher_name=t_name,
                    title=q.title,
                    description=q.description,
                    visibility=q.visibility,
                    time_per_question_seconds=q.time_per_question_seconds,
                    question_count=len(q.questions),
                    created_at=q.created_at,
                    questions=[
                        QuizQuestionResponse(
                            id=qq.id,
                            quiz_id=qq.quiz_id,
                            question_text=qq.question_text,
                            options=qq.options or [],
                            correct_option_index=qq.correct_option_index,
                            order_index=qq.order_index,
                        )
                        for qq in q.questions
                    ],
                )
            )
        return results

    @staticmethod
    def get_public_quizzes(db: Session) -> list[QuizResponse]:
        quizzes = db.scalars(
            select(Quiz)
            .where(Quiz.visibility == "PUBLIC")
            .options(selectinload(Quiz.questions), selectinload(Quiz.teacher))
            .order_by(Quiz.created_at.desc())
        ).all()

        results = []
        for q in quizzes:
            t_name = (f"{q.teacher.first_name or ''} {q.teacher.last_name or ''}".strip() or q.teacher.username) if q.teacher else "Educator"
            results.append(
                QuizResponse(
                    id=q.id,
                    teacher_id=q.teacher_id,
                    teacher_name=t_name,
                    title=q.title,
                    description=q.description,
                    visibility=q.visibility,
                    time_per_question_seconds=q.time_per_question_seconds,
                    question_count=len(q.questions),
                    created_at=q.created_at,
                    questions=[],
                )
            )
        return results

    @staticmethod
    def get_class_quizzes(
        db: Session,
        user_id: UUID,
    ) -> list[QuizResponse]:
        # Check if user is teacher
        teacher_quizzes = db.scalars(
            select(Quiz)
            .where(Quiz.teacher_id == user_id)
            .options(selectinload(Quiz.questions), selectinload(Quiz.teacher))
            .order_by(Quiz.created_at.desc())
        ).all()
        if teacher_quizzes:
            results = []
            for q in teacher_quizzes:
                t_name = (f"{q.teacher.first_name or ''} {q.teacher.last_name or ''}".strip() or q.teacher.username) if q.teacher else "Educator"
                results.append(
                    QuizResponse(
                        id=q.id,
                        teacher_id=q.teacher_id,
                        teacher_name=t_name,
                        title=q.title,
                        description=q.description,
                        visibility=q.visibility,
                        time_per_question_seconds=q.time_per_question_seconds,
                        question_count=len(q.questions),
                        created_at=q.created_at,
                        questions=[],
                    )
                )
            return results

        # Find linked teachers for this student
        teacher_ids = list(
            db.scalars(
                select(StudentTeacher.teacher_id).where(StudentTeacher.student_id == user_id)
            ).all()
        )

        if not teacher_ids:
            return []

        quizzes = db.scalars(
            select(Quiz)
            .where(Quiz.teacher_id.in_(teacher_ids))
            .options(selectinload(Quiz.questions), selectinload(Quiz.teacher))
            .order_by(Quiz.created_at.desc())
        ).all()

        results = []
        for q in quizzes:
            t_name = (f"{q.teacher.first_name or ''} {q.teacher.last_name or ''}".strip() or q.teacher.username) if q.teacher else "Educator"
            results.append(
                QuizResponse(
                    id=q.id,
                    teacher_id=q.teacher_id,
                    teacher_name=t_name,
                    title=q.title,
                    description=q.description,
                    visibility=q.visibility,
                    time_per_question_seconds=q.time_per_question_seconds,
                    question_count=len(q.questions),
                    created_at=q.created_at,
                    questions=[],
                )
            )
        return results

    @staticmethod
    def get_quiz_by_id(
        db: Session,
        quiz_id: UUID,
        user_id: UUID,
        is_playing: bool = False,
    ) -> QuizResponse:
        quiz = db.scalar(
            select(Quiz)
            .where(Quiz.id == quiz_id)
            .options(selectinload(Quiz.questions), selectinload(Quiz.teacher))
        )
        if not quiz:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Quiz not found",
            )

        # Check access if CLASS_ONLY
        if quiz.visibility == "CLASS_ONLY" and quiz.teacher_id != user_id:
            st = db.scalar(
                select(StudentTeacher).where(
                    StudentTeacher.student_id == user_id,
                    StudentTeacher.teacher_id == quiz.teacher_id,
                )
            )
            if not st:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="This quiz is restricted to classroom students of the creator.",
                )

        t_name = (f"{quiz.teacher.first_name or ''} {quiz.teacher.last_name or ''}".strip() or quiz.teacher.username) if quiz.teacher else "Educator"
        is_creator = quiz.teacher_id == user_id

        # Hide correct option index during gameplay if not creator
        questions_resp = []
        sorted_questions = sorted(quiz.questions, key=lambda q: q.order_index)
        for q in sorted_questions:
            correct_idx = q.correct_option_index if (is_creator or not is_playing) else None
            questions_resp.append(
                QuizQuestionResponse(
                    id=q.id,
                    quiz_id=q.quiz_id,
                    question_text=q.question_text,
                    options=q.options or [],
                    correct_option_index=correct_idx,
                    order_index=q.order_index,
                )
            )

        return QuizResponse(
            id=quiz.id,
            teacher_id=quiz.teacher_id,
            teacher_name=t_name,
            title=quiz.title,
            description=quiz.description,
            visibility=quiz.visibility,
            time_per_question_seconds=quiz.time_per_question_seconds,
            question_count=len(sorted_questions),
            created_at=quiz.created_at,
            questions=questions_resp,
        )


    @staticmethod
    def submit_quiz(
        db: Session,
        quiz_id: UUID,
        student_id: UUID,
        submission: QuizSubmitRequest,
    ) -> QuizSubmitResponse:
        quiz = db.scalar(
            select(Quiz)
            .where(Quiz.id == quiz_id)
            .options(selectinload(Quiz.questions))
        )
        if not quiz:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Quiz not found",
            )

        question_map = {q.id: q for q in quiz.questions}
        total_questions = len(quiz.questions)
        time_limit = quiz.time_per_question_seconds or 30

        total_score = 0
        correct_count = 0
        total_time = 0
        answers_record = []

        for ans in submission.answers:
            q = question_map.get(ans.question_id)
            if not q:
                continue

            time_spent = min(ans.time_taken_seconds, time_limit)
            total_time += time_spent
            is_correct = (ans.selected_index == q.correct_option_index)

            q_score = 0
            if is_correct:
                correct_count += 1
                # Kahoot-style scoring:
                # Base score = 500, speed bonus up to 500 (based on time remaining)
                time_ratio = max(0.0, (time_limit - time_spent) / time_limit)
                q_score = 500 + int(500 * time_ratio)
                total_score += q_score

            answers_record.append({
                "question_id": str(ans.question_id),
                "selected_index": ans.selected_index,
                "correct_option_index": q.correct_option_index,
                "is_correct": is_correct,
                "time_taken_seconds": time_spent,
                "score": q_score,
            })

        attempt = QuizAttempt(
            quiz_id=quiz.id,
            student_id=student_id,
            score=total_score,
            total_time_seconds=total_time,
            answers=answers_record,
            submitted_at=datetime.now(timezone.utc),
        )
        db.add(attempt)
        db.commit()
        db.refresh(attempt)

        # Mark any pending homework assignments for this student and quiz as COMPLETED
        assignments = db.scalars(
            select(Assignment).where(
                Assignment.student_id == student_id,
                Assignment.quiz_id == quiz_id,
                Assignment.status == "pending",
            )
        ).all()
        for a in assignments:
            a.status = "completed"
            a.completed_at = datetime.now(timezone.utc)
        if assignments:
            db.commit()

        # Calculate rank
        all_scores = db.scalars(
            select(QuizAttempt.score)
            .where(QuizAttempt.quiz_id == quiz.id)
            .order_by(QuizAttempt.score.desc(), QuizAttempt.total_time_seconds.asc())
        ).all()
        rank = 1
        for s in all_scores:
            if s > total_score:
                rank += 1
            else:
                break

        max_score = total_questions * 1000

        return QuizSubmitResponse(
            attempt_id=attempt.id,
            quiz_id=quiz.id,
            score=total_score,
            max_possible_score=max_score,
            correct_count=correct_count,
            total_questions=total_questions,
            total_time_seconds=total_time,
            rank=rank,
            submitted_at=attempt.submitted_at,
        )

    @staticmethod
    def get_quiz_leaderboard(
        db: Session,
        quiz_id: UUID,
        current_user: User,
    ) -> list[QuizLeaderboardEntry]:
        quiz = db.scalar(select(Quiz).where(Quiz.id == quiz_id))
        if not quiz:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Quiz not found",
            )

        attempts_query = (
            select(QuizAttempt)
            .where(QuizAttempt.quiz_id == quiz_id)
            .options(selectinload(QuizAttempt.student))
            .order_by(desc(QuizAttempt.score), QuizAttempt.total_time_seconds.asc())
        )

        # If CLASS_ONLY and requester is not the teacher, filter to teacher's class students
        if quiz.visibility == "CLASS_ONLY":
            attempts = db.scalars(attempts_query).all()
            # Fetch all classroom student ids for this teacher
            class_student_ids = set(
                db.scalars(
                    select(StudentTeacher.student_id).where(StudentTeacher.teacher_id == quiz.teacher_id)
                ).all()
            )
            filtered = []
            for att in attempts:
                if att.student_id in class_student_ids or att.student_id == current_user.id or quiz.teacher_id == current_user.id:
                    filtered.append(att)
            attempts = filtered
        else:
            attempts = db.scalars(attempts_query.limit(50)).all()

        # Deduplicate best score per student
        seen_students = set()
        leaderboard = []
        rank = 1

        for att in attempts:
            if att.student_id in seen_students:
                continue
            seen_students.add(att.student_id)

            student_name = "Student"
            avatar_url = None
            if att.student:
                student_name = (f"{att.student.first_name or ''} {att.student.last_name or ''}".strip() or att.student.username)
                avatar_url = att.student.avatar_url

            leaderboard.append(
                QuizLeaderboardEntry(
                    rank=rank,
                    student_id=att.student_id,
                    student_name=student_name,
                    avatar_url=avatar_url,
                    score=att.score,
                    total_time_seconds=att.total_time_seconds,
                    submitted_at=att.submitted_at,
                )
            )
            rank += 1

        return leaderboard

    @staticmethod
    def get_quiz_stats(
        db: Session,
        quiz_id: UUID,
        teacher_id: UUID,
    ) -> QuizStatsResponse:
        quiz = db.scalar(select(Quiz).where(Quiz.id == quiz_id))
        if not quiz:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Quiz not found",
            )

        if quiz.teacher_id != teacher_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only view detailed stats for quizzes you created.",
            )

        attempts = db.scalars(
            select(QuizAttempt)
            .where(QuizAttempt.quiz_id == quiz_id)
            .options(selectinload(QuizAttempt.student))
            .order_by(desc(QuizAttempt.score), QuizAttempt.total_time_seconds.asc())
        ).all()

        # Fetch classroom student ids for this teacher
        class_student_ids = set(
            db.scalars(
                select(StudentTeacher.student_id).where(StudentTeacher.teacher_id == teacher_id)
            ).all()
        )

        total_attempts = len(attempts)
        avg_score = (sum(a.score for a in attempts) / total_attempts) if total_attempts > 0 else 0.0
        highest_score = max((a.score for a in attempts), default=0)

        # Class attempts vs non-class
        class_attempts_list = []
        top_scorers_list = []
        seen_students = set()
        rank = 1

        for a in attempts:
            student = a.student
            is_class_student = a.student_id in class_student_ids
            
            student_name = (f"{student.first_name or ''} {student.last_name or ''}".strip() or student.username) if (student and is_class_student) else "Anonymous Student"
            
            if is_class_student:
                class_attempts_list.append(
                    QuizAttemptDetail(
                        student_id=a.student_id,
                        student_name=student_name,
                        is_class_student=True,
                        score=a.score,
                        total_time_seconds=a.total_time_seconds,
                        submitted_at=a.submitted_at,
                        answers=a.answers or [],
                    )
                )

            if a.student_id not in seen_students and len(top_scorers_list) < 10:
                seen_students.add(a.student_id)
                top_scorers_list.append(
                    QuizLeaderboardEntry(
                        rank=rank,
                        student_id=a.student_id,
                        student_name=student_name,
                        avatar_url=student.avatar_url if (student and is_class_student) else None,
                        score=a.score,
                        total_time_seconds=a.total_time_seconds,
                        submitted_at=a.submitted_at,
                    )
                )
                rank += 1

        return QuizStatsResponse(
            quiz_id=quiz.id,
            title=quiz.title,
            visibility=quiz.visibility,
            total_attempts=total_attempts,
            average_score=round(avg_score, 1),
            highest_score=highest_score,
            class_attempts=class_attempts_list,
            top_scorers=top_scorers_list,
        )
