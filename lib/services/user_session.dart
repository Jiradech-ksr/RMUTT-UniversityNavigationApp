import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static const String _keyIsGuest = 'is_guest';
  static const String _keyEmail = 'user_email';
  static const String _keyName = 'user_name';
  static const String _keyPhoto = 'user_photo';

  // --- SAVE DATA ---
  static Future<void> saveUser(
    String email,
    String name,
    String? photoUrl,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsGuest, false);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyName, name);
    if (photoUrl != null) {
      await prefs.setString(_keyPhoto, photoUrl);
    }
  }

  static Future<void> loginAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsGuest, true);
    // Clear old user data if any
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyName);
    await prefs.remove(_keyPhoto);
  }

  // --- GET DATA ---
  static Future<bool> isGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsGuest) ?? false;
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  static Future<String?> getPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhoto);
  }

  // --- LOGOUT ---
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
