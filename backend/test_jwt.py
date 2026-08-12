from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
)

access = create_access_token("123456")

refresh = create_refresh_token("123456")

print("ACCESS")
print(access)

print()

print("REFRESH")
print(refresh)

print()

print("DECODED ACCESS")
print(decode_token(access))

print()

print("DECODED REFRESH")
print(decode_token(refresh))