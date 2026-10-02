import random
import string
from datetime import datetime, timezone
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.core.enums import UserRole
from app.models.role import Role
from app.models.student_teacher import StudentTeacher
from app.models.teacher_profile import TeacherProfile
from app.models.user import User
from app.schemas.teachers import (
    EducatorRegistrationResponse,
    JoinClassResponse,
    MyTeacherResponse,
    TeacherListItem,
    TeacherProfileResponse,
    TeacherSelectionResponse,
)


class TeacherService:

    @staticmethod
    def _generate_unique_class_code(db: Session, institution_name: str | None = None) -> str:
        prefix = "ALG"
        if institution_name:
            clean = "".join([c for c in institution_name if c.isalnum()]).upper()
            if len(clean) >= 3:
                prefix = clean[:3]

        for _ in range(30):
            digits = "".join(random.choices(string.digits, k=3))
            code = f"{prefix}-{digits}"
            existing = db.scalar(select(TeacherProfile).where(TeacherProfile.class_code == code))
            if not existing:
                return code

        while True:
            code = f"{prefix}-" + "".join(random.choices(string.ascii_uppercase + string.digits, k=4))
            existing = db.scalar(select(TeacherProfile).where(TeacherProfile.class_code == code))
            if not existing:
                return code

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
                TeacherProfile,
            )
            .outerjoin(
                student_counts_subquery,
                User.id == student_counts_subquery.c.teacher_id,
            )
            .outerjoin(
                TeacherProfile,
                User.id == TeacherProfile.user_id,
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
                    TeacherProfile.institution_name.ilike(term),
                    TeacherProfile.subject_expertise.ilike(term),
                    TeacherProfile.class_code.ilike(term),
                )
            )

        results = db.execute(query).all()

        teachers_list = []
        for user, count, profile in results:
            specialty = (
                profile.subject_expertise
                if profile and profile.subject_expertise
                else (user.bio if user.bio else "Data Structures & Competitive Programming")
            )
            teachers_list.append(
                TeacherListItem(
                    id=user.id,
                    first_name=user.first_name or user.username,
                    last_name=user.last_name or "",
                    username=user.username,
                    avatar_url=user.avatar_url,
                    bio=profile.bio if profile and profile.bio else user.bio,
                    country=user.country,
                    student_count=int(count),
                    specialty=specialty,
                    institution_name=profile.institution_name if profile else None,
                    class_code=profile.class_code if profile else None,
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

        profile = db.scalar(
            select(TeacherProfile).where(TeacherProfile.user_id == teacher_id)
        )

        specialty = (
            profile.subject_expertise
            if profile and profile.subject_expertise
            else (teacher.bio if teacher.bio else "Data Structures & Competitive Programming")
        )

        return TeacherProfileResponse(
            id=teacher.id,
            first_name=teacher.first_name or teacher.username,
            last_name=teacher.last_name or "",
            username=teacher.username,
            email=teacher.email,
            avatar_url=teacher.avatar_url,
            bio=profile.bio if profile and profile.bio else teacher.bio,
            country=teacher.country,
            student_count=student_count,
            specialty=specialty,
            institution_name=profile.institution_name if profile else None,
            class_code=profile.class_code if profile else None,
            created_at=teacher.created_at,
        )

    @staticmethod
    def register_educator(
        db: Session,
        user_id: UUID,
        institution_name: str,
        subject_expertise: str,
        bio: str | None = None,
    ) -> EducatorRegistrationResponse:
        user = db.scalar(select(User).where(User.id == user_id, User.is_active.is_(True)))
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found.",
            )

        teacher_role = db.scalar(
            select(Role).where(Role.name == UserRole.TEACHER.value)
        )
        if not teacher_role:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Teacher role not configured in database.",
            )

        # Update user role to TEACHER
        user.role_id = teacher_role.id
        user.role = teacher_role
        if bio:
            user.bio = bio

        # Check existing teacher profile or create new
        profile = db.scalar(
            select(TeacherProfile).where(TeacherProfile.user_id == user.id)
        )

        if not profile:
            class_code = TeacherService._generate_unique_class_code(db, institution_name)
            profile = TeacherProfile(
                user_id=user.id,
                institution_name=institution_name.strip(),
                subject_expertise=subject_expertise.strip(),
                bio=bio.strip() if bio else None,
                class_code=class_code,
                is_verified=True,
            )
            db.add(profile)
        else:
            profile.institution_name = institution_name.strip()
            profile.subject_expertise = subject_expertise.strip()
            if bio:
                profile.bio = bio.strip()
            if not profile.class_code:
                profile.class_code = TeacherService._generate_unique_class_code(db, institution_name)

        try:
            db.commit()
            db.refresh(profile)
            db.refresh(user)
        except Exception:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to register as educator. Please try again.",
            )

        return EducatorRegistrationResponse(
            message="Successfully registered as educator.",
            role=UserRole.TEACHER.value,
            class_code=profile.class_code,
            institution_name=profile.institution_name,
            subject_expertise=profile.subject_expertise,
            bio=profile.bio,
        )

    @staticmethod
    def join_class_by_code(
        db: Session,
        student_id: UUID,
        class_code: str,
    ) -> JoinClassResponse:
        code = class_code.strip().upper()
        profile = db.scalar(
            select(TeacherProfile).where(func.upper(TeacherProfile.class_code) == code)
        )

        if not profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Class with code '{code}' not found. Please verify the code with your educator.",
            )

        if profile.user_id == student_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You cannot join your own class.",
            )

        teacher = db.scalar(
            select(User).where(User.id == profile.user_id, User.is_active.is_(True))
        )
        if not teacher:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Educator account associated with this class code is inactive or not found.",
            )

        # Atomic transaction: delete existing student-teacher link, insert new one
        try:
            db.query(StudentTeacher).filter(
                StudentTeacher.student_id == student_id
            ).delete()

            association = StudentTeacher(
                student_id=student_id,
                teacher_id=teacher.id,
            )
            db.add(association)
            db.commit()
            db.refresh(association)
        except Exception:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to join class. Please try again.",
            )

        teacher_name = (
            f"{teacher.first_name} {teacher.last_name}".strip()
            or teacher.username
        )

        return JoinClassResponse(
            message=f"Successfully joined class taught by {teacher_name}.",
            teacher_id=teacher.id,
            teacher_name=teacher_name,
            institution_name=profile.institution_name,
            class_code=profile.class_code,
            joined_at=association.created_at or datetime.now(timezone.utc),
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

