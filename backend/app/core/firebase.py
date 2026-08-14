import firebase_admin
from firebase_admin import credentials

from app.core.config import settings


def initialize_firebase() -> None:
    if firebase_admin._apps:
        return

    credential = credentials.Certificate(
        settings.FIREBASE_CREDENTIALS_PATH
    )

    firebase_admin.initialize_app(credential)
