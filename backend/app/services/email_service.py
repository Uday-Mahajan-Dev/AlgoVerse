import smtplib
from email.message import EmailMessage

from app.core.config import settings


class EmailService:

    @staticmethod
    def send_email(
        recipient: str,
        subject: str,
        body: str,
    ) -> None:

        if not settings.EMAIL_HOST:
            raise RuntimeError(
                "Email service is not configured."
            )

        message = EmailMessage()

        message["From"] = (
            f"{settings.EMAIL_FROM_NAME} "
            f"<{settings.EMAIL_FROM}>"
        )

        message["To"] = recipient
        message["Subject"] = subject

        message.set_content(body)

        with smtplib.SMTP(
            settings.EMAIL_HOST,
            settings.EMAIL_PORT,
            timeout=30,
        ) as server:

            if settings.EMAIL_USE_TLS:
                server.starttls()

            if (
                settings.EMAIL_USERNAME
                and settings.EMAIL_PASSWORD
            ):
                server.login(
                    settings.EMAIL_USERNAME,
                    settings.EMAIL_PASSWORD,
                )

            server.send_message(message)

    @staticmethod
    def send_email_otp(
        recipient: str,
        otp: str,
    ) -> None:

        subject = "Verify your AlgoVerse email"

        body = f"""Hello,

Your AlgoVerse email verification code is:

{otp}

This code expires in {settings.EMAIL_OTP_EXPIRE_MINUTES} minutes.

If you did not request this code, you can safely ignore this email.

Regards,
AlgoVerse Team
"""

        EmailService.send_email(
            recipient=recipient,
            subject=subject,
            body=body,
        )