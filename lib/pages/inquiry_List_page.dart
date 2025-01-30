import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nicoapp/pages/Inquiry_details.dart';
import 'package:nicoapp/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nicoapp/pages/create_inquiry_page.dart';

class InquiryListPage extends StatefulWidget {
  @override
  _InquiryListPageState createState() => _InquiryListPageState();
  final String inquiryStatus; // Add inquiryStatus parameter

  const InquiryListPage({Key? key, required this.inquiryStatus})
      : super(key: key);
}

class _InquiryListPageState extends State<InquiryListPage> {
  int currentPage = 1;
  int totalPages = 1;
  int totalRecords = 0;
  int pageSize = 10;
  bool isLoading = true;
  List inquiries = [];
  String? userId;
  String searchQuery = "";
  String inquiryStatus = '';
  List<dynamic> followUpUsers = []; // List of follow-up users
  List<dynamic> filteredFollowUpUsers = []; // Filtered list for search
  String? userRole; // Add a variable to store user role

  @override
  void initState() {
    super.initState();
    loadUserId();
    _fetchFollowUpUsers(); // Fetch follow-up users when initializing
    inquiryStatus =
        widget.inquiryStatus; // Initialize inquiryStatus from widget
  }

  Future<void> _fetchFollowUpUsers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data =
          await ApiService.fetchUsers(1, 20, searchQuery); // Example API call
      setState(() {
        followUpUsers = data['list'];
        filteredFollowUpUsers = followUpUsers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load follow-up users: $e')),
      );
    }
  }

  Future<void> loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
      userRole = prefs.getString('role'); // Fetch the user role
    });
    if (userId != null) {
      await fetchInquiries();
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

  Future<void> fetchInquiries() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await ApiService.fetchInquiries(
        currentPage,
        pageSize,
        searchQuery,
        widget.inquiryStatus, // Pass the inquiry status from the widget
      );

      setState(() {
        totalRecords = data['totalRecords'];
        totalPages = (totalRecords / pageSize).ceil();
        inquiries = data['inquiryList'];
        isLoading = false;
      });
    } catch (error) {
      print('Error: $error');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load inquiries: $error')),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
      await fetchInquiries();
    }
  }

  Future<void> loadPreviousPage() async {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
      await fetchInquiries();
    }
  }

  void onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
      currentPage = 1;
    });
    fetchInquiries();
  }

  void onEditInquiry(int index) {
    final inquiry = inquiries[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateInquiryPage(
          inquiryData: inquiry,
        ),
      ),
    );
  }

  void onDeleteInquiry(int index) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this inquiry?'),
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
      int inquiryId = inquiries[index]['inquiryId'];

      bool success = await ApiService.deleteInquiry(inquiryId);

      if (success) {
        setState(() {
          inquiries.removeAt(index);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inquiry deleted successfully.')),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete inquiry.')),
        );
      }
    }
  }

  Future<void> showQuotationDialog({
    required int inquiryId,
    required String dialogTitle,
    required String buttonText,
    required Function(int, int, String) onSubmit,
    required bool
        isQuotationGiven, // Pass whether the quotation is given or not
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUserIdString = prefs.getString('userId');
    int? userId =
        storedUserIdString != null ? int.parse(storedUserIdString) : null;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found. Please log in.')),
      );
      return;
    }

    // Fetch the inquiry details by ID
    final inquiryData = await ApiService.fetchInquiryById(inquiryId);
    if (inquiryData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load inquiry details.')),
      );
      return;
    }

    // Extract existing follow-up user and description from the inquiry data
    int? selectedFollowUpUserId = inquiryData['followUpUser']['id'];
    String? selectedFollowUpUserName = inquiryData['followUpUser']['name'];
    String description = inquiryData['description'] ?? '';

    TextEditingController _followUpUserSearchController =
        TextEditingController(text: selectedFollowUpUserName);

    // Create a local filtered list of follow-up users for search functionality
    List<dynamic> localFilteredFollowUpUsers = List.from(followUpUsers);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text(
                    dialogTitle,
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Follow-Up User Search Field
                        TextFormField(
                          controller: _followUpUserSearchController,
                          decoration: InputDecoration(
                            hintText: 'Search Follow-Up User',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            suffixIcon: const Icon(Icons.search,
                                color: Colors.blueAccent),
                          ),
                          onChanged: (String query) {
                            setState(() {
                              localFilteredFollowUpUsers = followUpUsers
                                  .where((user) => user['name']
                                      .toLowerCase()
                                      .contains(query.toLowerCase()))
                                  .toList();
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        if (localFilteredFollowUpUsers.isNotEmpty)
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Scrollbar(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: localFilteredFollowUpUsers.length,
                                itemBuilder: (context, index) {
                                  final user =
                                      localFilteredFollowUpUsers[index];
                                  return ListTile(
                                    title: Text(user['name'] ?? 'N/A'),
                                    onTap: () {
                                      setState(() {
                                        selectedFollowUpUserId = user[
                                            'Id']; // Update the selected user ID
                                        _followUpUserSearchController.text = user[
                                            'name']; // Update the text controller
                                        print(
                                            "Selected Follow-Up User ID: $selectedFollowUpUserId"); // Debugging
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Description Field
                        TextFormField(
                          initialValue: description,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              description = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.red)),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (selectedFollowUpUserId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Please select a Follow-Up User.')),
                          );
                          return;
                        }
                        if (description.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Description cannot be empty.')),
                          );
                          return;
                        }

                        onSubmit(
                            inquiryId, selectedFollowUpUserId!, description);
                        Navigator.of(context)
                            .pop(); // Close the dialog after successful submission
                      },
                      child: Text(
                        buttonText,
                        style: TextStyle(color: Colors.blueAccent),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void markQuotationDoneDialog(int inquiryId) {
    showQuotationDialog(
      inquiryId: inquiryId,
      dialogTitle: 'Mark Quotation as Done',
      buttonText: 'Mark as Done',
      onSubmit: markQuotationAsDone,
      isQuotationGiven: true, // For marking as done, pass true
    );
  }

  void reassignQuotationDialog(int inquiryId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUserIdString = prefs.getString('userId');
    int? userId =
        storedUserIdString != null ? int.parse(storedUserIdString) : null;

    showQuotationDialog(
      inquiryId: inquiryId,
      dialogTitle: 'Reassign Quotation',
      buttonText: 'Reassign',
      onSubmit: (int inquiryId, int followUpUser, String description) {
        if (userId != null) {
          reassignQuotation(
              inquiryId, followUpUser, description, userId); // Pass userId
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User ID not found.')),
          );
        }
      },
      isQuotationGiven: false, // Pass false for reassigning
    );
  }

  Future<void> markQuotationAsDone(
      int inquiryId, int followUpUser, String description) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUserIdString = prefs.getString('userId');
    int? userId =
        storedUserIdString != null ? int.parse(storedUserIdString) : null;

    if (userId != null) {
      final response = await ApiService.markQuotationAsDone(
        followUpUser: followUpUser.toString(),
        userId: userId.toString(),
        description: description,
        inquiryId: inquiryId,
        isQuotationGiven: true, // Ensure you're passing a valid bool
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation marked as done')),
        );
        fetchInquiries(); // Refresh the inquiry list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark quotation as done')),
        );
      }
    }
  }

  Future<void> reassignQuotation(
      int inquiryId, int followUpUser, String description, int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('auth_token');

    if (userId != null && authToken != null) {
      try {
        final response = await ApiService.reassignQuotation(
          inquiryId: inquiryId,
          followUpUser: followUpUser,
          userId: userId,
          description: description,
          authToken: authToken,
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quotation reassigned successfully')),
          );
          fetchInquiries(); // Refresh the inquiry list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Failed to reassign quotation: ${response.body}')),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during reassigning quotation: $error')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID or auth token not found')),
      );
    }
  }

  Future<void> toggleWinOrLossStatus(int inquiryId, bool isWin) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userIdString = prefs.getString('userId');

      // Ensure userId is available and convert it to int
      if (userIdString == null) {
        throw Exception('User ID not found in local storage');
      }

      int? userId = int.tryParse(userIdString);

      // Ensure userId is a valid integer
      if (userId == null) {
        throw Exception('Invalid User ID format');
      }

      // Call the API to update the win/loss status with the current isWin value
      await ApiService.updateWinOrLossStatus(inquiryId, userId, isWin);

      // Update the local inquiry list state
      setState(() {
        inquiries = inquiries.map((inquiry) {
          if (inquiry['inquiryId'] == inquiryId) {
            inquiry['win'] = !isWin; // Toggle the win/loss status
          }
          return inquiry;
        }).toList();
      });
    } catch (e) {
      print('Error toggling win or loss status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update win/loss status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inquiry List',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF5A3EBA),
        centerTitle: true,
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
                      hintText: 'Search inquiries...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                IconButton(
                  onPressed: () => filterShowDialougBox(context),
                  icon: Icon(CupertinoIcons.slider_horizontal_3),
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
              : inquiries.isEmpty
                  ? const Expanded(
                      child: Center(
                        child: Text('No inquiries found'),
                      ),
                    )
                  : Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Inquiry ID')),
                              DataColumn(label: Text('Project Name')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Brand Name')),
                              DataColumn(label: Text('Product Name')),
                              DataColumn(label: Text('Remark')),
                              DataColumn(label: Text('Created At')),
                              DataColumn(label: Text('Updated At')),
                              DataColumn(label: Text('Win Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: inquiries.map((inquiry) {
                              bool? isWin = inquiry['isWin'];

                              bool quotationGiven =
                                  inquiry['quotationGiven'] ?? false;

                              return DataRow(
                                cells: [
                                  DataCell(Text(
                                      inquiry['inquiryId']?.toString() ??
                                          'N/A')),
                                  DataCell(
                                      Text(inquiry['projectName'] ?? 'N/A')),
                                  DataCell(
                                      Text(inquiry['inquiryStatus'] ?? 'N/A')),
                                  DataCell(Text(inquiry['product']?['brand']
                                          ?['brandName'] ??
                                      'N/A')),
                                  DataCell(Text(inquiry['product']
                                          ?['productName'] ??
                                      'N/A')),
                                  DataCell(Text(inquiry['remark'] ?? 'N/A')),
                                  DataCell(Text(inquiry['createdAt'] ?? 'N/A')),
                                  DataCell(Text(inquiry['updatedAt'] ?? 'N/A')),
                                  DataCell(
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Show both icons if isWin is null
                                        if (isWin == null) ...[
                                          IconButton(
                                            icon: const Icon(Icons.thumb_up,
                                                color: Colors.green),
                                            onPressed: () async {
                                              // Call toggleWinOrLossStatus with a win state
                                              await toggleWinOrLossStatus(
                                                  inquiry['inquiryId'], true);
                                              // Call fetchInquiries to reload the inquiries after updating the status
                                              await fetchInquiries();
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.thumb_down,
                                                color: Colors.red),
                                            onPressed: () async {
                                              // Call toggleWinOrLossStatus with a loss state
                                              await toggleWinOrLossStatus(
                                                  inquiry['inquiryId'], false);
                                              // Call fetchInquiries to reload the inquiries after updating the status
                                              await fetchInquiries();
                                            },
                                          ),
                                        ] else ...[
                                          // Show single icon based on isWin value
                                          IconButton(
                                            icon: Icon(
                                              isWin
                                                  ? Icons.thumb_up
                                                  : Icons.thumb_down,
                                              color: isWin
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                            onPressed: () async {
                                              // Toggle the status (if it's currently true, make it false and vice versa)
                                              await toggleWinOrLossStatus(
                                                  inquiry['inquiryId'], !isWin);
                                              // Call fetchInquiries to reload the inquiries after updating the status
                                              await fetchInquiries();
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility),
                                          color: Colors.blue,
                                          onPressed: () => onViewInquiry(
                                              inquiry['inquiryId']),
                                        ),
                                        if (isWin == null)
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            color: Colors.blue,
                                            onPressed: () => onEditInquiry(
                                                inquiries.indexOf(inquiry)),
                                          ),
                                        if (userRole == 'ADMIN')
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            color: Colors.red,
                                            onPressed: () => onDeleteInquiry(
                                                inquiries.indexOf(inquiry)),
                                          ),
                                        if (isWin == null && !quotationGiven)
                                          IconButton(
                                            icon:
                                                const Icon(Icons.check_circle),
                                            color: Colors.green,
                                            onPressed: () =>
                                                markQuotationDoneDialog(
                                                    inquiry['inquiryId']),
                                          )
                                        else if (isWin == null &&
                                            quotationGiven)
                                          IconButton(
                                            icon: const Icon(Icons.replay),
                                            color: Colors.orange,
                                            onPressed: () =>
                                                reassignQuotationDialog(
                                                    inquiry['inquiryId']),
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
    );
  }

  void filterShowDialougBox(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: Text(
              "Filter",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filter by Status
                InkWell(
                  onTap: () {
                    _showStatusFilterDialog(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.slider_horizontal_3, size: 24),
                        SizedBox(width: 15),
                        Text(
                          "Filter by Status",
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(),

                // Filter by Quotation
                InkWell(
                  onTap: () {
                    _showStatusFilterDialog(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.slider_horizontal_3, size: 24),
                        SizedBox(width: 15),
                        Text(
                          "Filter by Quotation",
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(),

                // Filter by Follow Up User
                InkWell(
                  onTap: () {
                    _showStatusFilterDialog(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.slider_horizontal_3, size: 24),
                        SizedBox(width: 15),
                        Text(
                          "Filter by Follow Up User",
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Submit and Reset buttons
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     ElevatedButton(
                //       onPressed: () {
                //         // Your logic to submit the filter
                //         Navigator.of(context)
                //             .pop(); // Close the dialog after submission
                //       },
                //       style: ElevatedButton.styleFrom(
                //         padding:
                //             EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                //         foregroundColor: Colors.blue, // Button color
                //       ),
                //       child: Text("Submit"),
                //     ),
                //     ElevatedButton(
                //       onPressed: () {
                //         // Your logic to reset the filter
                //         Navigator.of(context)
                //             .pop(); // Close the dialog after reset
                //       },
                //       style: ElevatedButton.styleFrom(
                //         padding:
                //             EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                //         foregroundColor: Colors.grey, // Button color for Reset
                //       ),
                //       child: Text("Reset"),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStatusFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedStatus = 'Tender'; // Change to an available value
        String searchQuery = ''; // To hold the search input

        return AlertDialog(
          title: Text("Select Status",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search Bar (commented out in your code)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        selectedStatus = newValue;
                        print("Selected Status: $selectedStatus");
                      }
                    },
                    items: ['Tender', 'Urgent', 'Procurement', 'Product']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                print("Confirmed: $selectedStatus");
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Apply"),
            ),
          ],
        );
      },
    );
  }

  void onViewInquiry(int inquiryId) {
    print('View Inquiry Clicked: $inquiryId'); // Debug statement
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            InquiryDetails(inquiryId: inquiryId), // Pass the integer directly
      ),
    );
  }
}
