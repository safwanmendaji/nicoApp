import 'package:shared_preferences/shared_preferences.dart';

class FcmToken {
  static const String _fcmTokenKey = 'fcm_token';

  // Save FCM token to local storage
  static Future<void> saveFcmToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
  }

  // Retrieve FCM token from local storage
  static Future<String?> getFcmToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }

  // Clear FCM token from local storage
  static Future<void> clearFcmToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fcmTokenKey);
  }
}
