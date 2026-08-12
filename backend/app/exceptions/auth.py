from fastapi import HTTPException, status


class InvalidCredentialsException(HTTPException):

    def __init__(self):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
        )


class EmailAlreadyExistsException(HTTPException):

    def __init__(self):
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already exists.",
        )


class UsernameAlreadyExistsException(HTTPException):

    def __init__(self):
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            detail="Username already exists.",
        )


class DefaultRoleNotFoundException(HTTPException):

    def __init__(self):
        super().__init__(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Default role not found.",
        )