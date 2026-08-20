from fastapi import APIRouter

from app.api.v1.auth.router import router as auth_router
from app.api.v1.health.router import router as health_router
from app.api.v1.teacher.dashboard import router as teacher_dashboard_router

api_router = APIRouter()

api_router.include_router(health_router)
api_router.include_router(auth_router)
api_router.include_router(teacher_dashboard_router)