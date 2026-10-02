import unittest
from uuid import uuid4
from datetime import date
from sqlalchemy import select

from app.db.session import SessionLocal
from app.models.role import Role
from app.models.user import User
from app.models.user_badge import UserBadge
from app.schemas.user import UserUpdate
from app.services.badge_service import BadgeService


class TestProfileAndBadges(unittest.TestCase):
    def setUp(self):
        self.db = SessionLocal()

    def tearDown(self):
        self.db.close()

    def test_badges_catalog_and_awards(self):
        # 1. Ensure seed badges are populated
        BadgeService.ensure_seed_badges(self.db)
        badges = BadgeService.get_all_badges(self.db)
        self.assertGreaterEqual(len(badges), 12)

        # 2. Create test user
        student_role = self.db.scalar(select(Role).where(Role.name == "STUDENT"))
        if not student_role:
            self.skipTest("Student role not found")

        unique_suffix = uuid4().hex[:6]
        test_user = User(
            username=f"testbadge_{unique_suffix}",
            email=f"testbadge_{unique_suffix}@example.com",
            hashed_password="hashed_pwd",
            first_name="Badge",
            last_name="Tester",
            role_id=student_role.id,
        )
        self.db.add(test_user)
        self.db.commit()
        self.db.refresh(test_user)

        try:
            # 3. Test award badge
            awarded = BadgeService.award_badge_if_eligible(self.db, test_user.id, "FIRST_LOGIN")
            self.assertTrue(awarded)

            # Awarding same badge again should return False (already earned)
            awarded_again = BadgeService.award_badge_if_eligible(self.db, test_user.id, "FIRST_LOGIN")
            self.assertFalse(awarded_again)

            # 4. Fetch user badges
            user_badges = BadgeService.get_user_badges(self.db, test_user.id)
            self.assertGreaterEqual(len(user_badges), 12)
            earned_count = sum(1 for b in user_badges if b.is_earned)
            self.assertEqual(earned_count, 1)

            first_login_badge = next((b for b in user_badges if b.code == "FIRST_LOGIN"), None)
            self.assertIsNotNone(first_login_badge)
            self.assertTrue(first_login_badge.is_earned)
            self.assertIsNotNone(first_login_badge.earned_at)

        finally:
            self.db.query(UserBadge).filter(UserBadge.user_id == test_user.id).delete(synchronize_session=False)
            self.db.delete(test_user)
            self.db.commit()


if __name__ == "__main__":
    unittest.main()
