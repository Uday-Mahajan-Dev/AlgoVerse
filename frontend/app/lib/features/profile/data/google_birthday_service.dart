import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/dob_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

class GoogleBirthdayService {
  static const String birthdayScope =
      'https://www.googleapis.com/auth/user.birthday.read';
  static const String declinedPrefKey = 'google_birthday_sync_declined';

  /// Fire-and-forget birthday sync after successful Google sign-in.
  /// Runs with a short timeout (8s) and fails silently.
  static void syncBirthdayAfterLogin({
    required Map<String, dynamic> userData,
  }) {
    final existingDob = userData['date_of_birth']?.toString();
    if (existingDob != null && existingDob.trim().isNotEmpty) {
      return;
    }

    // Run asynchronously without awaiting so login is never blocked or delayed
    Future<void>.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final declined = prefs.getBool(declinedPrefKey) ?? false;
        if (declined) {
          debugPrint('[GoogleBirthday] Birthday sync previously declined by user.');
          return;
        }

        await fetchAndSaveGoogleBirthday(promptUserIfNeeded: false);
      } catch (e) {
        debugPrint('[GoogleBirthday] Background sync skipped/failed: $e');
      }
    });
  }

  /// Explicitly import from Google (e.g. from Profile page button).
  /// Returns a user-friendly message or null on success.
  static Future<String?> importBirthdayExplicitly() async {
    try {
      return await fetchAndSaveGoogleBirthday(promptUserIfNeeded: true);
    } catch (e) {
      debugPrint('[GoogleBirthday] Explicit import failed: $e');
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Core logic to authorize the scope, query People API, validate range, and PATCH /users/me.
  static Future<String?> fetchAndSaveGoogleBirthday({
    required bool promptUserIfNeeded,
  }) async {
    final googleSignIn = GoogleSignIn.instance;

    // Request authorization scope using google_sign_in v7 authorizationClient
    String? accessToken;

    try {
      final authClient = googleSignIn.authorizationClient;
      if (promptUserIfNeeded) {
        final authResponse = await authClient
            .authorizeScopes([birthdayScope])
            .timeout(const Duration(seconds: 8));
        accessToken = authResponse.accessToken;
      } else {
        final silentAuth = await authClient
            .authorizationForScopes([birthdayScope])
            .timeout(const Duration(seconds: 8));
        if (silentAuth != null) {
          accessToken = silentAuth.accessToken;
        } else {
          final authResponse = await authClient
              .authorizeScopes([birthdayScope])
              .timeout(const Duration(seconds: 8));
          accessToken = authResponse.accessToken;
        }
      }
    } catch (e) {
      debugPrint('[GoogleBirthday] authorizationClient error: $e');
    }

    if (accessToken == null || accessToken.isEmpty) {
      if (!promptUserIfNeeded) {
        // Record declined to avoid nagging on every login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(declinedPrefKey, true);
      }
      return promptUserIfNeeded
          ? 'Could not authorize birthday access. Permission was denied or unavailable.'
          : null;
    }

    // Call Google People API
    final url = Uri.parse(
      'https://people.googleapis.com/v1/people/me?personFields=birthdays',
    );
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      debugPrint(
        '[GoogleBirthday] People API returned HTTP ${response.statusCode}: ${response.body}',
      );
      if (promptUserIfNeeded) {
        throw Exception(
          'Could not retrieve birthday from Google profile (HTTP ${response.statusCode}).',
        );
      }
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final birthdays = data['birthdays'] as List<dynamic>?;
    if (birthdays == null || birthdays.isEmpty) {
      if (promptUserIfNeeded) {
        throw Exception('No birthday is configured on your Google Account.');
      }
      return null;
    }

    // Search for a birthday entry with full year, month, and day
    DateTime? resolvedDob;
    for (final b in birthdays) {
      final dateObj = b['date'] as Map<String, dynamic>?;
      if (dateObj != null) {
        final y = dateObj['year'] as int?;
        final m = dateObj['month'] as int?;
        final d = dateObj['day'] as int?;
        if (y != null && m != null && d != null) {
          resolvedDob = DobConstants.safeDate(y, m, d);
          break;
        }
      }
    }

    if (resolvedDob == null) {
      if (promptUserIfNeeded) {
        throw Exception('Your Google Account birthday is missing the birth year.');
      }
      return null;
    }

    // Validate against A3 range [17, 80]
    if (!DobConstants.isWithinRange(resolvedDob)) {
      if (promptUserIfNeeded) {
        throw Exception(
          'Your Google Account birth date ($resolvedDob) is outside the allowed range of 17 to 80 years old.',
        );
      }
      return null;
    }

    // Format YYYY-MM-DD
    final yStr = resolvedDob.year.toString().padLeft(4, '0');
    final mStr = resolvedDob.month.toString().padLeft(2, '0');
    final dStr = resolvedDob.day.toString().padLeft(2, '0');
    final dobFormatted = '$yStr-$mStr-$dStr';

    // PATCH /users/me with dob_source = GOOGLE
    final jwt = await TokenStorage.getAccessToken();
    if (jwt != null && jwt.isNotEmpty) {
      await ApiClient.updateProfile(
        accessToken: jwt,
        dateOfBirth: dobFormatted,
        dobSource: 'GOOGLE',
      );
      debugPrint('[GoogleBirthday] Successfully imported Google DOB: $dobFormatted');
      return null; // success
    }

    return null;
  }
}
