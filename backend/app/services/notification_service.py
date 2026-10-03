import uuid
from typing import Optional

from sqlalchemy import select, update, func, desc
from sqlalchemy.orm import Session

from app.models.notification import Notification


class NotificationService:
    @staticmethod
    def get_user_notifications(
        db: Session,
        user_id: uuid.UUID,
        limit: int = 50,
    ) -> tuple[list[Notification], int]:
        """Fetch user notifications ordered by created_at DESC, plus unread count."""
        stmt = (
            select(Notification)
            .where(Notification.user_id == user_id)
            .order_by(desc(Notification.created_at))
            .limit(limit)
        )
        notifications = list(db.scalars(stmt).all())

        unread_count_stmt = (
            select(func.count(Notification.id))
            .where(Notification.user_id == user_id, Notification.is_read == False)
        )
        unread_count = db.scalar(unread_count_stmt) or 0

        return notifications, unread_count

    @staticmethod
    def mark_as_read(
        db: Session,
        notification_id: uuid.UUID,
        user_id: uuid.UUID,
    ) -> Optional[Notification]:
        """Mark a single notification as read."""
        stmt = (
            select(Notification)
            .where(Notification.id == notification_id, Notification.user_id == user_id)
        )
        notification = db.scalars(stmt).first()
        if not notification:
            return None

        notification.is_read = True
        db.commit()
        db.refresh(notification)
        return notification

    @staticmethod
    def mark_all_as_read(
        db: Session,
        user_id: uuid.UUID,
    ) -> int:
        """Mark all unread notifications for a user as read."""
        stmt = (
            update(Notification)
            .where(Notification.user_id == user_id, Notification.is_read == False)
            .values(is_read=True)
        )
        result = db.execute(stmt)
        db.commit()
        return result.rowcount

    @staticmethod
    def create_notification(
        db: Session,
        user_id: uuid.UUID,
        title: str,
        message: str,
        type: str = "SYSTEM",
    ) -> Notification:
        """Create and commit a single notification."""
        notif = Notification(
            user_id=user_id,
            title=title,
            message=message,
            type=type,
            is_read=False,
        )
        db.add(notif)
        db.commit()
        db.refresh(notif)
        return notif

    @staticmethod
    def create_notifications_bulk(
        db: Session,
        user_ids: list[uuid.UUID],
        title: str,
        message: str,
        type: str = "SYSTEM",
    ) -> list[Notification]:
        """Create notifications for multiple users in bulk."""
        if not user_ids:
            return []

        notifications = [
            Notification(
                user_id=uid,
                title=title,
                message=message,
                type=type,
                is_read=False,
            )
            for uid in user_ids
        ]
        db.add_all(notifications)
        db.commit()
        return notifications
