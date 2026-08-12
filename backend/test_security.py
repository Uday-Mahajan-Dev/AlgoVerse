from app.core.security import (
    get_password_hash,
    verify_password,
)

password = "AlgoVerse123!"

hashed = get_password_hash(password)

print(hashed)

print(verify_password(password, hashed))

print(verify_password("wrongpassword", hashed))