import 'package:shared_preferences/shared_preferences.dart';

class ApiEndpoints {
  // Claves para SharedPreferences
  static const String keyApiUrl = 'custom_api_url';
  static const String keySheetId = 'custom_sheet_id';

  // URL por defecto del Web App desplegado en Apps Script
  static const String defaultApiUrl = 'https://script.google.com/macros/s/AKfycbwME8YfWEVRbynxhXcRhwUHDnJzdiuzCS7v80ZmeOWUX0Pn6MtQwJL7VL8eiUgQVfYU/exec';
  static const String defaultSheetId = '1rci21UOupu2CS7G4RQLsIpFjQexwYDGGl9cJJpBXFGw';

  static Future<String> getApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyApiUrl) ?? defaultApiUrl;
  }

  static Future<void> setApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyApiUrl, url.trim());
  }

  static Future<String> getSheetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keySheetId) ?? defaultSheetId;
  }

  static Future<void> setSheetId(String sheetId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keySheetId, sheetId.trim());
  }

  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyApiUrl);
    await prefs.remove(keySheetId);
  }
}
