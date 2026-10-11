from uuid import UUID
from fastapi import HTTPException, status
from sqlalchemy import or_, select
from sqlalchemy.orm import Session, selectinload

from app.models.teacher_profile import TeacherProfile
from app.models.user import User
from app.schemas.admin_educator import (
    EducatorVerificationActionResponse,
    PendingEducatorResponse,
)


class AdminEducatorService:
    @staticmethod
    def get_pending_educators(
        db: Session,
        include_all: bool = False,
    ) -> list[PendingEducatorResponse]:
        query = (
            select(TeacherProfile)
            .options(selectinload(TeacherProfile.user))
            .order_by(TeacherProfile.created_at.desc())
        )
        if not include_all:
            query = query.where(TeacherProfile.is_verified.is_(False))

        profiles = db.scalars(query).all()
        results: list[PendingEducatorResponse] = []
        for p in profiles:
            u = p.user
            full_name = f"{u.first_name or ''} {u.last_name or ''}".strip() if u else ""
            if not full_name and u:
                full_name = u.username
            results.append(
                PendingEducatorResponse(
                    id=p.id,
                    user_id=p.user_id,
                    name=full_name or "Faculty Member",
                    email=u.email if u else "",
                    institution=p.institution_name or "Not Specified",
                    designation=p.designation or "Professor",
                    applied_at=p.created_at,
                    is_verified=p.is_verified,
                )
            )
        return results

    @staticmethod
    def set_educator_verification(
        db: Session,
        educator_id: UUID,
        is_verified: bool,
    ) -> EducatorVerificationActionResponse:
        profile = db.scalar(
            select(TeacherProfile).where(
                or_(
                    TeacherProfile.id == educator_id,
                    TeacherProfile.user_id == educator_id,
                )
            )
        )
        if not profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Educator profile not found for id {educator_id}",
            )

        profile.is_verified = is_verified
        db.commit()
        db.refresh(profile)

        action_word = "verified" if is_verified else "revoked"
        return EducatorVerificationActionResponse(
            user_id=profile.user_id,
            is_verified=profile.is_verified,
            message=f"Educator verification successfully {action_word}.",
        )

    @staticmethod
    def verify_educator(db: Session, educator_id: UUID) -> EducatorVerificationActionResponse:
        return AdminEducatorService.set_educator_verification(db, educator_id, is_verified=True)

    @staticmethod
    def revoke_educator(db: Session, educator_id: UUID) -> EducatorVerificationActionResponse:
        return AdminEducatorService.set_educator_verification(db, educator_id, is_verified=False)
