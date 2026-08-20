from pydantic import BaseModel


class TeacherDashboardStatsSchema(BaseModel):
    total_students: int
    active_students: int
    average_mastery: float
    problems_solved: int


class ConceptPerformanceSchema(BaseModel):
    concept: str
    mastery: float
    students_attempted: int


class WeakConceptSchema(BaseModel):
    concept: str
    mastery: float
    affected_students: int


class RecentActivitySchema(BaseModel):
    student_name: str
    activity: str
    topic: str
    time: str


class TeacherDashboardResponseSchema(BaseModel):
    stats: TeacherDashboardStatsSchema
    concept_performance: list[ConceptPerformanceSchema] = []
    weak_concepts: list[WeakConceptSchema] = []
    recent_activity: list[RecentActivitySchema] = []
