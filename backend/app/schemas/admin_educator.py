from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, ConfigDict


class PendingEducatorResponse(BaseModel):
    id: UUID
    user_id: UUID
    name: str
    email: str
    institution: str
    designation: str
    applied_at: datetime
    is_verified: bool

    model_config = ConfigDict(from_attributes=True)


class EducatorVerificationActionResponse(BaseModel):
    user_id: UUID
    is_verified: bool
    message: str
