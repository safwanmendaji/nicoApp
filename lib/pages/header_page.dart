import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nicoapp/pages/user_detail_page.dart';
import 'package:nicoapp/services/api_services.dart';
import 'package:nicoapp/url.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HeaderPage extends StatefulWidget implements PreferredSizeWidget {
  final String pageTitle;

  const HeaderPage({super.key, required this.pageTitle});

  @override
  _HeaderPageState createState() => _HeaderPageState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HeaderPageState extends State<HeaderPage> {
  int remindersCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // Fetch dashboard data and set reminders count
  Future<void> _fetchDashboardData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? token = prefs.getString('auth_token');

    if (userId != null && token != null) {
      try {
        final response = await fetchNotificationData(userId, token);
        setState(() {
          remindersCount = response['notificationCount'] ?? 0;
        });
      } catch (e) {
        print('Failed to load dashboard data: $e');
        setState(() {
          remindersCount = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(1, 1, 0, 0),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
      title: Text(
        widget.pageTitle,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      backgroundColor: const Color.fromRGBO(106, 11, 195, 1),
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                _showNotificationsList(context);
              },
            ),
            if (remindersCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.red,
                  child: Text(
                    remindersCount.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.person, color: Colors.white),
          onPressed: () async {
            await _navigateToUserDetails(context);
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // Fetch user details and navigate to UserDetailsPage
  Future<void> _navigateToUserDetails(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId != null) {
      int id = int.parse(userId);
      Map<String, dynamic>? userDetails = await ApiService.fetchUserById(id);

      if (userDetails != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserDetailsPage(
              name: userDetails['name'],
              email: userDetails['email'],
              mobileNo: userDetails['mobileNo'],
              designation: userDetails['designation'],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load user details')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found')),
      );
    }
  }

  // Fetch notification data
  static Future<Map<String, dynamic>> fetchNotificationData(
      String userId, String token) async {
    final response = await http.get(
      Uri.parse(
          '${Url.baseUrl}user/dashboard/notification-list?userId=$userId'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data);
      return data['data'];
    } else {
      throw Exception('Failed to load dashboard data');
    }
  }

  // Display notifications list as a bottom sheet
  void _showNotificationsList(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? token = prefs.getString('auth_token');

    if (userId != null && token != null) {
      try {
        final response = await fetchNotificationData(userId, token);
        List notifications = response['notifications'] ?? [];

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),

                  // Notifications list
                  Expanded(
                    child: ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        var notification = notifications[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.notifications_active,
                              color: Colors.deepPurple,
                            ),
                            title: Text(
                              notification['message'] ?? 'No message',
                              style: const TextStyle(fontSize: 16),
                            ),
                            subtitle: Text(
                              notification['createdAt'] ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade400,
                            ),
                            onTap: () {
                              print('Tapped on notification: $index');
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notifications: $e')),
        );
      }
    }
  }
}
