from uuid import UUID
from pydantic import BaseModel


# ============================================================
# STUDENT DASHBOARD SCHEMAS
# ============================================================

class StudentUserSummary(BaseModel):
    id: UUID
    username: str
    first_name: str
    last_name: str
    email: str
    avatar_url: str | None = None


class StudentLevelXp(BaseModel):
    current_level: int
    current_xp: int
    next_level_xp: int
    xp_to_next_level: int
    progress: float


class StudentContinueLearning(BaseModel):
    category: str
    topic: str
    progress: float
    progress_text: str


class StudentDailyMission(BaseModel):
    number: str
    title: str
    progress_text: str
    progress: float
    reward: str
    icon: str


class StudentPerformanceStats(BaseModel):
    day_streak: int
    total_xp: int


class StudentNextAchievement(BaseModel):
    title: str
    description: str
    current_count: int
    target_count: int
    progress: float
    progress_text: str
    remaining_text: str


class StudentWeeklyChallenge(BaseModel):
    title: str
    description: str
    current_count: int
    target_count: int
    reward: str
    progress: float
    progress_text: str


class StudentRecentActivity(BaseModel):
    title: str
    xp: str
    icon: str


class StudentDashboardResponse(BaseModel):
    user: StudentUserSummary
    level_xp: StudentLevelXp
    continue_learning: StudentContinueLearning
    daily_missions: list[StudentDailyMission]
    performance: StudentPerformanceStats
    next_achievement: StudentNextAchievement
    weekly_challenge: StudentWeeklyChallenge
    recent_activities: list[StudentRecentActivity]


# ============================================================
# TEACHER DASHBOARD SCHEMAS
# ============================================================

class TeacherStats(BaseModel):
    total_students: int
    active_students: int
    average_mastery: float
    problems_solved: int


class ConceptPerformance(BaseModel):
    concept: str
    mastery: float
    students_attempted: int


class WeakConcept(BaseModel):
    concept: str
    mastery: float
    affected_students: int


class TeacherRecentActivity(BaseModel):
    student_name: str
    activity: str
    topic: str
    time: str


class TeacherDashboardResponse(BaseModel):
    stats: TeacherStats
    concept_performance: list[ConceptPerformance]
    weak_concepts: list[WeakConcept]
    recent_activity: list[TeacherRecentActivity]
