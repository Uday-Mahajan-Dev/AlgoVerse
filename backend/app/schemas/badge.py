from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class BadgeResponse(BaseModel):
    id: UUID
    code: str
    title: str
    description: str
    icon_key: str
    category: str
    target_role: str = "ALL"

    model_config = ConfigDict(from_attributes=True)


class UserBadgeResponse(BaseModel):
    id: UUID
    code: str
    title: str
    description: str
    icon_key: str
    category: str
    target_role: str = "ALL"
    is_earned: bool = False
    earned_at: datetime | None = None

    model_config = ConfigDict(from_attributes=True)
