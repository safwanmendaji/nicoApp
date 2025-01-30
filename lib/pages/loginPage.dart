import 'package:flutter/material.dart';
import 'package:nicoapp/services/api_services.dart';
import 'package:nicoapp/services/notication_services.dart';
import 'package:nicoapp/url.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nicoapp/pages/dashboard.dart';
import 'package:nicoapp/pages/forgot_password.dart'; // Import your Forgot Password page
import 'dart:convert'; // For JSON encoding/decoding

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  static const int _sessionDurationDays = 15;

  final NotificationServices notificationServices = NotificationServices();

  @override
  void initState() {
    super.initState();
    _checkSession();
    notificationServices.firebaseInit();
    notificationServices.isTokenRefresh();
    notificationServices.getDeviceToken().then((value) {
      print('Device token: $value');
    });
  }

  // Check if a valid session exists
  Future<void> _checkSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    final String? sessionStartDateStr = prefs.getString('session_start_date');

    if (token != null && sessionStartDateStr != null) {
      final DateTime sessionStartDate = DateTime.parse(sessionStartDateStr);
      final DateTime now = DateTime.now();

      // Check if session is still valid (within 15 days)
      if (now.difference(sessionStartDate).inDays < _sessionDurationDays) {
        // If session is valid, navigate to Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
      } else {
        // If session expired, clear the stored session data
        await _logout();
      }
    }
  }

  // Perform login
  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Email and password are required.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.login(email, password);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Get token and userId from the response
        final String token = responseData['data']['token'] ?? '';
        final String userId = responseData['data']['userId'].toString();
        final String role = responseData['data']['Role'] ?? '';

        // Store token, userId, role, and session start date in local storage
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('userId', userId);
        await prefs.setString('role', role);
        await prefs.setString(
            'session_start_date', DateTime.now().toIso8601String());

        // Fetch device token and send it to the server using the API service
        final String? deviceToken = await notificationServices.getDeviceToken();
        if (deviceToken!.isNotEmpty) {
          await ApiService.sendTokenToServer(userId, deviceToken);
        }

        // Display success message
        final String message = responseData['message'] ?? 'Login successful';
        _showSnackBar(message);

        // Navigate to Dashboard after login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
      } else {
        final String message =
            responseData['message'] ?? 'Login failed. Please try again.';
        _showSnackBar(message);
      }
    } catch (e) {
      print('Error during login: $e');
      _showSnackBar('Something went wrong. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Logout and clear session data
  Future<void> _logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('userId');
    await prefs.remove('role');
    await prefs.remove('session_start_date');
    _showSnackBar('Session expired. Please log in again.');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor =
        Color.fromARGB(255, 106, 11, 195); // Matching the Dashboard color

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Row(
          children: [
            // Image.asset(
            //   'assets/images/logo.png', // Replace with the actual path to your logo image
            //   height: 50, // Adjust the size of the logo
            // ),
            const SizedBox(width: 50), // Space between logo and text
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Image.asset(
                'assets/images/logo.png', // Replace with the actual path to your logo image
                height: 180, // Adjust the size of the logo (smaller size)
              ),
              const SizedBox(
                  height: 20.0), // Space between logo and Welcome Back text
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Color(0xFF6200EE)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  prefixIcon: const Icon(Icons.email, color: Color(0xFF6200EE)),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: primaryColor, width: 2.0),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Color(0xFF6200EE)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF6200EE)),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: primaryColor, width: 2.0),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 30.0),

              // Login Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            primaryColor, // Use backgroundColor instead of primary
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
              const SizedBox(height: 20.0),

              // Forgot Password link
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ForgotPasswordPage()),
                  );
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
