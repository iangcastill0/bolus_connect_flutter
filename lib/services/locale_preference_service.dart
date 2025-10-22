import 'package:shared_preferences/shared_preferences.dart';

/// Service to persist user's language and region preferences.
/// Stores preferences in SharedPreferences for later retrieval.
class LocalePreferenceService {
  const LocalePreferenceService();

  static const String _keyLanguage = 'user_language';
  static const String _keyRegion = 'user_region';
  static const String _keyLocaleSetupCompleted = 'locale_setup_completed';

  // Default values
  static const String _defaultLanguage = 'en';
  static const String _defaultRegion = 'us';

  /// Gets the user's selected language code (e.g., 'en', 'es', 'fr')
  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? _defaultLanguage;
  }

  /// Sets the user's selected language code
  Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, languageCode);
  }

  /// Gets the user's selected region code (e.g., 'us', 'uk', 'eu')
  Future<String> getRegion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRegion) ?? _defaultRegion;
  }

  /// Sets the user's selected region code
  Future<void> setRegion(String regionCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRegion, regionCode);
  }

  /// Checks if the user has completed the locale setup screen
  Future<bool> hasCompletedSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLocaleSetupCompleted) ?? false;
  }

  /// Marks the locale setup as completed
  Future<void> markSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLocaleSetupCompleted, true);
  }

  /// Gets the glucose unit based on the selected region
  /// Returns 'mg/dL' for US and Mexico, 'mmol/L' for others
  Future<String> getGlucoseUnit() async {
    final region = await getRegion();
    // Regions that use mg/dL: US, Mexico
    final mgdlRegions = ['us', 'mx'];
    return mgdlRegions.contains(region) ? 'mg/dL' : 'mmol/L';
  }

  /// Clears all locale preferences (useful for testing or reset)
  Future<void> clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLanguage);
    await prefs.remove(_keyRegion);
    await prefs.remove(_keyLocaleSetupCompleted);
  }
}
