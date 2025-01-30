import 'package:flutter/material.dart';

class UserDetailsPage extends StatelessWidget {
  final String name;
  final String email;
  final String mobileNo;
  final String designation;

  // Constructor to receive user details
  const UserDetailsPage({
    Key? key,
    required this.name,
    required this.email,
    required this.mobileNo,
    required this.designation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Information',
          style: TextStyle(color: Colors.white), // Title color set to white
        ),
        backgroundColor: const Color.fromRGBO(106, 11, 195, 1), // Stylish color
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade700,
              Colors.deepPurple.shade300,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title

            const SizedBox(height: 16),
            // Card for User Details
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserInfoRow(Icons.person, 'Name', name),
                    const Divider(),
                    _buildUserInfoRow(Icons.email, 'Email', email),
                    const Divider(),
                    _buildUserInfoRow(Icons.phone, 'Mobile No', mobileNo),
                    const Divider(),
                    _buildUserInfoRow(Icons.work, 'Designation', designation),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to create a row with an icon and text
  Widget _buildUserInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
