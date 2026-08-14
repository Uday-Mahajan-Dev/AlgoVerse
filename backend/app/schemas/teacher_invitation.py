
from datetime import datetime

from pydantic import BaseModel, EmailStr


class TeacherInvitationCreate(BaseModel):
    email: EmailStr


class TeacherInvitationResponse(BaseModel):
    message: str
    email: EmailStr


class TeacherInvitationAcceptResponse(BaseModel):
    message: str
    email: EmailStr
    status: str
    expires_at: datetime

