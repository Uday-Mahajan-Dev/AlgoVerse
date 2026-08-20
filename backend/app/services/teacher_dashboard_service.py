from sqlalchemy.orm import Session

from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.teacher_dashboard import (
    TeacherDashboardResponseSchema,
    TeacherDashboardStatsSchema,
)


class TeacherDashboardService:

    @staticmethod
    def get_dashboard_data(
        db: Session,
        teacher: User,
    ) -> TeacherDashboardResponseSchema:
        total_students = UserRepository.count_students(db)
        active_students = UserRepository.count_active_students(db)

        stats = TeacherDashboardStatsSchema(
            total_students=total_students,
            active_students=active_students,
            average_mastery=0.0,
            problems_solved=0,
        )

        return TeacherDashboardResponseSchema(
            stats=stats,
            concept_performance=[],
            weak_concepts=[],
            recent_activity=[],
        )
