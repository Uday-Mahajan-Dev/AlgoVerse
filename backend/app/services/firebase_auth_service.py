import logging
import requests
from firebase_admin import auth

logger = logging.getLogger(__name__)


class FirebaseAuthService:

    @staticmethod
    def verify_id_token(id_token: str) -> dict:
        if not id_token or not id_token.strip():
            raise ValueError("ID token is empty.")

        # 1. Try Firebase Admin SDK verification
        try:
            decoded = auth.verify_id_token(id_token)
            if decoded and decoded.get("email"):
                sign_in_provider = (
                    decoded.get("firebase", {})
                    .get("sign_in_provider", "google")
                )
                decoded["provider"] = (
                    "google"
                    if "google" in sign_in_provider
                    else (
                        "github"
                        if "github" in sign_in_provider
                        else sign_in_provider
                    )
                )
                return decoded
        except Exception as e:
            logger.warning(
                f"Firebase Admin SDK verification failed ({e}). Attempting Google tokeninfo fallback..."
            )

        # 2. Fallback: Verify Google ID token via Google OAuth2 tokeninfo endpoint
        try:
            resp = requests.get(
                f"https://oauth2.googleapis.com/tokeninfo?id_token={id_token}",
                timeout=6.0,
            )
            if resp.status_code == 200:
                data = resp.json()
                email = data.get("email")
                uid = data.get("sub") or data.get("user_id")
                if email and uid:
                    return {
                        "uid": uid,
                        "email": email,
                        "name": data.get("name") or email.split("@")[0],
                        "given_name": data.get("given_name", ""),
                        "family_name": data.get("family_name", ""),
                        "picture": data.get("picture", ""),
                        "provider": "google",
                    }
        except Exception as e:
            logger.warning(f"Google tokeninfo endpoint failed: {e}")

        raise ValueError("Google authentication failed on server")
