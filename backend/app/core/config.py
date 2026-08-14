from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # ==========================================
    # Application
    # ==========================================

    APP_NAME: str = "AlgoVerse API"
    APP_VERSION: str = "v1"
    DEBUG: bool = True

    API_V1_PREFIX: str = "/api/v1"

    # ==========================================
    # Database
    # ==========================================

    DATABASE_URL: str

    # ==========================================
    # JWT Authentication
    # ==========================================

    SECRET_KEY: str
    ALGORITHM: str = "HS256"

    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # ==========================================
    # Email OTP
    # ==========================================

    EMAIL_OTP_EXPIRE_MINUTES: int = 10
    EMAIL_OTP_MAX_ATTEMPTS: int = 5

    EMAIL_HOST: str = ""
    EMAIL_PORT: int = 587
    EMAIL_USERNAME: str = ""
    EMAIL_PASSWORD: str = ""
    EMAIL_FROM: str = ""
    EMAIL_FROM_NAME: str = "AlgoVerse"
    EMAIL_USE_TLS: bool = True

    EMAIL_OTP_RESEND_COOLDOWN_SECONDS: int = 60


    # ==========================================
    # Teacher Invitations
    # ==========================================

    TEACHER_INVITATION_EXPIRE_HOURS: int = 48

    TEACHER_INVITATION_BASE_URL: str = (
        "http://localhost:3000/teacher-invitation"
    )


    # ==========================================
    # Firebase
    # ==========================================

    FIREBASE_CREDENTIALS_PATH: str = "firebase-service-account.json"

    # ==========================================
    # Settings
    # ==========================================

    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore",
    )


settings = Settings()
