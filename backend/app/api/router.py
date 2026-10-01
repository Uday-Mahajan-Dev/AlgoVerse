from fastapi import APIRouter

from app.api.v1.auth.router import router as auth_router
from app.api.v1.courses.router import lesson_router
from app.api.v1.courses.router import router as courses_router
from app.api.v1.dashboard.router import router as dashboard_router
from app.api.v1.health.router import router as health_router
from app.api.v1.problems.router import router as problems_router
from app.api.v1.teachers.router import router as teachers_router

api_router = APIRouter()

api_router.include_router(health_router)
api_router.include_router(auth_router)
api_router.include_router(dashboard_router, prefix="/dashboard")
api_router.include_router(teachers_router, prefix="/teachers")
api_router.include_router(courses_router, prefix="/courses")
api_router.include_router(problems_router, prefix="/problems")
api_router.include_router(lesson_router)