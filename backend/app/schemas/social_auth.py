from pydantic import BaseModel


class SocialLoginRequest(BaseModel):
    id_token: str
