import os
import json
import logging
import firebase_admin
from firebase_admin import credentials

from app.core.config import settings

logger = logging.getLogger(__name__)


def initialize_firebase():
    if firebase_admin._apps:
        return firebase_admin.get_app()

    cert_path = os.getenv(
        "FIREBASE_SERVICE_ACCOUNT_FILE",
        settings.FIREBASE_CREDENTIALS_PATH or "firebase-service-account.json",
    )
    cert_json_env = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")

    cred = None
    if cert_json_env:
        try:
            cred_dict = json.loads(cert_json_env)
            cred = credentials.Certificate(cred_dict)
            logger.info(
                "Initializing Firebase Admin using FIREBASE_SERVICE_ACCOUNT_JSON env var."
            )
        except Exception as e:
            logger.error(
                f"Failed to parse FIREBASE_SERVICE_ACCOUNT_JSON: {e}"
            )

    if not cred and os.path.exists(cert_path):
        try:
            cred = credentials.Certificate(cert_path)
            logger.info(f"Initializing Firebase Admin using file: {cert_path}")
        except Exception as e:
            logger.error(
                f"Failed to load Firebase cert file {cert_path}: {e}"
            )

    if cred:
        return firebase_admin.initialize_app(cred)
    else:
        logger.warning(
            "Firebase credentials not found (neither valid file nor FIREBASE_SERVICE_ACCOUNT_JSON env var). "
            "Firebase Admin SDK initialized in default mode."
        )
        try:
            return firebase_admin.initialize_app()
        except Exception as e:
            logger.error(f"Failed to initialize default Firebase app: {e}")
            return None
