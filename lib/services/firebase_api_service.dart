import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nicoapp/url.dart';

class FirebaseApiService {
  // Method to send Firebase Token to the server
  static Future<http.Response> requestTokenToSendNotification({
    required int userId,
    required String flutterToken,
    required String deviceId,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('User not authenticated');
    }

    const url = '${Url.baseUrl}notification/requesttoken?isWeb=false';
    final response = await http.put(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "userId": userId,
        "flutterFireBaseToken": flutterToken,
        "deviceId": deviceId,
      }),
    );

    return response;
  }

  // Method to send a push notification using a token
  static Future<http.Response> sendTokenNotification({
    required String title,
    required String message,
    required String token,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('auth_token');

    if (authToken == null) {
      throw Exception('User not authenticated');
    }

    const url = '${Url.baseUrl}notification/token';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $authToken",
      },
      body: jsonEncode({
        "title": title,
        "message": message,
        "token": token,
      }),
    );

    return response;
  }
}
