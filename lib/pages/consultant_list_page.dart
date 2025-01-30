import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nicoapp/services/api_services.dart';
import 'package:nicoapp/pages/navbar.dart';
import 'create_consultant_page.dart'; // Import the CreateConsultantPage

class ConsultantListPage extends StatefulWidget {
  const ConsultantListPage({super.key});

  @override
  _ConsultantListPageState createState() => _ConsultantListPageState();
}

class _ConsultantListPageState extends State<ConsultantListPage> {
  int currentPage = 1;
  int totalPages = 1;
  int totalRecords = 0;
  int pageSize = 10;
  bool isLoading = true;
  List consultants = [];
  String? userId;
  String? userRole;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    loadUserIdAndRole();
  }

  // Load both userId and userRole from SharedPreferences
  Future<void> loadUserIdAndRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
      userRole = prefs.getString('role'); // Fetch the user's role
    });
    if (userId != null) {
      await fetchConsultants();
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

  Future<void> fetchConsultants() async {
    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      // Call API to get the consultants list
      final data = await ApiService.fetchConsultants(
        currentPage,
        pageSize,
        searchQuery,
      );

      setState(() {
        totalRecords = data['totalRecords'];
        totalPages = (totalRecords / pageSize).ceil(); // Calculate total pages
        consultants = data['Consultants'] ?? []; // Assign an empty list if null
        isLoading = false;
      });
    } catch (error) {
      print('Error: $error');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load consultants: $error')),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
      await fetchConsultants();
    }
  }

  Future<void> loadPreviousPage() async {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
      await fetchConsultants();
    }
  }

  void onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
      currentPage = 1; // Reset to first page when search changes
    });
    fetchConsultants();
  }

  void onEditConsultant(int index) {
    final consultant = consultants[index];
    // Navigate to CreateConsultantPage with the consultant data for editing
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateConsultantPage(consultant: consultant),
      ),
    );
  }

  void onDeleteConsultant(int index) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content:
              const Text('Are you sure you want to delete this consultant?'),
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
      final consultantId = consultants[index]['consultantId'];

      // Call the delete API
      bool deletionSuccess = await ApiService.deleteConsultant(consultantId);

      if (deletionSuccess) {
        setState(() {
          consultants.removeAt(index); // Remove from local list
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultant deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete consultant')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Consultant List',
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
                      hintText: 'Search consultants...',
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
              : consultants.isEmpty
                  ? const Expanded(
                      child: Center(
                        child: Text('No consultants found'),
                      ),
                    )
                  : Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              const DataColumn(label: Text('SR No.')),
                              const DataColumn(label: Text('Company Name')),
                              const DataColumn(
                                  label: Text('Contact Person Name')),
                              const DataColumn(label: Text('Mobile')),
                              // Only show the actions column if userRole == ADMIN
                              if (userRole == 'ADMIN')
                                const DataColumn(label: Text('Actions')),
                            ],
                            rows: consultants.asMap().entries.map((entry) {
                              int index = entry.key;
                              var consultant = entry.value;
                              return DataRow(
                                cells: [
                                  DataCell(Text(
                                      (index + 1 + (currentPage - 1) * pageSize)
                                          .toString())), // Serial number
                                  DataCell(Text(
                                      consultant['consultantName'] ?? 'N/A')),
                                  DataCell(Text(
                                      consultant['contactPerson'] ?? 'N/A')),
                                  DataCell(Text(
                                      consultant['contactNumber'] ?? 'N/A')),
                                  if (userRole == 'ADMIN')
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            color: Colors.blue,
                                            onPressed: () =>
                                                onEditConsultant(index),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            color: Colors.red,
                                            onPressed: () =>
                                                onDeleteConsultant(index),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: currentPage > 1 ? loadPreviousPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A3EBA),
                  ),
                  child: const Text('Previous'),
                ),
                Text('Page $currentPage of $totalPages'),
                ElevatedButton(
                  onPressed: currentPage < totalPages ? loadNextPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A3EBA),
                  ),
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
}
