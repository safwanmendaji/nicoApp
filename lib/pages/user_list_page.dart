import 'package:flutter/material.dart';
import 'package:nicoapp/pages/create_user_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nicoapp/services/api_services.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  int currentPage = 1;
  int totalPages = 1;
  int totalRecords = 0;
  int pageSize = 10;
  bool isLoading = true;
  List users = [];
  String? userId;
  String searchQuery = "";
  bool isAdmin = false; // Variable to check if the user is an admin

  @override
  void initState() {
    super.initState();
    loadUserId();
  }

  Future<void> loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });

    // Fetch the role from SharedPreferences
    String? role = prefs
        .getString('role'); // Assuming 'role' is saved in SharedPreferences
    if (role != null && role == 'ADMIN') {
      setState(() {
        isAdmin = true; // Enable admin privileges if role is 'ADMIN'
      });
    }

    if (userId != null) {
      await fetchUsers();
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: User ID not found. Please log in."),
        ),
      );
    }
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data =
          await ApiService.fetchUsers(currentPage, pageSize, searchQuery);

      setState(() {
        totalRecords = data['totalRecords'];
        totalPages = (totalRecords / pageSize).ceil();
        users = data['list'] ?? []; // Assign empty list if null
        isLoading = false;
      });
    } catch (error) {
      print('Error: $error');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $error')),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
      await fetchUsers();
    }
  }

  Future<void> loadPreviousPage() async {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
      await fetchUsers();
    }
  }

  void onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
      currentPage = 1; // Reset to first page when search changes
    });
    fetchUsers();
  }

  void onEditUser(int index) {
    var user = users[index]; // Get the user object from the list
    int? userId = user['Id']; // Extract the user ID

    // Check if userId is not null before navigating
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateUserPage(userId: userId), // Pass user ID
        ),
      );
    } else {
      // Optionally, handle the case where userId is null
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found.')),
      );
    }
  }

  Future<void> onDeleteUser(int index) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this user?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      String? token =
          await _getToken(); // Get the token from shared preferences or another method

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error: Token not found. Please log in again.')),
        );
        return; // Exit the function if token is null
      }

      var user = users[index];

      if (user['Id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User ID is missing.')),
        );
        return;
      }

      try {
        String userId = user['Id'].toString();

        await ApiService.deleteUser(userId, token); // Call the delete API
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${user['name']} deleted successfully')),
        );

        await fetchUsers(); // Refresh the user list
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user: $error')),
        );
      }
    }
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(
        'auth_token'); // Assuming token is stored in SharedPreferences
  }

  void onToggleActiveStatus(int index, bool isActive) async {
    var user = users[index];

    if (user['Id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User ID is missing.')),
      );
      return;
    }

    bool previousStatus = user['status'] ?? false;

    setState(() {
      user['status'] = isActive;
    });

    try {
      await ApiService.updateUserStatus(user['Id'], isActive);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'User ${user['name']} is now ${isActive ? "active" : "inactive"}')),
      );
    } catch (error) {
      setState(() {
        user['status'] = previousStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User List',
          style: const TextStyle(
            color: Colors.white, // Title color set to white
          ),
        ),
        backgroundColor: const Color(0xFF5A3EBA), // Optional background color
        centerTitle: true, // Center the title
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    // Handle filter action
                  },
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: () {
                    // Handle sort action
                  },
                ),
              ],
            ),
          ),
          isLoading
              ? const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : users.isEmpty
                  ? const Expanded(
                      child: Center(
                        child: Text('No users found'),
                      ),
                    )
                  : Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              const DataColumn(
                                  label:
                                      Text('Sr No')), // Updated to show Sr No
                              const DataColumn(label: Text('Name')),
                              const DataColumn(label: Text('Email')),
                              const DataColumn(label: Text('Department')),
                              const DataColumn(label: Text('Phone')),
                              if (isAdmin)
                                const DataColumn(label: Text('Status')),
                              if (isAdmin)
                                const DataColumn(label: Text('Actions')),
                            ],
                            rows: users.asMap().entries.map((entry) {
                              int index = entry.key;
                              var user = entry.value;
                              return DataRow(
                                cells: [
                                  DataCell(Text((index + 1)
                                      .toString())), // Display Sr No instead of User ID
                                  DataCell(Text(user['name'] ?? 'N/A')),
                                  DataCell(Text(user['email'] ?? 'N/A')),
                                  DataCell(Text(user['department'] ?? 'N/A')),
                                  DataCell(Text(user['phone'] ?? 'N/A')),
                                  if (isAdmin)
                                    DataCell(
                                      Switch(
                                        value: user['status'] ?? false,
                                        onChanged: (value) {
                                          onToggleActiveStatus(index, value);
                                        },
                                      ),
                                    ),
                                  if (isAdmin)
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            color: Colors.blue,
                                            onPressed: () => onEditUser(index),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            color: Colors.red,
                                            onPressed: () =>
                                                onDeleteUser(index),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: loadPreviousPage,
                child: const Text('Previous'),
              ),
              Text('Page $currentPage of $totalPages'),
              ElevatedButton(
                onPressed: loadNextPage,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
