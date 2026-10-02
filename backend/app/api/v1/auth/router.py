from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import (
    get_current_admin,
    get_current_user,
    get_db,
)
from app.models.user import User
from app.schemas.auth import (
    LoginRequest,
    RegisterRequest,
    RegisterResponse,
    ResendVerificationRequest,
    VerifyEmailRequest,
)
from app.schemas.logout import LogoutRequest
from app.schemas.refresh import RefreshRequest
from app.schemas.social_auth import SocialLoginRequest
from app.schemas.teacher_invitation import (
    TeacherInvitationAcceptResponse,
    TeacherInvitationCreate,
    TeacherInvitationResponse,
)
from app.schemas.token import Token
from app.schemas.user import UserResponse
from app.services.auth_service import AuthService
from app.services.social_auth_service import SocialAuthService
from app.services.teacher_invitation_service import (
    TeacherInvitationService,
)


router = APIRouter(
    prefix="/auth",
    tags=["Authentication"],
)


@router.post(
    "/register",
    response_model=RegisterResponse,
    status_code=201,
)
def register(
    data: RegisterRequest,
    db: Session = Depends(get_db),
):
    AuthService.register(
        db=db,
        data=data,
    )

    return RegisterResponse(
        message="Registration successful. Please verify your email.",
        email=data.email,
    )


@router.post(
    "/verify-email",
    response_model=UserResponse,
)
def verify_email(
    data: VerifyEmailRequest,
    db: Session = Depends(get_db),
):
    return AuthService.verify_email(
        db=db,
        email=data.email,
        otp=data.otp,
    )


@router.post("/resend-verification")
def resend_verification(
    data: ResendVerificationRequest,
    db: Session = Depends(get_db),
):
    AuthService.resend_verification(
        db=db,
        email=data.email,
    )

    return {
        "message": "A new verification code has been sent."
    }


@router.post(
    "/login",
    response_model=Token,
)
def login(
    data: LoginRequest,
    db: Session = Depends(get_db),
):
    return AuthService.login(
        db=db,
        data=data,
    )


@router.post(
    "/social-login",
    response_model=Token,
)
def social_login(
    data: SocialLoginRequest,
    db: Session = Depends(get_db),
):
    return SocialAuthService.login(
        db=db,
        id_token=data.id_token,
    )


@router.post(
    "/google",
    response_model=Token,
)
def google_login(
    data: SocialLoginRequest,
    db: Session = Depends(get_db),
):
    return SocialAuthService.login(
        db=db,
        id_token=data.id_token,
    )


@router.post(
    "/teacher-invitations",
    response_model=TeacherInvitationResponse,
    status_code=201,
)
def create_teacher_invitation(
    data: TeacherInvitationCreate,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    invitation = TeacherInvitationService.create_invitation(
        db=db,
        email=data.email,
        invited_by=current_admin.id,
    )

    return TeacherInvitationResponse(
        message="Teacher invitation sent successfully.",
        email=invitation.email,
    )


@router.get(
    "/teacher-invitations/accept",
    response_model=TeacherInvitationAcceptResponse,
)
def accept_teacher_invitation(
    token: str = Query(...),
    db: Session = Depends(get_db),
):
    invitation = TeacherInvitationService.accept_invitation(
        db=db,
        raw_token=token,
    )

    return TeacherInvitationAcceptResponse(
        message=(
            "Teacher invitation accepted. "
            "Please sign in using this email address."
        ),
        email=invitation.email,
        status=invitation.status,
        expires_at=invitation.expires_at,
    )


@router.post(
    "/refresh",
    response_model=Token,
)
def refresh(
    data: RefreshRequest,
    db: Session = Depends(get_db),
):
    return AuthService.refresh(
        db=db,
        refresh_token=data.refresh_token,
    )


@router.post("/logout")
def logout(
    data: LogoutRequest,
    db: Session = Depends(get_db),
):
    AuthService.logout(
        db=db,
        refresh_token=data.refresh_token,
    )

    return {
        "message": "Logged out successfully."
    }


@router.get(
    "/me",
    response_model=UserResponse,
)
def me(
    current_user: User = Depends(get_current_user),
):
    return UserResponse.from_user(current_user)
