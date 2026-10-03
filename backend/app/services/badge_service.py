import logging
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.badge import Badge
from app.models.user_badge import UserBadge
from app.schemas.badge import BadgeResponse, UserBadgeResponse
from app.services.notification_service import NotificationService

logger = logging.getLogger(__name__)


SEED_BADGES = [
    {
        "code": "FIRST_LOGIN",
        "title": "Welcome to AlgoVerse",
        "description": "Logged into AlgoVerse and started your interactive CS journey",
        "icon_key": "rocket",
        "category": "SOCIAL",
        "target_role": "ALL",
    },
    {
        "code": "FIRST_ENROLLMENT",
        "title": "Enrolled in First Course",
        "description": "Enrolled in your first interactive algorithm course",
        "icon_key": "book_open",
        "category": "LEARNING",
        "target_role": "STUDENT",
    },
    {
        "code": "FIRST_VISUALIZATION",
        "title": "Watched First Algorithm",
        "description": "Explored and interacted with a step-by-step algorithm visualization",
        "icon_key": "eye",
        "category": "LEARNING",
        "target_role": "STUDENT",
    },
    {
        "code": "FIRST_PROBLEM_SOLVED",
        "title": "First AC Submission",
        "description": "Successfully solved your first coding challenge with an Accepted verdict",
        "icon_key": "check_circle",
        "category": "CODING",
        "target_role": "STUDENT",
    },
    {
        "code": "STREAK_3",
        "title": "3-Day Streak",
        "description": "Maintained an active 3-day continuous learning streak",
        "icon_key": "flame",
        "category": "STREAK",
        "target_role": "STUDENT",
    },
    {
        "code": "STREAK_7",
        "title": "7-Day Streak",
        "description": "Demonstrated master discipline with a 7-day learning streak",
        "icon_key": "trophy",
        "category": "STREAK",
        "target_role": "STUDENT",
    },
    {
        "code": "ARRAYS_MODULE_COMPLETE",
        "title": "Completed an Arrays Module",
        "description": "Conquered all interactive exercises in an Arrays module",
        "icon_key": "layers",
        "category": "LEARNING",
        "target_role": "STUDENT",
    },
    {
        "code": "ARRAYS_COURSE_COMPLETE",
        "title": "Completed Arrays Course",
        "description": "Fully conquered the Data Structures & Algorithms: Arrays course",
        "icon_key": "award",
        "category": "LEARNING",
        "target_role": "STUDENT",
    },
    {
        "code": "MULTILANG_CODER",
        "title": "Solved in 2+ Languages",
        "description": "Submitted accepted solutions in multiple programming languages",
        "icon_key": "terminal",
        "category": "CODING",
        "target_role": "STUDENT",
    },
    {
        "code": "EDUCATOR",
        "title": "Became an Educator",
        "description": "Verified as an active educator or teaching assistant on AlgoVerse",
        "icon_key": "school",
        "category": "TEACHING",
        "target_role": "ALL",
    },
    {
        "code": "MENTOR_LINKED",
        "title": "Joined a Teacher Class",
        "description": "Linked with a mentor professor via classroom joining code",
        "icon_key": "users",
        "category": "SOCIAL",
        "target_role": "STUDENT",
    },
    {
        "code": "HOMEWORK_COMPLETE",
        "title": "Completed Assigned Homework",
        "description": "Successfully submitted and finished an assigned homework lesson",
        "icon_key": "clipboard_check",
        "category": "LEARNING",
        "target_role": "STUDENT",
    },
    # Teacher-exclusive badges
    {
        "code": "FIRST_CLASS_CREATED",
        "title": "Classroom Pioneer",
        "description": "Created your verified educator classroom and student joining code",
        "icon_key": "school",
        "category": "TEACHING",
        "target_role": "TEACHER",
    },
    {
        "code": "HOMEWORK_ASSIGNED",
        "title": "Active Mentor",
        "description": "Assigned targeted homework exercises to your classroom students",
        "icon_key": "clipboard_check",
        "category": "TEACHING",
        "target_role": "TEACHER",
    },
    {
        "code": "PROBLEM_SETTER",
        "title": "Problem Setter",
        "description": "Authored your first custom algorithmic coding challenge in Educator Studio",
        "icon_key": "terminal",
        "category": "TEACHING",
        "target_role": "TEACHER",
    },
    {
        "code": "QUIZ_MASTER",
        "title": "Quiz Master",
        "description": "Created and launched an interactive live quiz in Educator Studio",
        "icon_key": "award",
        "category": "TEACHING",
        "target_role": "TEACHER",
    },
]


class BadgeService:

    @staticmethod
    def ensure_seed_badges(db: Session) -> None:
        """Idempotently seed and update achievement badges."""
        existing_badges = {b.code: b for b in db.scalars(select(Badge)).all()}
        added_or_updated = False
        for item in SEED_BADGES:
            if item["code"] not in existing_badges:
                badge = Badge(
                    code=item["code"],
                    title=item["title"],
                    description=item["description"],
                    icon_key=item["icon_key"],
                    category=item["category"],
                    target_role=item.get("target_role", "ALL"),
                )
                db.add(badge)
                added_or_updated = True
            else:
                existing = existing_badges[item["code"]]
                if existing.target_role != item.get("target_role", "ALL"):
                    existing.target_role = item.get("target_role", "ALL")
                    added_or_updated = True
        if added_or_updated:
            try:
                db.commit()
            except Exception as e:
                db.rollback()
                logger.warning(f"Error seeding badges: {e}")

    @staticmethod
    def award_badge_if_eligible(db: Session, user_id: UUID, badge_code: str) -> bool:
        """
        Awards a badge to a user if not already earned.
        Returns True if newly awarded, False otherwise.
        """
        try:
            BadgeService.ensure_seed_badges(db)
            badge = db.scalar(select(Badge).where(Badge.code == badge_code))
            if not badge:
                return False

            existing = db.scalar(
                select(UserBadge).where(
                    UserBadge.user_id == user_id,
                    UserBadge.badge_id == badge.id,
                )
            )
            if existing:
                return False

            user_badge = UserBadge(
                user_id=user_id,
                badge_id=badge.id,
            )
            db.add(user_badge)
            db.commit()
            db.refresh(user_badge)

            # Trigger notification
            try:
                NotificationService.create_notification(
                    db=db,
                    user_id=user_id,
                    title="Achievement Unlocked!",
                    message=f"You earned: {badge.title}",
                    type="BADGE",
                )
            except Exception as notif_err:
                logger.warning(f"Failed to create badge notification: {notif_err}")

            return True

        except Exception as e:
            db.rollback()
            logger.warning(f"Failed to award badge {badge_code} to user {user_id}: {e}")
            return False

    @staticmethod
    def get_all_badges(db: Session, role: str | None = None) -> list[BadgeResponse]:
        BadgeService.ensure_seed_badges(db)
        query = select(Badge)
        if role:
            role_upper = role.upper()
            query = query.where(Badge.target_role.in_([role_upper, "ALL"]))
        badges = db.scalars(query.order_by(Badge.category, Badge.title)).all()
        return [BadgeResponse.model_validate(b) for b in badges]

    @staticmethod
    def get_user_badges(db: Session, user_id: UUID, role: str | None = None) -> list[UserBadgeResponse]:
        BadgeService.ensure_seed_badges(db)
        
        # If role not explicitly provided, fetch from User
        if role is None:
            from app.models.user import User
            user = db.scalar(select(User).where(User.id == user_id))
            if user and hasattr(user, "role") and user.role:
                role = user.role.name

        query = select(Badge)
        if role:
            role_upper = role.upper()
            query = query.where(Badge.target_role.in_([role_upper, "ALL"]))
        
        badges = db.scalars(query.order_by(Badge.category, Badge.title)).all()
        user_earned = {
            ub.badge_id: ub.earned_at
            for ub in db.scalars(select(UserBadge).where(UserBadge.user_id == user_id)).all()
        }

        results = []
        for b in badges:
            is_earned = b.id in user_earned
            earned_at = user_earned.get(b.id)
            results.append(
                UserBadgeResponse(
                    id=b.id,
                    code=b.code,
                    title=b.title,
                    description=b.description,
                    icon_key=b.icon_key,
                    category=b.category,
                    target_role=b.target_role,
                    is_earned=is_earned,
                    earned_at=earned_at,
                )
            )
        return results
