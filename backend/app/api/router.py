from fastapi import APIRouter

from app.api.v1.ai.router import router as ai_router
from app.api.v1.auth.router import router as auth_router
from app.api.v1.badges.router import router as badges_router
from app.api.v1.courses.router import lesson_router
from app.api.v1.courses.router import router as courses_router
from app.api.v1.dashboard.router import router as dashboard_router
from app.api.v1.health.router import router as health_router
from app.api.v1.notifications.router import router as notifications_router
from app.api.v1.problems.router import router as problems_router
from app.api.v1.quizzes.router import router as quizzes_router
from app.api.v1.students.router import router as students_router
from app.api.v1.teachers.router import router as teachers_router
from app.api.v1.users.router import router as users_router

api_router = APIRouter()

api_router.include_router(health_router)
api_router.include_router(auth_router)
api_router.include_router(users_router)
api_router.include_router(students_router, prefix="/students")
api_router.include_router(notifications_router, prefix="/notifications")
api_router.include_router(badges_router, prefix="/badges")


api_router.include_router(dashboard_router, prefix="/dashboard")
api_router.include_router(teachers_router, prefix="/teachers")
api_router.include_router(quizzes_router, prefix="/quizzes")
api_router.include_router(courses_router, prefix="/courses")
api_router.include_router(problems_router, prefix="/problems")
api_router.include_router(ai_router, prefix="/ai")
api_router.include_router(lesson_router)