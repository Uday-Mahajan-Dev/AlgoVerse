from uuid import UUID
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_admin, get_db
from app.models.user import User
from app.schemas.admin_educator import (
    EducatorVerificationActionResponse,
    PendingEducatorResponse,
)
from app.services.admin_educator_service import AdminEducatorService
from app.api.v1.admin.teacher_invitations import router as teacher_invitations_router

router = APIRouter(
    tags=["Admin"],
)

router.include_router(teacher_invitations_router)


@router.get(
    "/educators/pending",
    response_model=list[PendingEducatorResponse],
    summary="List all pending educators awaiting verification (Admin only)",
)
def get_pending_educators(
    include_all: bool = Query(default=False, description="Include all educators, not just pending"),
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    return AdminEducatorService.get_pending_educators(
        db=db,
        include_all=include_all,
    )


@router.post(
    "/educators/{educator_id}/verify",
    response_model=EducatorVerificationActionResponse,
    summary="Verify an educator account (Admin only)",
)
def verify_educator(
    educator_id: UUID,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    return AdminEducatorService.set_educator_verification(
        db=db,
        educator_id=educator_id,
        is_verified=True,
    )


@router.post(
    "/educators/{educator_id}/revoke",
    response_model=EducatorVerificationActionResponse,
    summary="Revoke an educator verification (Admin only)",
)
def revoke_educator(
    educator_id: UUID,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    return AdminEducatorService.set_educator_verification(
        db=db,
        educator_id=educator_id,
        is_verified=False,
    )


# ============================================================
# EDUCATOR APPLICATIONS (ADMIN APPROVAL WORKFLOW)
# ============================================================

from app.schemas.educator_application import (
    EducatorApplicationRejectRequest,
    EducatorApplicationResponse,
)
from app.services.educator_application_service import EducatorApplicationService


@router.get(
    "/educator-applications",
    response_model=list[EducatorApplicationResponse],
    summary="List educator applications (Admin only)",
)
def list_educator_applications(
    status: str | None = Query(default="PENDING", description="Filter by status: PENDING, APPROVED, REJECTED, or ALL"),
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    return EducatorApplicationService.list_applications(
        db=db,
        status_filter=status,
    )


@router.post(
    "/educator-applications/{application_id}/approve",
    response_model=EducatorApplicationResponse,
    summary="Approve an educator application (Admin only)",
)
def approve_educator_application(
    application_id: UUID,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    return EducatorApplicationService.approve_application(
        db=db,
        application_id=application_id,
        admin_user=current_admin,
    )


@router.post(
    "/educator-applications/{application_id}/reject",
    response_model=EducatorApplicationResponse,
    summary="Reject an educator application (Admin only)",
)
def reject_educator_application(
    application_id: UUID,
    request: EducatorApplicationRejectRequest,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    return EducatorApplicationService.reject_application(
        db=db,
        application_id=application_id,
        admin_user=current_admin,
        admin_note=request.admin_note,
    )
