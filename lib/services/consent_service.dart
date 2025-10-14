import 'package:shared_preferences/shared_preferences.dart';

/// Handles storage and retrieval of safety disclaimer consent.
class ConsentService {
  static const int disclaimerVersion = 1;
  static const String _versionKey = 'disclaimerAcceptedVersion';
  static const String _timestampKey = 'disclaimerAcceptedAt';
  static const String _legacyBoolKey = 'disclaimerAccepted';

  const ConsentService();

  /// Returns true when the stored consent matches the current disclaimer version.
  Future<bool> hasAcceptedLatestDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getInt(_versionKey);

    // A legacy boolean indicates an older disclaimer that requires re-acknowledgement.
    if (version == disclaimerVersion) {
      return true;
    }

    return false;
  }

  /// Persists the latest disclaimer consent along with a timestamp.
  Future<void> recordDisclaimerAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_versionKey, disclaimerVersion);
    await prefs.setString(_timestampKey, DateTime.now().toIso8601String());
    await prefs.remove(_legacyBoolKey);
  }

  /// Clears stored consent, forcing the onboarding flow to show the disclaimer again.
  Future<void> clearDisclaimerAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_versionKey);
    await prefs.remove(_timestampKey);
    await prefs.setBool(_legacyBoolKey, false);
  }
}
