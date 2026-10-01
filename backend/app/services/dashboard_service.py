from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.enums import UserRole
from app.models.role import Role
from app.models.user import User
from app.schemas.dashboard import (
    ConceptPerformance,
    StudentContinueLearning,
    StudentDailyMission,
    StudentDashboardResponse,
    StudentLevelXp,
    StudentNextAchievement,
    StudentPerformanceStats,
    StudentRecentActivity,
    StudentUserSummary,
    StudentWeeklyChallenge,
    TeacherDashboardResponse,
    TeacherRecentActivity,
    TeacherStats,
    WeakConcept,
)


class DashboardService:

    @staticmethod
    def get_student_dashboard(
        db: Session,
        user: User,
    ) -> StudentDashboardResponse:
        first_name = user.first_name if user.first_name else user.username
        last_name = user.last_name if user.last_name else ""

        user_summary = StudentUserSummary(
            id=user.id,
            username=user.username,
            first_name=first_name,
            last_name=last_name,
            email=user.email,
            avatar_url=user.avatar_url,
        )

        level_xp = StudentLevelXp(
            current_level=12,
            current_xp=780,
            next_level_xp=1000,
            xp_to_next_level=220,
            progress=0.78,
        )

        continue_learning = StudentContinueLearning(
            category="DATA STRUCTURES & ALGORITHMS",
            topic="Binary Trees",
            progress=0.72,
            progress_text="72% COMPLETE",
        )

        daily_missions = [
            StudentDailyMission(
                number="01",
                title="Solve 3 Problems",
                progress_text="2 / 3",
                progress=0.66,
                reward="50 XP",
                icon="code",
            ),
            StudentDailyMission(
                number="02",
                title="Complete a Lesson",
                progress_text="0 / 1",
                progress=0.0,
                reward="30 XP",
                icon="book",
            ),
            StudentDailyMission(
                number="03",
                title="Daily Challenge",
                progress_text="AVAILABLE",
                progress=0.0,
                reward="75 XP",
                icon="target",
            ),
        ]

        performance = StudentPerformanceStats(
            day_streak=12,
            total_xp=1240,
        )

        next_achievement = StudentNextAchievement(
            title="PROBLEM SOLVER",
            description="Solve 100 problems to unlock this achievement.",
            current_count=87,
            target_count=100,
            progress=0.87,
            progress_text="87 / 100 PROBLEMS",
            remaining_text="13 PROBLEMS TO UNLOCK",
        )

        weekly_challenge = StudentWeeklyChallenge(
            title="ALGORITHM SPRINT",
            description="Solve 10 problems this week.",
            current_count=7,
            target_count=10,
            reward="200 XP",
            progress=0.7,
            progress_text="7 / 10 COMPLETE",
        )

        recent_activities = [
            StudentRecentActivity(
                title="Solved Two Sum",
                xp="+20 XP",
                icon="code",
            ),
            StudentRecentActivity(
                title="Completed Arrays Basics",
                xp="+30 XP",
                icon="book",
            ),
            StudentRecentActivity(
                title="Reached Level 12",
                xp="+100 XP",
                icon="badge",
            ),
        ]

        return StudentDashboardResponse(
            user=user_summary,
            level_xp=level_xp,
            continue_learning=continue_learning,
            daily_missions=daily_missions,
            performance=performance,
            next_achievement=next_achievement,
            weekly_challenge=weekly_challenge,
            recent_activities=recent_activities,
        )

    @staticmethod
    def get_teacher_dashboard(
        db: Session,
        teacher: User,
    ) -> TeacherDashboardResponse:
        # Query student stats dynamically from database
        student_role_stmt = select(Role.id).where(
            Role.name == UserRole.STUDENT.value
        )
        student_role_id = db.scalar(student_role_stmt)

        total_students = 0
        active_students = 0

        if student_role_id:
            total_students_stmt = select(func.count(User.id)).where(
                User.role_id == student_role_id
            )
            total_students = db.scalar(total_students_stmt) or 0

            active_students_stmt = select(func.count(User.id)).where(
                User.role_id == student_role_id,
                User.is_active.is_(True),
            )
            active_students = db.scalar(active_students_stmt) or 0

        # Baseline classroom metrics fallback when DB is freshly initialized
        display_total_students = total_students if total_students > 0 else 120
        display_active_students = active_students if active_students > 0 else 87

        stats = TeacherStats(
            total_students=display_total_students,
            active_students=display_active_students,
            average_mastery=0.72,
            problems_solved=1842,
        )

        concept_performance = [
            ConceptPerformance(
                concept="Arrays",
                mastery=0.84,
                students_attempted=min(112, display_total_students),
            ),
            ConceptPerformance(
                concept="Linked Lists",
                mastery=0.71,
                students_attempted=min(104, display_total_students),
            ),
            ConceptPerformance(
                concept="Stacks & Queues",
                mastery=0.67,
                students_attempted=min(98, display_total_students),
            ),
            ConceptPerformance(
                concept="Trees",
                mastery=0.58,
                students_attempted=min(91, display_total_students),
            ),
            ConceptPerformance(
                concept="Graphs",
                mastery=0.49,
                students_attempted=min(83, display_total_students),
            ),
            ConceptPerformance(
                concept="Dynamic Programming",
                mastery=0.43,
                students_attempted=min(76, display_total_students),
            ),
        ]

        weak_concepts = [
            WeakConcept(
                concept="Dynamic Programming",
                mastery=0.43,
                affected_students=min(76, display_total_students),
            ),
            WeakConcept(
                concept="Graphs",
                mastery=0.49,
                affected_students=min(83, display_total_students),
            ),
            WeakConcept(
                concept="Trees",
                mastery=0.58,
                affected_students=min(91, display_total_students),
            ),
            WeakConcept(
                concept="Recursion",
                mastery=0.61,
                affected_students=min(68, display_total_students),
            ),
        ]

        recent_activity = [
            TeacherRecentActivity(
                student_name="Rahul Sharma",
                activity="Solved a problem",
                topic="Binary Search",
                time="5 min ago",
            ),
            TeacherRecentActivity(
                student_name="Priya Patil",
                activity="Completed a story",
                topic="Stack",
                time="18 min ago",
            ),
            TeacherRecentActivity(
                student_name="Aman Joshi",
                activity="Attempted a problem",
                topic="Graphs",
                time="32 min ago",
            ),
            TeacherRecentActivity(
                student_name="Sneha Kulkarni",
                activity="Completed a lesson",
                topic="Linked Lists",
                time="1 hour ago",
            ),
            TeacherRecentActivity(
                student_name="Arjun Deshmukh",
                activity="Won a DSA challenge",
                topic="Queues",
                time="2 hours ago",
            ),
        ]

        return TeacherDashboardResponse(
            stats=stats,
            concept_performance=concept_performance,
            weak_concepts=weak_concepts,
            recent_activity=recent_activity,
        )
