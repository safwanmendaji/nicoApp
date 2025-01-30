import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nicoapp/pages/loginPage.dart';
import 'package:nicoapp/url.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OtpPage extends StatelessWidget {
  const OtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController otpController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter OTP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter the OTP sent to your email:',
              style: TextStyle(
                fontSize: 18,
                color: Color.fromARGB(255, 106, 11, 195), // Custom color
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'OTP',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final String otp = otpController.text.trim();
                if (otp.isNotEmpty) {
                  // Get email from shared preferences
                  String? email = await _getEmailFromLocalStorage();

                  if (email != null) {
                    final response = await otpValidate(email, otp);

                    if (response.statusCode == 200) {
                      // If the OTP is valid, navigate to NewPassword page
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NewPasswordPage(),
                        ),
                      );
                    } else {
                      // Handle error
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid OTP. Please try again.'),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No email found.')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter the OTP.')),
                  );
                }
              },
              child: const Text('Verify OTP'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<String?> _getEmailFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(
        'email'); // Assuming you stored the email with the key 'email'
  }

  static Future<http.Response> otpValidate(String email, String otp) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${Url.baseUrl}user/otpvalidate'),
      headers: headers,
      body: jsonEncode({
        'email': email,
        'otp': otp,
      }),
    );
    return response;
  }

  static Future<Map<String, String>> _getHeaders() async {
    // Implement your logic to get headers with auth_token
    return {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer your_token_here', // Example header if required
    };
  }
}

// Define your NewPasswordPage class here
class NewPasswordPage extends StatefulWidget {
  const NewPasswordPage({super.key});

  @override
  _NewPasswordPageState createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  String? _email;

  @override
  void initState() {
    super.initState();
    _getEmailFromLocalStorage();
  }

  Future<void> _getEmailFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _email = prefs.getString(
          'email'); // Assuming you stored the email with the key 'email'
    });
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new password.')),
      );
      return;
    }

    final String newPassword = _newPasswordController.text.trim();
    if (_email != null) {
      final response = await _sendNewPasswordApi(_email!, newPassword);

      if (response.statusCode == 200) {
        // Handle successful password update
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully.')),
        );

        // Redirect to LoginPage after successful update
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) =>
                  const LoginPage()), // Ensure you have a LoginPage
          (Route<dynamic> route) => false, // Remove all previous routes
        );
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to update password. Please try again.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email found.')),
      );
    }
  }

  Future<http.Response> _sendNewPasswordApi(
      String email, String newPassword) async {
    final headers = await _getHeaders(); // Get headers if needed
    final response = await http.post(
      Uri.parse(
          '${Url.baseUrl}user/updatePasswordAfterOtpValidation'), // Replace with your actual API endpoint
      headers: headers,
      body: jsonEncode({
        'email': email,
        'password': newPassword,
      }),
    );
    return response;
  }

  static Future<Map<String, String>> _getHeaders() async {
    // Implement your logic to get headers with auth_token
    return {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer your_token_here', // Example header if required
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set New Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter your new password:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'New Password',
              ),
              obscureText: true, // To hide the password input
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updatePassword,
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}
