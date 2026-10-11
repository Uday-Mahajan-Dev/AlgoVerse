from datetime import datetime, timezone
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import desc, func, select
from sqlalchemy.orm import Session

from app.models.custom_problem import CustomProblem
from app.models.lesson import Lesson
from app.models.lesson_feedback import LessonFeedback
from app.models.problem import Problem
from app.models.problem_feedback import ProblemFeedback
from app.models.professor_rating import ProfessorRating
from app.models.role import Role
from app.models.student_teacher import StudentTeacher
from app.models.user import User
from app.schemas.feedback import (
    LessonFeedbackCreate,
    LessonFeedbackResponse,
    LessonFeedbackSummary,
    ProblemFeedbackCreate,
    ProblemFeedbackResponse,
    ProblemFeedbackSummary,
    ProfessorRatingCreate,
    ProfessorRatingItem,
    ProfessorRatingsSummary,
)


class FeedbackService:

    # ---------------------------------------------------------
    # 1. Lesson Feedback
    # ---------------------------------------------------------

    @staticmethod
    def submit_lesson_feedback(
        db: Session,
        student_id: UUID,
        lesson_id: UUID,
        data: LessonFeedbackCreate,
    ) -> LessonFeedbackResponse:
        lesson = db.scalar(select(Lesson).where(Lesson.id == lesson_id))
        if not lesson:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Lesson with ID '{lesson_id}' not found.",
            )

        existing = db.scalar(
            select(LessonFeedback).where(
                LessonFeedback.student_id == student_id,
                LessonFeedback.lesson_id == lesson_id,
            )
        )

        now = datetime.now(timezone.utc)
        if existing:
            existing.rating = data.rating
            existing.comment = data.comment.strip() if data.comment else None
            existing.updated_at = now
            record = existing
        else:
            record = LessonFeedback(
                student_id=student_id,
                lesson_id=lesson_id,
                rating=data.rating,
                comment=data.comment.strip() if data.comment else None,
                created_at=now,
                updated_at=now,
            )
            db.add(record)

        db.commit()
        db.refresh(record)
        return LessonFeedbackResponse.model_validate(record)

    @staticmethod
    def get_lesson_feedback_summary(
        db: Session,
        lesson_id: UUID,
        student_id: UUID | None = None,
    ) -> LessonFeedbackSummary:
        lesson = db.scalar(select(Lesson).where(Lesson.id == lesson_id))
        if not lesson:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Lesson with ID '{lesson_id}' not found.",
            )

        avg_val, count_val = db.execute(
            select(
                func.avg(LessonFeedback.rating),
                func.count(LessonFeedback.id),
            ).where(LessonFeedback.lesson_id == lesson_id)
        ).first() or (0.0, 0)

        my_rating = None
        my_comment = None
        if student_id:
            my_record = db.scalar(
                select(LessonFeedback).where(
                    LessonFeedback.student_id == student_id,
                    LessonFeedback.lesson_id == lesson_id,
                )
            )
            if my_record:
                my_rating = my_record.rating
                my_comment = my_record.comment

        avg_rating = round(float(avg_val), 1) if avg_val else 0.0
        return LessonFeedbackSummary(
            avg_rating=avg_rating,
            rating_count=int(count_val or 0),
            my_rating=my_rating,
            my_comment=my_comment,
        )

    # ---------------------------------------------------------
    # 2. Problem Feedback
    # ---------------------------------------------------------

    @staticmethod
    def submit_problem_feedback(
        db: Session,
        student_id: UUID,
        problem_id: UUID,
        data: ProblemFeedbackCreate,
    ) -> ProblemFeedbackResponse:
        kind = data.problem_kind.lower()
        if kind == "custom":
            problem = db.scalar(select(CustomProblem).where(CustomProblem.id == problem_id))
            if not problem:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Custom problem with ID '{problem_id}' not found.",
                )
        else:
            problem = db.scalar(select(Problem).where(Problem.id == problem_id))
            if not problem:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Problem with ID '{problem_id}' not found.",
                )

        existing = db.scalar(
            select(ProblemFeedback).where(
                ProblemFeedback.student_id == student_id,
                ProblemFeedback.problem_id == problem_id,
                ProblemFeedback.problem_kind == kind,
            )
        )

        now = datetime.now(timezone.utc)
        if existing:
            existing.rating = data.rating
            existing.comment = data.comment.strip() if data.comment else None
            existing.updated_at = now
            record = existing
        else:
            record = ProblemFeedback(
                student_id=student_id,
                problem_id=problem_id,
                problem_kind=kind,
                rating=data.rating,
                comment=data.comment.strip() if data.comment else None,
                created_at=now,
                updated_at=now,
            )
            db.add(record)

        db.commit()
        db.refresh(record)
        return ProblemFeedbackResponse.model_validate(record)

    @staticmethod
    def get_problem_feedback_summary(
        db: Session,
        problem_id: UUID,
        problem_kind: str = "course",
        student_id: UUID | None = None,
    ) -> ProblemFeedbackSummary:
        kind = problem_kind.lower()
        avg_val, count_val = db.execute(
            select(
                func.avg(ProblemFeedback.rating),
                func.count(ProblemFeedback.id),
            ).where(
                ProblemFeedback.problem_id == problem_id,
                ProblemFeedback.problem_kind == kind,
            )
        ).first() or (0.0, 0)

        my_rating = None
        my_comment = None
        if student_id:
            my_record = db.scalar(
                select(ProblemFeedback).where(
                    ProblemFeedback.student_id == student_id,
                    ProblemFeedback.problem_id == problem_id,
                    ProblemFeedback.problem_kind == kind,
                )
            )
            if my_record:
                my_rating = my_record.rating
                my_comment = my_record.comment

        avg_rating = round(float(avg_val), 1) if avg_val else 0.0
        return ProblemFeedbackSummary(
            avg_rating=avg_rating,
            rating_count=int(count_val or 0),
            my_rating=my_rating,
            my_comment=my_comment,
        )

    # ---------------------------------------------------------
    # 3. Professor Ratings
    # ---------------------------------------------------------

    @staticmethod
    def submit_professor_rating(
        db: Session,
        student_id: UUID,
        teacher_id: UUID,
        data: ProfessorRatingCreate,
    ) -> ProfessorRatingsSummary:
        teacher = db.scalar(select(User).where(User.id == teacher_id))
        if not teacher:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Educator with ID '{teacher_id}' not found.",
            )

        # Rule: Only approved mentees (student_teachers link exists) can rate the professor
        link = db.scalar(
            select(StudentTeacher).where(
                StudentTeacher.student_id == student_id,
                StudentTeacher.teacher_id == teacher_id,
            )
        )
        if not link:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only approved classroom mentees can rate this educator.",
            )

        existing = db.scalar(
            select(ProfessorRating).where(
                ProfessorRating.student_id == student_id,
                ProfessorRating.teacher_id == teacher_id,
            )
        )

        now = datetime.now(timezone.utc)
        if existing:
            existing.rating = data.rating
            existing.comment = data.comment.strip() if data.comment else None
            existing.updated_at = now
        else:
            record = ProfessorRating(
                student_id=student_id,
                teacher_id=teacher_id,
                rating=data.rating,
                comment=data.comment.strip() if data.comment else None,
                created_at=now,
                updated_at=now,
            )
            db.add(record)

        db.commit()
        return FeedbackService.get_professor_ratings_summary(
            db=db,
            teacher_id=teacher_id,
            student_id=student_id,
        )

    @staticmethod
    def get_professor_ratings_summary(
        db: Session,
        teacher_id: UUID,
        student_id: UUID | None = None,
    ) -> ProfessorRatingsSummary:
        teacher = db.scalar(select(User).where(User.id == teacher_id))
        if not teacher:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Educator with ID '{teacher_id}' not found.",
            )

        rows = (
            db.execute(
                select(ProfessorRating, User)
                .join(User, User.id == ProfessorRating.student_id)
                .where(ProfessorRating.teacher_id == teacher_id)
                .order_by(desc(ProfessorRating.created_at))
            )
            .all()
        )

        items: list[ProfessorRatingItem] = []
        ratings_sum = 0
        my_rating = None
        my_comment = None

        for rating_record, student_user in rows:
            ratings_sum += rating_record.rating
            s_name = (
                f"{student_user.first_name} {student_user.last_name}".strip()
                if student_user and (student_user.first_name or student_user.last_name)
                else (student_user.username if student_user else "Student")
            )
            items.append(
                ProfessorRatingItem(
                    id=rating_record.id,
                    student_id=rating_record.student_id,
                    student_name=s_name,
                    student_avatar=student_user.avatar_url,
                    rating=rating_record.rating,
                    comment=rating_record.comment,
                    created_at=rating_record.created_at,
                )
            )
            if student_id and rating_record.student_id == student_id:
                my_rating = rating_record.rating
                my_comment = rating_record.comment

        count = len(items)
        avg_rating = round(ratings_sum / count, 1) if count > 0 else 0.0

        return ProfessorRatingsSummary(
            avg_rating=avg_rating,
            rating_count=count,
            my_rating=my_rating,
            my_comment=my_comment,
            ratings=items,
        )
