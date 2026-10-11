from datetime import datetime, timezone
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.core.enums import UserRole
from app.models.mentorship_request import MentorshipRequest
from app.models.professor_rating import ProfessorRating
from app.models.role import Role
from app.models.student_teacher import StudentTeacher
from app.models.teacher_profile import TeacherProfile
from app.models.user import User
from app.schemas.mentorship import (
    ClassroomSettingsResponse,
    MentorshipRequestResponse,
    ProfessorListItem,
    StudentMentorItem,
)
from app.services.badge_service import BadgeService
from app.services.notification_service import NotificationService


class MentorshipService:

    @staticmethod
    def _format_request_response(
        req: MentorshipRequest,
        student: User | None = None,
        teacher: User | None = None,
        teacher_profile: TeacherProfile | None = None,
    ) -> MentorshipRequestResponse:
        s_user = student or req.student
        t_user = teacher or req.teacher

        s_name = (
            f"{s_user.first_name} {s_user.last_name}".strip()
            if s_user and (s_user.first_name or s_user.last_name)
            else (s_user.username if s_user else "Student")
        )
        t_name = (
            f"{t_user.first_name} {t_user.last_name}".strip()
            if t_user and (t_user.first_name or t_user.last_name)
            else (t_user.username if t_user else "Professor")
        )

        tp = teacher_profile or (t_user.teacher_profile if t_user else None)

        return MentorshipRequestResponse(
            id=req.id,
            student_id=req.student_id,
            teacher_id=req.teacher_id,
            class_code_attempted=req.class_code_attempted,
            status=req.status,
            message=req.message,
            created_at=req.created_at,
            resolved_at=req.resolved_at,
            resolved_by=req.resolved_by,
            student_name=s_name,
            student_username=s_user.username if s_user else "",
            student_email=s_user.email if s_user else "",
            student_avatar=s_user.avatar_url if s_user else None,
            teacher_name=t_name,
            teacher_username=t_user.username if t_user else "",
            teacher_institution=tp.institution_name if tp else None,
            teacher_designation=tp.designation if tp else None,
            teacher_avatar=t_user.avatar_url if t_user else None,
        )

    @staticmethod
    def create_request(
        db: Session,
        student_id: UUID,
        teacher_id: UUID | None = None,
        class_code: str | None = None,
        message: str | None = None,
    ) -> MentorshipRequestResponse:
        if not teacher_id and not class_code:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Either teacher_id or class_code must be provided.",
            )

        profile: TeacherProfile | None = None

        if class_code:
            clean_code = class_code.strip().upper()
            profile = db.scalar(
                select(TeacherProfile).where(
                    func.upper(TeacherProfile.class_code) == clean_code
                )
            )
            if not profile:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Class with code '{clean_code}' not found.",
                )
        elif teacher_id:
            profile = db.scalar(
                select(TeacherProfile).where(TeacherProfile.user_id == teacher_id)
            )
            if not profile:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Educator profile not found.",
                )

        if not profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Educator not found.",
            )

        if profile.user_id == student_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You cannot send a mentorship request to yourself.",
            )

        teacher_user = db.scalar(
            select(User).where(User.id == profile.user_id, User.is_active.is_(True))
        )
        if not teacher_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Educator account is inactive or not found.",
            )

        # Phase 7 rule: Unverified educators cannot accept students
        if not profile.is_verified:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This educator account is pending verification and cannot accept student requests yet.",
            )

        # Classroom settings check: is accepting requests
        if not profile.is_accepting_requests:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Educator is currently not accepting new mentorship requests.",
            )

        # Capacity check
        current_enrolled_count = (
            db.scalar(
                select(func.count(StudentTeacher.id)).where(
                    StudentTeacher.teacher_id == profile.user_id
                )
            )
            or 0
        )
        if not profile.is_verified:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Educator is pending administrator verification. Classroom joining code is inactive.",
            )

        if current_enrolled_count >= profile.max_students:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Classroom has reached maximum capacity ({current_enrolled_count}/{profile.max_students} students). New requests are blocked.",
            )

        # Check if already linked as mentee
        existing_link = db.scalar(
            select(StudentTeacher).where(
                StudentTeacher.student_id == student_id,
                StudentTeacher.teacher_id == profile.user_id,
            )
        )
        if existing_link:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You are already enrolled with this educator.",
            )

        # Check if pending request already exists
        pending_request = db.scalar(
            select(MentorshipRequest).where(
                MentorshipRequest.student_id == student_id,
                MentorshipRequest.teacher_id == profile.user_id,
                MentorshipRequest.status == "PENDING",
            )
        )
        if pending_request:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You already have a pending mentorship request with this educator.",
            )

        # Create new request
        new_request = MentorshipRequest(
            student_id=student_id,
            teacher_id=profile.user_id,
            class_code_attempted=profile.class_code if class_code else None,
            status="PENDING",
            message=message.strip() if message else None,
        )
        db.add(new_request)

        try:
            db.commit()
            db.refresh(new_request)
        except Exception:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to submit mentorship request.",
            )

        student_user = db.scalar(select(User).where(User.id == student_id))
        s_name = (
            f"{student_user.first_name} {student_user.last_name}".strip()
            if student_user and (student_user.first_name or student_user.last_name)
            else (student_user.username if student_user else "A student")
        )

        # Notify educator
        try:
            NotificationService.create_notification(
                db=db,
                user_id=profile.user_id,
                title="New Mentorship Request",
                message=f"{s_name} has requested to join your classroom.",
                type="SYSTEM",
            )
        except Exception:
            pass

        return MentorshipService._format_request_response(
            new_request,
            student=student_user,
            teacher=teacher_user,
            teacher_profile=profile,
        )

    @staticmethod
    def get_student_requests(
        db: Session,
        student_id: UUID,
    ) -> list[MentorshipRequestResponse]:
        requests = db.scalars(
            select(MentorshipRequest)
            .where(MentorshipRequest.student_id == student_id)
            .order_by(MentorshipRequest.created_at.desc())
        ).all()

        return [MentorshipService._format_request_response(r) for r in requests]

    @staticmethod
    def get_teacher_requests(
        db: Session,
        teacher_id: UUID,
        status_filter: str | None = None,
    ) -> list[MentorshipRequestResponse]:
        query = select(MentorshipRequest).where(
            MentorshipRequest.teacher_id == teacher_id
        )
        if status_filter and status_filter.upper() != "ALL":
            query = query.where(MentorshipRequest.status == status_filter.upper())

        requests = db.scalars(query.order_by(MentorshipRequest.created_at.desc())).all()
        return [MentorshipService._format_request_response(r) for r in requests]

    @staticmethod
    def approve_request(
        db: Session,
        request_id: UUID,
        teacher_id: UUID,
    ) -> MentorshipRequestResponse:
        req = db.scalar(
            select(MentorshipRequest).where(
                MentorshipRequest.id == request_id,
                MentorshipRequest.teacher_id == teacher_id,
            )
        )
        if not req:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Mentorship request not found.",
            )

        if req.status != "PENDING":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot approve request: Status is already {req.status}.",
            )

        profile = db.scalar(
            select(TeacherProfile).where(TeacherProfile.user_id == teacher_id)
        )
        if not profile or not profile.is_verified:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Faculty account requires administrator verification before approving requests.",
            )
        max_allowed = profile.max_students if profile else 100

        current_count = (
            db.scalar(
                select(func.count(StudentTeacher.id)).where(
                    StudentTeacher.teacher_id == teacher_id
                )
            )
            or 0
        )

        if current_count >= max_allowed:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot approve request: Classroom has reached maximum capacity ({current_count}/{max_allowed} students).",
            )

        now = datetime.now(timezone.utc)
        req.status = "APPROVED"
        req.resolved_at = now
        req.resolved_by = teacher_id

        # Insert or update StudentTeacher link
        existing = db.scalar(
            select(StudentTeacher).where(
                StudentTeacher.student_id == req.student_id,
                StudentTeacher.teacher_id == teacher_id,
            )
        )
        if not existing:
            link = StudentTeacher(
                student_id=req.student_id,
                teacher_id=teacher_id,
                approved_at=now,
                request_id=req.id,
            )
            db.add(link)

        try:
            db.commit()
            db.refresh(req)
        except Exception:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to approve mentorship request.",
            )

        # Award badge to student
        BadgeService.award_badge_if_eligible(db, req.student_id, "MENTOR_LINKED")

        # Notify student
        teacher_user = db.scalar(select(User).where(User.id == teacher_id))
        t_name = (
            f"Professor {teacher_user.first_name} {teacher_user.last_name}".strip()
            if teacher_user and (teacher_user.first_name or teacher_user.last_name)
            else (teacher_user.username if teacher_user else "Your educator")
        )

        try:
            NotificationService.create_notification(
                db=db,
                user_id=req.student_id,
                title="Mentorship Request Approved",
                message=f"Congratulations! {t_name} has approved your mentorship request.",
                type="SYSTEM",
            )
        except Exception:
            pass

        return MentorshipService._format_request_response(req)

    @staticmethod
    def reject_request(
        db: Session,
        request_id: UUID,
        teacher_id: UUID,
    ) -> MentorshipRequestResponse:
        req = db.scalar(
            select(MentorshipRequest).where(
                MentorshipRequest.id == request_id,
                MentorshipRequest.teacher_id == teacher_id,
            )
        )
        if not req:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Mentorship request not found.",
            )

        if req.status != "PENDING":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot reject request: Status is already {req.status}.",
            )

        profile = db.scalar(
            select(TeacherProfile).where(TeacherProfile.user_id == teacher_id)
        )
        if not profile or not profile.is_verified:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Faculty account requires administrator verification before rejecting requests.",
            )

        now = datetime.now(timezone.utc)
        req.status = "REJECTED"
        req.resolved_at = now
        req.resolved_by = teacher_id

        try:
            db.commit()
            db.refresh(req)
        except Exception:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to reject mentorship request.",
            )

        teacher_user = db.scalar(select(User).where(User.id == teacher_id))
        t_name = (
            f"Professor {teacher_user.first_name} {teacher_user.last_name}".strip()
            if teacher_user and (teacher_user.first_name or teacher_user.last_name)
            else (teacher_user.username if teacher_user else "Educator")
        )

        try:
            NotificationService.create_notification(
                db=db,
                user_id=req.student_id,
                title="Mentorship Request Declined",
                message=f"Your mentorship request to {t_name} was declined.",
                type="SYSTEM",
            )
        except Exception:
            pass

        return MentorshipService._format_request_response(req)

    @staticmethod
    def get_classroom_settings(
        db: Session,
        teacher_id: UUID,
    ) -> ClassroomSettingsResponse:
        profile = db.scalar(
            select(TeacherProfile).where(TeacherProfile.user_id == teacher_id)
        )
        if not profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Teacher profile not found.",
            )

        current_count = (
            db.scalar(
                select(func.count(StudentTeacher.id)).where(
                    StudentTeacher.teacher_id == teacher_id
                )
            )
            or 0
        )

        capacity_pct = (
            round((current_count / profile.max_students) * 100, 1)
            if profile.max_students > 0
            else 0.0
        )

        display_code = profile.class_code if profile.is_verified else "PENDING_VERIFICATION"
        return ClassroomSettingsResponse(
            teacher_id=teacher_id,
            max_students=profile.max_students,
            is_accepting_requests=profile.is_accepting_requests and profile.is_verified,
            current_student_count=current_count,
            capacity_pct=capacity_pct,
            class_code=display_code,
        )

    @staticmethod
    def update_classroom_settings(
        db: Session,
        teacher_id: UUID,
        max_students: int | None = None,
        is_accepting_requests: bool | None = None,
    ) -> ClassroomSettingsResponse:
        profile = db.scalar(
            select(TeacherProfile).where(TeacherProfile.user_id == teacher_id)
        )
        if not profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Teacher profile not found.",
            )

        if max_students is not None:
            if max_students < 1:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Classroom capacity must be at least 1 student.",
                )
            profile.max_students = max_students

        if is_accepting_requests is not None:
            profile.is_accepting_requests = is_accepting_requests

        try:
            db.commit()
            db.refresh(profile)
        except Exception:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update classroom settings.",
            )

        current_count = (
            db.scalar(
                select(func.count(StudentTeacher.id)).where(
                    StudentTeacher.teacher_id == teacher_id
                )
            )
            or 0
        )

        capacity_pct = (
            round((current_count / profile.max_students) * 100, 1)
            if profile.max_students > 0
            else 0.0
        )

        return ClassroomSettingsResponse(
            teacher_id=teacher_id,
            max_students=profile.max_students,
            is_accepting_requests=profile.is_accepting_requests,
            current_student_count=current_count,
            capacity_pct=capacity_pct,
            class_code=profile.class_code,
        )

    @staticmethod
    def get_professors_directory(
        db: Session,
        search_query: str | None = None,
        verified_only: bool = True,
    ) -> list[ProfessorListItem]:
        teacher_role = db.scalar(select(Role).where(Role.name == UserRole.TEACHER.value))
        if not teacher_role:
            return []

        query = (
            select(
                User,
                TeacherProfile,
                func.count(StudentTeacher.id).label("student_count"),
            )
            .join(TeacherProfile, TeacherProfile.user_id == User.id)
            .outerjoin(StudentTeacher, StudentTeacher.teacher_id == User.id)
            .where(User.role_id == teacher_role.id, User.is_active.is_(True))
            .group_by(User.id, TeacherProfile.id)
        )

        if verified_only:
            query = query.where(TeacherProfile.is_verified.is_(True))

        if search_query:
            term = f"%{search_query.strip()}%"
            query = query.where(
                or_(
                    User.username.ilike(term),
                    User.first_name.ilike(term),
                    User.last_name.ilike(term),
                    TeacherProfile.institution_name.ilike(term),
                    TeacherProfile.designation.ilike(term),
                    TeacherProfile.subject_expertise.ilike(term),
                )
            )

        rows = db.execute(query).all()

        # Aggregate ratings per teacher
        rating_stats_map: dict[UUID, tuple[float, int]] = {}
        rating_rows = db.execute(
            select(
                ProfessorRating.teacher_id,
                func.avg(ProfessorRating.rating).label("avg_rating"),
                func.count(ProfessorRating.id).label("rating_count"),
            ).group_by(ProfessorRating.teacher_id)
        ).all()
        for t_id, avg_r, cnt in rating_rows:
            rating_stats_map[t_id] = (
                round(float(avg_r), 1) if avg_r else 0.0,
                int(cnt or 0),
            )

        results: list[ProfessorListItem] = []
        for user, profile, count in rows:
            specialty = (
                profile.subject_expertise
                if profile and profile.subject_expertise
                else (user.bio if user.bio else "Data Structures & Algorithms")
            )
            r_avg, r_count = rating_stats_map.get(user.id, (0.0, 0))
            results.append(
                ProfessorListItem(
                    id=user.id,
                    first_name=user.first_name or user.username,
                    last_name=user.last_name or "",
                    username=user.username,
                    avatar_url=user.avatar_url,
                    institution_name=profile.institution_name if profile else None,
                    designation=profile.designation if profile else None,
                    specialty=specialty,
                    student_count=int(count),
                    max_students=profile.max_students if profile else 100,
                    is_accepting_requests=profile.is_accepting_requests if profile else True,
                    is_verified=profile.is_verified if profile else False,
                    rating_avg=r_avg,
                    avg_rating=r_avg,
                    rating_count=r_count,
                    class_code=profile.class_code if profile else None,
                )
            )

        return results

    @staticmethod
    def get_my_mentors(
        db: Session,
        student_id: UUID,
    ) -> list[StudentMentorItem]:
        links = (
            db.execute(
                select(StudentTeacher, User, TeacherProfile)
                .join(User, User.id == StudentTeacher.teacher_id)
                .outerjoin(TeacherProfile, TeacherProfile.user_id == User.id)
                .where(
                    StudentTeacher.student_id == student_id,
                    User.is_active.is_(True),
                )
                .order_by(StudentTeacher.approved_at.desc())
            )
            .all()
        )

        mentors: list[StudentMentorItem] = []
        for link, teacher, profile in links:
            t_name = (
                f"{teacher.first_name} {teacher.last_name}".strip()
                if (teacher.first_name or teacher.last_name)
                else teacher.username
            )
            mentors.append(
                StudentMentorItem(
                    teacher_id=teacher.id,
                    teacher_name=t_name,
                    teacher_username=teacher.username,
                    teacher_avatar=teacher.avatar_url,
                    institution_name=profile.institution_name if profile else None,
                    designation=profile.designation if profile else None,
                    specialty=profile.subject_expertise if profile else None,
                    class_code=profile.class_code if profile else None,
                    approved_at=link.approved_at,
                )
            )

        return mentors
