from datetime import date

MIN_AGE_YEARS = 17
MAX_AGE_YEARS = 80


def calculate_age(dob: date, on_date: date | None = None) -> int:
    """Accurately calculates age given a date of birth and reference date."""
    if on_date is None:
        on_date = date.today()
    return on_date.year - dob.year - (
        (on_date.month, on_date.day) < (dob.month, dob.day)
    )


def validate_dob_range(dob: date, on_date: date | None = None) -> None:
    """Raises ValueError if date of birth is outside [MIN_AGE_YEARS, MAX_AGE_YEARS]."""
    if on_date is None:
        on_date = date.today()
    age = calculate_age(dob, on_date)
    if age < MIN_AGE_YEARS or age > MAX_AGE_YEARS:
        raise ValueError(
            f"Date of birth must correspond to an age between {MIN_AGE_YEARS} and {MAX_AGE_YEARS} years old."
        )
