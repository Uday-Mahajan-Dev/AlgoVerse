from fastapi import FastAPI
from starlette.middleware.sessions import SessionMiddleware

from app.api.router import api_router
from app.core.config import settings
from app.core.firebase import initialize_firebase


initialize_firebase()


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    debug=settings.DEBUG,
)


app.add_middleware(
    SessionMiddleware,
    secret_key=settings.SECRET_KEY,
    same_site="lax",
    https_only=False,
)


app.include_router(
    api_router,
    prefix=settings.API_V1_PREFIX,
)


@app.get("/")
def root():
    return {
        "message": "Welcome to AlgoVerse API"
    }
