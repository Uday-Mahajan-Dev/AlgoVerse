/// Single source of truth constants for Date of Birth across client.
class DobConstants {
  static const int minAgeYears = 17;
  static const int maxAgeYears = 80;

  static DateTime safeDate(int year, int month, int day) {
    if (month == 2 && day == 29) {
      final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      if (!isLeap) return DateTime(year, 2, 28);
    }
    return DateTime(year, month, day);
  }

  /// Latest allowed birth date (today minus 17 years)
  static DateTime get maxBirthDate {
    final now = DateTime.now();
    return safeDate(now.year - minAgeYears, now.month, now.day);
  }

  /// Earliest allowed birth date (today minus 80 years)
  static DateTime get minBirthDate {
    final now = DateTime.now();
    return safeDate(now.year - maxAgeYears, now.month, now.day);
  }

  /// Initial picker date (defaults to maxBirthDate if none given)
  static DateTime initialPickerDate(DateTime? current) {
    if (current != null) {
      if (current.isBefore(minBirthDate)) return minBirthDate;
      if (current.isAfter(maxBirthDate)) return maxBirthDate;
      return current;
    }
    return maxBirthDate;
  }

  /// Accurately computes age accounting for birthdays yet to occur in the current year.
  static int? computeAge(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  /// Checks if given DOB corresponds to an age between 17 and 80 inclusive.
  static bool isWithinRange(DateTime dob) {
    final age = computeAge(dob);
    if (age == null) return false;
    return age >= minAgeYears && age <= maxAgeYears;
  }
}
