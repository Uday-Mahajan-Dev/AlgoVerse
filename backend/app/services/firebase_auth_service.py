from firebase_admin import auth


class FirebaseAuthService:

    @staticmethod
    def verify_id_token(id_token: str) -> dict:
        try:
            return auth.verify_id_token(id_token)
        except Exception:
            raise ValueError("Invalid Firebase ID token.")
