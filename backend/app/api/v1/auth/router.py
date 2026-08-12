from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import (
    get_db,
    get_current_user,
)
from app.models.user import User
from app.schemas.auth import (
    LoginRequest,
    RegisterRequest,
    RegisterResponse,
    VerifyEmailRequest,
)
from app.schemas.logout import LogoutRequest
from app.schemas.refresh import RefreshRequest
from app.schemas.token import Token
from app.schemas.user import UserResponse
from app.services.auth_service import AuthService


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
    return current_user