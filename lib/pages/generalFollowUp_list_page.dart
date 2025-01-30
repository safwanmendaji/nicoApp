import 'package:flutter/material.dart';
import 'package:nicoapp/Model/User.dart';
import 'package:nicoapp/Model/general_followUp.dart';
import 'package:nicoapp/pages/create_general_followUp_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nicoapp/services/api_services.dart';

class GeneralFollowUpListPage extends StatefulWidget {
  const GeneralFollowUpListPage({super.key});

  @override
  _GeneralFollowUpListPageState createState() =>
      _GeneralFollowUpListPageState();
}

class _GeneralFollowUpListPageState extends State<GeneralFollowUpListPage> {
  int currentPage = 1;
  int totalPages = 1;
  bool isLoading = true;
  List followUps = [];
  String? userId;
  String? userRole; // Variable to hold user role
  String searchQuery = ''; // Variable to hold the search query

  @override
  void initState() {
    super.initState();
    loadUserId();
  }

  Future<void> loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
      userRole = prefs.getString('role'); // Fetch user role from local storage
    });
    if (userId != null) {
      await fetchFollowUps();
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

  Future<void> fetchFollowUps() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await ApiService.fetchGeneralFollowUps(
        currentPage,
        10, // Page size
        userId!,
        searchQuery,
      );

      setState(() {
        followUps = data['list'] ?? []; // Default to an empty list if null
        totalPages = data['totalPages'] ?? 1;
        isLoading = false;
      });
    } catch (error) {
      print('Error: $error');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load general follow-ups: $error')),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
      await fetchFollowUps();
    }
  }

  Future<void> loadPreviousPage() async {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
      await fetchFollowUps();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
      currentPage = 1; // Reset to first page when searching
    });
    fetchFollowUps(); // Trigger fetching with new search query
  }

  Future<void> onDelete(int followUpId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content:
              const Text('Are you sure you want to delete this follow-up?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await ApiService.deleteGeneralFollowUp(followUpId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Follow-up deleted successfully.')),
        );
        fetchFollowUps(); // Refresh the list after deletion
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete follow-up.')),
        );
      }
    }
  }

  Future<void> onEdit(int followUpId) async {
    // Find the follow-up object by its ID
    final selectedFollowUp = followUps.firstWhere(
      (followUp) => followUp['generalFollowUpId'] == followUpId,
      orElse: () => null,
    );

    if (selectedFollowUp != null) {
      // Navigate to the CreateGeneralFollowUpPage for editing
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateGeneralFollowUpPage(
            followUp: GeneralFollowUp(
              generalFollowUpId: selectedFollowUp['generalFollowUpId'],
              generalFollowUpName:
                  selectedFollowUp['generalFollowUpName'] ?? '',
              createdBy: CreatedBy(
                id: selectedFollowUp['createdBy']['id'] ?? 0,
                name: selectedFollowUp['createdBy']['name'] ?? '',
                email: selectedFollowUp['createdBy']['email'] ?? '',
                designation: selectedFollowUp['createdBy']['designation'] ?? '',
                mobileNo: selectedFollowUp['createdBy']['mobileNo'] ?? '',
              ),
              updatedBy: UpdatedBy(
                id: selectedFollowUp['updatedBy']['id'] ?? 0,
                name: selectedFollowUp['updatedBy']['name'] ?? '',
                email: selectedFollowUp['updatedBy']['email'] ?? '',
                designation: selectedFollowUp['updatedBy']['designation'] ?? '',
                mobileNo: selectedFollowUp['updatedBy']['mobileNo'] ?? '',
              ),
              followUpPerson: FollowUpPerson(
                id: selectedFollowUp['followUpPerson']['id'] ?? 0,
                name: selectedFollowUp['followUpPerson']['name'] ?? '',
                email: selectedFollowUp['followUpPerson']['email'] ?? '',
                designation:
                    selectedFollowUp['followUpPerson']['designation'] ?? '',
                mobileNo: selectedFollowUp['followUpPerson']['mobileNo'] ?? '',
              ),
              description: selectedFollowUp['description'] ?? '',
              status: selectedFollowUp['status'] ?? '',
              statusNotes: selectedFollowUp['statusNotes'] ?? '',
              dueDate: selectedFollowUp['dueDate'] ?? '',
            ),
          ),
        ),
      ).then((value) {
        // After returning from the edit page, refresh the follow-ups list
        fetchFollowUps();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Follow-up not found.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Follow Up-List',
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
                hintText: 'Search Follow-Ups...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          isLoading
              ? const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : followUps.isEmpty
                  ? const Expanded(
                      child: Center(
                        child: Text('No follow-ups found'),
                      ),
                    )
                  : Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Sr No')),
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Due Date')),
                              DataColumn(label: Text('Created At')),
                              DataColumn(label: Text('Follow-Up Person')),
                              DataColumn(
                                  label: Text('Actions')), // New Actions column
                            ],
                            rows: followUps.asMap().entries.map((entry) {
                              int index = entry.key;
                              var followUp = entry.value;
                              return DataRow(
                                cells: [
                                  // Replace generalFollowUpId with Sr No
                                  DataCell(Text((index + 1)
                                      .toString())), // Sr No starts from 1
                                  DataCell(Text(
                                      followUp['generalFollowUpName'] ??
                                          'N/A')),
                                  DataCell(Text(followUp['status'] ?? 'N/A')),
                                  DataCell(Text(followUp['dueDate'] ?? 'N/A')),
                                  DataCell(Text(followUp['createdAt'] != null
                                      ? followUp['createdAt'].split('T')[0]
                                      : 'N/A')),
                                  DataCell(Text(followUp['followUpPerson']
                                          ['name'] ??
                                      'N/A')),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () => onEdit(
                                            followUp['generalFollowUpId'],
                                          ),
                                        ),
                                        // Conditionally render the delete button
                                        if (userRole == "ADMIN")
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () => onDelete(
                                                followUp['generalFollowUpId']),
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
                  onPressed: loadPreviousPage,
                  child: const Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: loadNextPage,
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
