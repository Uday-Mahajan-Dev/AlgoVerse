import random
import string
from datetime import date, datetime, timezone
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.core.enums import UserRole
from app.models.role import Role
from app.models.student_teacher import StudentTeacher
from app.models.ta_approval_request import TAApprovalRequest
from app.models.teacher_profile import TeacherProfile
from app.models.user import User
from app.schemas.teachers import (
    EducatorRegistrationResponse,
    JoinClassResponse,
    MyTeacherResponse,
    TARequestResponse,
    TAResponseActionResult,
    TeacherListItem,
    TeacherProfileResponse,
    TeacherSelectionResponse,
)
from app.services.badge_service import BadgeService


class TeacherService:

    @staticmethod
    def _generate_unique_class_code(db: Session, institution_name: str | None = None) -> str:
        while True:
            code = "".join(random.choices(string.ascii_uppercase + string.digits, k=6))
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
                    designation=profile.designation if profile else None,
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
            professional_bio=profile.bio if profile and profile.bio else teacher.bio,
            country=teacher.country,
            student_count=student_count,
            specialty=specialty,
            institution_name=profile.institution_name if profile else None,
            designation=profile.designation if profile else None,
            subject_expertise=profile.subject_expertise if profile else None,
            class_code=profile.class_code if profile else None,
            instagram_url=teacher.instagram_url,
            linkedin_url=teacher.linkedin_url,
            created_at=teacher.created_at,
        )

    @staticmethod
    def register_educator(
        db: Session,
        user_id: UUID,
        institution_name: str,
        designation: str,
        subject_expertise: str,
        date_of_birth: date,
        supervisor_email: str | None = None,
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

        # Server-side age calculation
        today = date.today()
        age = today.year - date_of_birth.year - (
            (today.month, today.day) < (date_of_birth.month, date_of_birth.day)
        )

        clean_desig = designation.strip()
        is_ta = clean_desig.lower() == "teaching assistant"

        # Age gate validation
        if age < 25 and not is_ta:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Educators under 25 years old must register through the Teaching Assistant (TA) pathway with supervisor professor approval.",
            )

        # Update user DOB and Bio
        user.date_of_birth = date_of_birth
        if bio:
            user.bio = bio.strip()

        # TA Approval Pathway
        if age < 25 or is_ta:
            if not supervisor_email or not supervisor_email.strip():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="A valid supervising professor's email is required for Teaching Assistant applications or educators under 25.",
                )

            sup_email = supervisor_email.strip().lower()
            supervisor = db.scalar(
                select(User).where(
                    func.lower(User.email) == sup_email,
                    User.is_active.is_(True),
                )
            )
            if not supervisor:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"No educator account found with email '{supervisor_email}'. Please verify your professor's email.",
                )

            if supervisor.id == user.id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="You cannot specify yourself as your supervising professor.",
                )

            if supervisor.role_id != teacher_role.id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"The user with email '{supervisor_email}' does not have an active Educator role.",
                )

            # Create or update pending TA approval request
            existing_req = db.scalar(
                select(TAApprovalRequest).where(
                    TAApprovalRequest.applicant_id == user.id,
                    TAApprovalRequest.status == "PENDING",
                )
            )
            if existing_req:
                existing_req.supervisor_id = supervisor.id
                existing_req.institution_name = institution_name.strip()
                existing_req.designation = "Teaching Assistant"
                existing_req.subject_expertise = subject_expertise.strip()
                existing_req.bio = bio.strip() if bio else None
                existing_req.date_of_birth = date_of_birth
            else:
                new_req = TAApprovalRequest(
                    applicant_id=user.id,
                    supervisor_id=supervisor.id,
                    status="PENDING",
                    institution_name=institution_name.strip(),
                    designation="Teaching Assistant",
                    subject_expertise=subject_expertise.strip(),
                    bio=bio.strip() if bio else None,
                    date_of_birth=date_of_birth,
                )
                db.add(new_req)

            try:
                db.commit()
                db.refresh(user)
            except Exception:
                db.rollback()
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Failed to submit Teaching Assistant application.",
                )

            sup_name = f"{supervisor.first_name} {supervisor.last_name}".strip() or supervisor.username
            return EducatorRegistrationResponse(
                status="PENDING_SUPERVISOR_APPROVAL",
                message=f"Application submitted! Your request has been routed to Professor {sup_name} ({supervisor.email}) for review.",
                role=user.role.name if user.role else UserRole.STUDENT.value,
                class_code=None,
                institution_name=institution_name.strip(),
                designation="Teaching Assistant",
                subject_expertise=subject_expertise.strip(),
                bio=bio,
            )

        # Full Educator Instant Approval Pathway (Age >= 25 and non-TA designation)
        user.role_id = teacher_role.id
        user.role = teacher_role

        profile = db.scalar(
            select(TeacherProfile).where(TeacherProfile.user_id == user.id)
        )

        if not profile:
            class_code = TeacherService._generate_unique_class_code(db, institution_name)
            profile = TeacherProfile(
                user_id=user.id,
                institution_name=institution_name.strip(),
                designation=clean_desig,
                subject_expertise=subject_expertise.strip(),
                bio=bio.strip() if bio else None,
                date_of_birth=date_of_birth,
                class_code=class_code,
                is_verified=True,
            )
            db.add(profile)
        else:
            profile.institution_name = institution_name.strip()
            profile.designation = clean_desig
            profile.subject_expertise = subject_expertise.strip()
            profile.date_of_birth = date_of_birth
            if bio:
                profile.bio = bio.strip()
            if not profile.class_code:
                profile.class_code = TeacherService._generate_unique_class_code(db, institution_name)
            profile.is_verified = True

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

        # Award EDUCATOR badge
        BadgeService.award_badge_if_eligible(db, user.id, "EDUCATOR")

        return EducatorRegistrationResponse(
            status="APPROVED",
            message="Successfully verified and registered as educator.",
            role=UserRole.TEACHER.value,
            class_code=profile.class_code,
            institution_name=profile.institution_name,
            designation=profile.designation,
            subject_expertise=profile.subject_expertise,
            bio=profile.bio,
        )

    @staticmethod
    def get_ta_requests(
        db: Session,
        teacher_id: UUID,
    ) -> list[TARequestResponse]:
        requests = db.scalars(
            select(TAApprovalRequest)
            .where(TAApprovalRequest.supervisor_id == teacher_id)
            .order_by(TAApprovalRequest.requested_at.desc())
        ).all()

        results = []
        for r in requests:
            applicant = r.applicant
            app_name = f"{applicant.first_name} {applicant.last_name}".strip() if applicant else "Applicant"
            if not app_name and applicant:
                app_name = applicant.username

            results.append(
                TARequestResponse(
                    id=r.id,
                    applicant_id=r.applicant_id,
                    applicant_name=app_name,
                    applicant_email=applicant.email if applicant else "",
                    applicant_username=applicant.username if applicant else "",
                    applicant_avatar_url=applicant.avatar_url if applicant else None,
                    institution_name=r.institution_name,
                    designation=r.designation,
                    subject_expertise=r.subject_expertise,
                    bio=r.bio,
                    date_of_birth=r.date_of_birth,
                    status=r.status,
                    requested_at=r.requested_at,
                    responded_at=r.responded_at,
                )
            )
        return results

    @staticmethod
    def respond_to_ta_request(
        db: Session,
        teacher_id: UUID,
        request_id: UUID,
        action: str,
    ) -> TAResponseActionResult:
        req = db.scalar(
            select(TAApprovalRequest).where(
                TAApprovalRequest.id == request_id,
                TAApprovalRequest.supervisor_id == teacher_id,
            )
        )
        if not req:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="TA approval request not found or not assigned to you.",
            )

        if req.status != "PENDING":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"This request has already been resolved with status '{req.status}'.",
            )

        act = action.strip().upper()
        if act not in ["APPROVE", "REJECT"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Action must be either APPROVE or REJECT.",
            )

        req.responded_at = datetime.now(timezone.utc)

        if act == "APPROVE":
            req.status = "APPROVED"
            teacher_role = db.scalar(select(Role).where(Role.name == UserRole.TEACHER.value))
            if not teacher_role:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Teacher role not configured.",
                )

            applicant = db.scalar(select(User).where(User.id == req.applicant_id))
            if applicant:
                applicant.role_id = teacher_role.id
                applicant.role = teacher_role

                # Create or update applicant teacher profile
                profile = db.scalar(
                    select(TeacherProfile).where(TeacherProfile.user_id == applicant.id)
                )
                if not profile:
                    class_code = TeacherService._generate_unique_class_code(db, req.institution_name)
                    profile = TeacherProfile(
                        user_id=applicant.id,
                        institution_name=req.institution_name,
                        designation=req.designation,
                        subject_expertise=req.subject_expertise,
                        bio=req.bio,
                        date_of_birth=req.date_of_birth,
                        class_code=class_code,
                        supervisor_id=teacher_id,
                        is_verified=True,
                    )
                    db.add(profile)
                else:
                    profile.institution_name = req.institution_name
                    profile.designation = req.designation
                    profile.subject_expertise = req.subject_expertise
                    profile.bio = req.bio
                    profile.date_of_birth = req.date_of_birth
                    profile.supervisor_id = teacher_id
                    profile.is_verified = True
                    if not profile.class_code:
                        profile.class_code = TeacherService._generate_unique_class_code(db, req.institution_name)

                BadgeService.award_badge_if_eligible(db, applicant.id, "EDUCATOR")
        else:
            req.status = "REJECTED"

        try:
            db.commit()
            db.refresh(req)
        except Exception:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update TA request.",
            )

        return TAResponseActionResult(
            message=f"TA application has been {req.status.lower()} successfully.",
            request_id=req.id,
            status=req.status,
            applicant_id=req.applicant_id,
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

        # Award MENTOR_LINKED badge
        BadgeService.award_badge_if_eligible(db, student_id, "MENTOR_LINKED")

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

        # Award MENTOR_LINKED badge
        BadgeService.award_badge_if_eligible(db, student_id, "MENTOR_LINKED")

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
