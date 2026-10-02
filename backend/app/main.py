from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
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
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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


@app.get("/health")
def health():
    return {
        "status": "ok"
    }


@app.get("/")
def root():
    return {
        "message": "Welcome to AlgoVerse API"
    }
