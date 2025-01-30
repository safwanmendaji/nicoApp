import 'package:flutter/material.dart';
import 'package:nicoapp/services/api_services.dart';
import 'package:nicoapp/pages/navbar.dart';
import 'package:nicoapp/pages/create_role_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleListPage extends StatefulWidget {
  const RoleListPage({super.key});

  @override
  _RoleListPageState createState() => _RoleListPageState();
}

class _RoleListPageState extends State<RoleListPage> {
  int currentPage = 1;
  int totalPages = 1;
  int totalRecords = 0;
  int pageSize = 10;
  bool isLoading = true;
  List roles = [];
  String searchQuery = "";
  String? userRole;

  @override
  void initState() {
    super.initState();
    fetchUserRoleAndRoles(); // Fetch user role and roles on page load
  }

  Future<void> fetchUserRoleAndRoles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('role');
    });
    await fetchRoles();
  }

  Future<void> fetchRoles() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await ApiService.fetchRoles(
        page: currentPage,
        size: pageSize,
        searchQuery: searchQuery.isEmpty ? null : searchQuery,
      );

      setState(() {
        roles = data['roles'] ?? [];
        totalRecords = data['totalItems'];
        totalPages = data['totalPages'];
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load roles: $error')),
      );
    }
  }

  void onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
      currentPage = 1;
    });
    fetchRoles();
  }

  // Edit action handler - Redirect to CreateRolePage for update
  void onEditRole(int index) {
    final roleId = roles[index]['Id']; // Get roleId from the selected role
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateRolePage(
          roleId: roleId,
        ), // Pass roleId for update
      ),
    );
  }

  Future<void> onDeleteRole(int index) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this role?'),
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
      int roleId = roles[index]['Id'];
      bool success = await ApiService.deleteRole(roleId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role deleted successfully.')),
        );
        await fetchRoles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete role.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Role List',
          style: const TextStyle(
            color: Colors.white, // Title color set to white
          ),
        ),
        backgroundColor: const Color(0xFF5A3EBA),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search roles...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          isLoading
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              : roles.isEmpty
                  ? const Expanded(child: Center(child: Text('No roles found')))
                  : Expanded(
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('Sr No')),
                          DataColumn(label: Text('Name')),
                          if (userRole == 'ADMIN')
                            DataColumn(label: Text('Actions')),
                        ],
                        rows: List<DataRow>.generate(roles.length, (index) {
                          final role = roles[index];
                          final serialNumber =
                              (currentPage - 1) * pageSize + index + 1;
                          return DataRow(cells: [
                            DataCell(Text(serialNumber.toString())),
                            DataCell(Text(role['name'] ?? 'N/A')),
                            if (userRole == 'ADMIN')
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    color: Colors.blue,
                                    onPressed: () => onEditRole(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () => onDeleteRole(index),
                                  ),
                                ],
                              )),
                          ]);
                        }),
                      ),
                    ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: currentPage > 1 ? loadPreviousPage : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A3EBA)),
                  child: const Text('Previous'),
                ),
                Text('Page $currentPage of $totalPages'),
                ElevatedButton(
                  onPressed: currentPage < totalPages ? loadNextPage : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A3EBA)),
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
      // bottomNavigationBar: const NavBar(),
    );
  }

  Future<void> loadNextPage() async {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
      await fetchRoles();
    }
  }

  Future<void> loadPreviousPage() async {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
      await fetchRoles();
    }
  }
}
