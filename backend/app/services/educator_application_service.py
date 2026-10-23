from datetime import date, datetime, timezone
from uuid import UUID
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.core.constants import MIN_AGE_YEARS, MAX_AGE_YEARS, calculate_age, validate_dob_range
from app.core.enums import UserRole
from app.models.educator_application import EducatorApplication
from app.models.notification import Notification
from app.models.role import Role
from app.models.teacher_profile import TeacherProfile
from app.models.user import User
from app.schemas.educator_application import EducatorApplicationCreate, EducatorApplicationResponse
from app.services.teacher_service import TeacherService


class EducatorApplicationService:
    @staticmethod
    def create_application(
        db: Session,
        user_id: UUID,
        data: EducatorApplicationCreate,
    ) -> EducatorApplicationResponse:
        user = db.scalar(select(User).where(User.id == user_id, User.is_active.is_(True)))
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found.",
            )

        # 1. Enforce date-of-birth range [17, 80]
        try:
            validate_dob_range(data.date_of_birth)
        except ValueError as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=str(e),
            )

        # 2. Recompute age from date of birth
        age = calculate_age(data.date_of_birth)

        # 3. Clean requested role
        clean_role = data.requested_role.strip().upper()
        if clean_role not in ["PROFESSOR", "ASSISTANT"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid requested role. Must be 'PROFESSOR' or 'ASSISTANT'.",
            )

        # 4. Enforce age gate: age > 25 -> PROFESSOR or ASSISTANT allowed; otherwise ASSISTANT only
        if age <= 25 and clean_role == "PROFESSOR":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Educators aged 25 and under are only eligible for the Assistant role.",
            )

        # 5. Check duplicate pending application -> 409
        pending_app = db.scalar(
            select(EducatorApplication).where(
                EducatorApplication.user_id == user.id,
                EducatorApplication.status == "PENDING",
            )
        )
        if pending_app:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="You already have a pending educator application under review.",
            )

        # 6. If user profile missing DOB, save to profile
        if not user.date_of_birth:
            user.date_of_birth = data.date_of_birth
            user.dob_source = "MANUAL"

        # 7. Create PENDING application. User role stays STUDENT.
        application = EducatorApplication(
            user_id=user.id,
            requested_role=clean_role,
            date_of_birth_at_application=data.date_of_birth,
            age_at_application=age,
            institution_name=data.institution_name.strip(),
            designation=data.designation.strip(),
            subject_expertise=data.subject_expertise.strip(),
            bio=data.bio.strip() if data.bio else None,
            supervisor_email=data.supervisor_email.strip() if data.supervisor_email else None,
            status="PENDING",
        )
        db.add(application)

        try:
            db.commit()
            db.refresh(application)
        except Exception:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to submit educator application.",
            )

        application.user = user
        return EducatorApplicationResponse.from_model(application)

    @staticmethod
    def get_user_application(
        db: Session,
        user_id: UUID,
    ) -> EducatorApplicationResponse | None:
        app = db.scalar(
            select(EducatorApplication)
            .options(selectinload(EducatorApplication.user))
            .where(EducatorApplication.user_id == user_id)
            .order_by(EducatorApplication.created_at.desc())
            .limit(1)
        )
        if not app:
            return None
        return EducatorApplicationResponse.from_model(app)

    @staticmethod
    def cancel_user_application(
        db: Session,
        user_id: UUID,
    ) -> EducatorApplicationResponse:
        app = db.scalar(
            select(EducatorApplication)
            .options(selectinload(EducatorApplication.user))
            .where(
                EducatorApplication.user_id == user_id,
                EducatorApplication.status == "PENDING",
            )
        )
        if not app:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No pending educator application found to cancel.",
            )

        app.status = "CANCELLED"
        try:
            db.commit()
            db.refresh(app)
        except Exception:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to cancel educator application.",
            )

        return EducatorApplicationResponse.from_model(app)

    @staticmethod
    def list_applications(
        db: Session,
        status_filter: str | None = "PENDING",
    ) -> list[EducatorApplicationResponse]:
        query = (
            select(EducatorApplication)
            .options(selectinload(EducatorApplication.user))
            .order_by(EducatorApplication.created_at.desc())
        )
        if status_filter and status_filter.upper() != "ALL":
            query = query.where(EducatorApplication.status == status_filter.upper())

        apps = db.scalars(query).all()
        return [EducatorApplicationResponse.from_model(a) for a in apps]

    @staticmethod
    def approve_application(
        db: Session,
        application_id: UUID,
        admin_user: User,
    ) -> EducatorApplicationResponse:
        app = db.scalar(
            select(EducatorApplication)
            .options(selectinload(EducatorApplication.user))
            .where(EducatorApplication.id == application_id)
        )
        if not app:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Educator application not found.",
            )

        if app.status != "PENDING":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot approve application with status '{app.status}'. Only PENDING applications can be approved.",
            )

        applicant = app.user
        if not applicant:
            applicant = db.scalar(select(User).where(User.id == app.user_id))

        teacher_role = db.scalar(
            select(Role).where(Role.name == UserRole.TEACHER.value)
        )
        if not teacher_role:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Teacher role not configured in database.",
            )

        # 1. Update application record
        app.status = "APPROVED"
        app.reviewed_at = datetime.now(timezone.utc)
        app.reviewed_by = admin_user.id

        # 2. Switch user role to TEACHER
        applicant.role_id = teacher_role.id
        applicant.role = teacher_role

        # 3. Create or activate teacher profile with is_verified = True
        profile = db.scalar(
            select(TeacherProfile).where(TeacherProfile.user_id == applicant.id)
        )
        desig = "Professor" if app.requested_role == "PROFESSOR" else "Teaching Assistant"
        if not profile:
            class_code = TeacherService._generate_unique_class_code(db, app.institution_name)
            profile = TeacherProfile(
                user_id=applicant.id,
                institution_name=app.institution_name,
                designation=desig,
                subject_expertise=app.subject_expertise,
                bio=app.bio,
                date_of_birth=app.date_of_birth_at_application,
                class_code=class_code,
                is_verified=True,
            )
            db.add(profile)
        else:
            profile.institution_name = app.institution_name
            profile.designation = desig
            profile.subject_expertise = app.subject_expertise
            if app.bio:
                profile.bio = app.bio
            if not profile.class_code:
                profile.class_code = TeacherService._generate_unique_class_code(db, app.institution_name)
            profile.is_verified = True

        # 4. In-app notification
        class_code_str = profile.class_code or ""
        notif = Notification(
            user_id=applicant.id,
            title="Educator Application Approved! 🎉",
            message=f"Congratulations! Your educator application for {app.requested_role.title()} has been approved. Your class code is {class_code_str}.",
            type="SYSTEM",
            is_read=False,
        )
        db.add(notif)

        try:
            db.commit()
            db.refresh(app)
        except Exception:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to approve educator application.",
            )

        return EducatorApplicationResponse.from_model(app)

    @staticmethod
    def reject_application(
        db: Session,
        application_id: UUID,
        admin_user: User,
        admin_note: str | None = None,
    ) -> EducatorApplicationResponse:
        app = db.scalar(
            select(EducatorApplication)
            .options(selectinload(EducatorApplication.user))
            .where(EducatorApplication.id == application_id)
        )
        if not app:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Educator application not found.",
            )

        if app.status != "PENDING":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot reject application with status '{app.status}'. Only PENDING applications can be rejected.",
            )

        app.status = "REJECTED"
        app.admin_note = admin_note.strip() if admin_note else None
        app.reviewed_at = datetime.now(timezone.utc)
        app.reviewed_by = admin_user.id

        # Notification to student
        note_text = f" Reason: {app.admin_note}" if app.admin_note else ""
        notif = Notification(
            user_id=app.user_id,
            title="Educator Application Update",
            message=f"Your application for educator status was not approved.{note_text} You may review your qualifications and reapply.",
            type="SYSTEM",
            is_read=False,
        )
        db.add(notif)

        try:
            db.commit()
            db.refresh(app)
        except Exception:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to reject educator application.",
            )

        return EducatorApplicationResponse.from_model(app)
