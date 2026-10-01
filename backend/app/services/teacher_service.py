from datetime import datetime, timezone
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.core.enums import UserRole
from app.models.role import Role
from app.models.student_teacher import StudentTeacher
from app.models.user import User
from app.schemas.teachers import (
    MyTeacherResponse,
    TeacherListItem,
    TeacherProfileResponse,
    TeacherSelectionResponse,
)


class TeacherService:

    @staticmethod
    def get_all_teachers(
        db: Session,
        search_query: str | None = None,
    ) -> list[TeacherListItem]:
        teacher_role = db.scalar(
            select(Role).where(Role.name == UserRole.TEACHER.value)
        )

        if not teacher_role:
            return []

        # Count students per teacher
        student_counts_subquery = (
            select(
                StudentTeacher.teacher_id,
                func.count(StudentTeacher.id).label("student_count"),
            )
            .group_by(StudentTeacher.teacher_id)
            .subquery()
        )

        query = (
            select(
                User,
                func.coalesce(student_counts_subquery.c.student_count, 0).label(
                    "student_count"
                ),
            )
            .outerjoin(
                student_counts_subquery,
                User.id == student_counts_subquery.c.teacher_id,
            )
            .where(
                User.role_id == teacher_role.id,
                User.is_active.is_(True),
            )
        )

        if search_query:
            term = f"%{search_query.strip()}%"
            query = query.where(
                or_(
                    User.first_name.ilike(term),
                    User.last_name.ilike(term),
                    User.username.ilike(term),
                    User.bio.ilike(term),
                )
            )

        results = db.execute(query).all()

        teachers_list = []
        for user, count in results:
            specialty = (
                user.bio
                if user.bio
                else "Data Structures & Competitive Programming"
            )
            teachers_list.append(
                TeacherListItem(
                    id=user.id,
                    first_name=user.first_name or user.username,
                    last_name=user.last_name or "",
                    username=user.username,
                    avatar_url=user.avatar_url,
                    bio=user.bio,
                    country=user.country,
                    student_count=int(count),
                    specialty=specialty,
                )
            )

        return teachers_list

    @staticmethod
    def get_teacher_profile(
        db: Session,
        teacher_id: UUID,
    ) -> TeacherProfileResponse:
        teacher_role = db.scalar(
            select(Role).where(Role.name == UserRole.TEACHER.value)
        )

        teacher = db.scalar(
            select(User).where(
                User.id == teacher_id,
                User.role_id == teacher_role.id if teacher_role else False,
                User.is_active.is_(True),
            )
        )

        if not teacher:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Teacher not found.",
            )

        student_count = db.scalar(
            select(func.count(StudentTeacher.id)).where(
                StudentTeacher.teacher_id == teacher_id
            )
        ) or 0

        specialty = (
            teacher.bio
            if teacher.bio
            else "Data Structures & Competitive Programming"
        )

        return TeacherProfileResponse(
            id=teacher.id,
            first_name=teacher.first_name or teacher.username,
            last_name=teacher.last_name or "",
            username=teacher.username,
            email=teacher.email,
            avatar_url=teacher.avatar_url,
            bio=teacher.bio,
            country=teacher.country,
            student_count=student_count,
            specialty=specialty,
            created_at=teacher.created_at,
        )

    @staticmethod
    def select_teacher(
        db: Session,
        student_id: UUID,
        teacher_id: UUID,
    ) -> TeacherSelectionResponse:
        if student_id == teacher_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You cannot select yourself as your mentor teacher.",
            )

        teacher_role = db.scalar(
            select(Role).where(Role.name == UserRole.TEACHER.value)
        )

        teacher = db.scalar(
            select(User).where(
                User.id == teacher_id,
                User.role_id == teacher_role.id if teacher_role else False,
                User.is_active.is_(True),
            )
        )

        if not teacher:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Selected teacher does not exist or is inactive.",
            )

        # Atomic transaction: delete any existing mentor association, then insert new one
        try:
            db.query(StudentTeacher).filter(
                StudentTeacher.student_id == student_id
            ).delete()

            association = StudentTeacher(
                student_id=student_id,
                teacher_id=teacher_id,
            )
            db.add(association)
            db.commit()
            db.refresh(association)
        except Exception:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update teacher selection. Please try again.",
            )

        teacher_name = (
            f"{teacher.first_name} {teacher.last_name}".strip()
            or teacher.username
        )

        return TeacherSelectionResponse(
            message="Teacher selected successfully.",
            teacher_id=teacher.id,
            teacher_name=teacher_name,
            selected_at=association.created_at or datetime.now(timezone.utc),
        )

    @staticmethod
    def get_my_teacher(
        db: Session,
        student_id: UUID,
    ) -> MyTeacherResponse:
        association = db.scalar(
            select(StudentTeacher).where(
                StudentTeacher.student_id == student_id
            )
        )

        if not association:
            return MyTeacherResponse(
                has_teacher=False,
                teacher=None,
                selected_at=None,
            )

        teacher_profile = TeacherService.get_teacher_profile(
            db=db,
            teacher_id=association.teacher_id,
        )

        return MyTeacherResponse(
            has_teacher=True,
            teacher=teacher_profile,
            selected_at=association.created_at,
        )
