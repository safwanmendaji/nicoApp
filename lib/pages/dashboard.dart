import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nicoapp/Model/general_followUp.dart';
import 'package:nicoapp/pages/Inquiry_details.dart';
import 'package:nicoapp/pages/create_general_followUp_page.dart';
import 'package:nicoapp/pages/header_page.dart';
import 'package:nicoapp/pages/inquiry_List_page.dart';
import 'package:nicoapp/pages/navbar.dart';
import 'package:nicoapp/services/api_services.dart';
import 'package:nicoapp/url.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import to format and fetch current month
import 'package:month_picker_dialog/month_picker_dialog.dart'; // Month picker import

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<dynamic> _inquiries = []; // Declare with underscore for consistency
  late Future<List<GeneralFollowUp>> _futureFollowUps;
  int tenderInquiryCount = 0;
  int procurementInquiryCount = 0;
  int purchaseInquiryCount = 0;
  int urgentInquiryCount = 0;
  int inquiryWin = 0;
  int inquiryLoss = 0;
  bool isLoading = true;

  List<dynamic> inquiries = [];

  final CalendarController _calendarController = CalendarController();
  late _MeetingDataSource _events = _MeetingDataSource([]);

  String _selectedMonth =
      DateFormat('MMM').format(DateTime.now()); // Set current month by default

  final List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  final Map<String, int> _monthMap = {
    'Jan': 1,
    'Feb': 2,
    'Mar': 3,
    'Apr': 4,
    'May': 5,
    'Jun': 6,
    'Jul': 7,
    'Aug': 8,
    'Sep': 9,
    'Oct': 10,
    'Nov': 11,
    'Dec': 12
  };

  DateTime? _selectedMonthStartDate;
  DateTime? _selectedMonthEndDate;

  @override
  void initState() {
    super.initState();
    _futureFollowUps = ApiService.fetchFollowUps(1, 10);
    _loadDashboardData();
    _updateCalendarForMonth(_monthMap[_selectedMonth]!);
    _fetchInquiries();
  }

  void _updateCalendarForMonth(int month) {
    final DateTime now = DateTime.now();
    final DateTime firstDayOfMonth = DateTime(now.year, month, 1);
    final DateTime lastDayOfMonth = DateTime(now.year, month + 1, 0);

    setState(() {
      _selectedMonthStartDate = firstDayOfMonth;
      _selectedMonthEndDate = lastDayOfMonth;
    });

    fetchCalendarEvents(month); // Fetch events for the current month
  }

  Future<void> fetchCalendarEvents(int month) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('auth_token');
    String? userIdString = prefs.getString('userId');
    int? userId = int.tryParse(userIdString ?? '');

    if (authToken == null || userId == null) {
      _showError('auth_token or userId is missing from local storage');
      return;
    }

    final String apiUrl =
        '${Url.baseUrl}dashboard/calenderevent?month=$month&userId=$userId';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['data'] != null && jsonResponse['data'] is Map) {
          final Map<String, dynamic> data = jsonResponse['data'];
          List<_Meeting> meetings = [];

          _events = _MeetingDataSource([]); // Clear previous events

          data.forEach((dateString, events) {
            DateTime eventDate = DateTime.parse(dateString);
            for (var event in events) {
              meetings.add(_Meeting(
                event['generalFollowUpName'],
                event['description'],
                null,
                null,
                DateTime.parse(event['dueDate']), // Parse the due date
                DateTime.parse(event['dueDate'])
                    .add(const Duration(hours: 2)), // End time
                const Color(0xFF0A8043), // Color for the event
                false,
                '',
                '',
                '',
              ));
            }
          });

          setState(() {
            _events =
                _MeetingDataSource(meetings); // Update calendar data source
            isLoading = false;
          });
        } else {
          throw Exception('Invalid data structure in response');
        }
      } else {
        _showError(
            'Failed to load calendar events. Status code: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error fetching calendar events: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadDashboardData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      String? userId = prefs.getString('userId');

      if (token != null && userId != null) {
        final data = await ApiService.fetchDashboardData(userId, token);
        setState(() {
          tenderInquiryCount = data['tenderInquiryCount'];
          procurementInquiryCount = data['procurementInquiryCount'];
          purchaseInquiryCount = data['purchaseInquiryCount'];
          urgentInquiryCount = data['urgentInquiryCount'];
          isLoading = false;
        });
      } else {
        _showError('Failed to retrieve user credentials.');
      }
    } catch (e) {
      _showError('Error fetching dashboard data: $e');
    }
  }

  Future<void> _pickMonth(BuildContext context) async {
    DateTime? selectedDate = await showMonthPicker(
      context: context,
      initialDate:
          DateTime(DateTime.now().year, _monthMap[_selectedMonth] ?? 1),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      String newSelectedMonth = DateFormat('MMM').format(selectedDate);
      _onMonthChanged(newSelectedMonth);
    }
  }

  void _onMonthChanged(String? newMonth) {
    if (newMonth != null) {
      setState(() {
        _selectedMonth = newMonth;
        isLoading = true;
        _events = _MeetingDataSource([]); // Clear previous events
      });

      _updateCalendarForMonth(_monthMap[_selectedMonth]!);
    }
  }

  Future<void> _markFollowUpAsDone(int followUpId, String description) async {
    try {
      await ApiService.markFollowUpAsDone(followUpId, 2, description);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Follow-up marked as done successfully!')),
      );

      setState(() {
        isLoading = true; // Show loader while fetching new data
      });

      _futureFollowUps = ApiService.fetchFollowUps(1, 10);
      _futureFollowUps.then((value) {
        setState(() {
          isLoading = false; // Hide loader after data is fetched
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _showDescriptionDialog(int followUpId) async {
    final TextEditingController _descriptionController =
        TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must provide a description to close
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                    'Please provide a description before marking as done.'),
                const SizedBox(height: 10),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Enter description',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Close dialog without marking done
              },
            ),
            ElevatedButton(
              child: const Text('Mark Done'),
              onPressed: () {
                if (_descriptionController.text.isNotEmpty) {
                  Navigator.of(context).pop(); // Close dialog
                  _markFollowUpAsDone(followUpId, _descriptionController.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Description is required to mark as done!')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildInquiryCard(String title, String count, Color color,
      {double sizeMultiplier = 1.0}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: (MediaQuery.of(context).size.width / 2) * sizeMultiplier,
        padding: EdgeInsets.all(16 * sizeMultiplier),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 10 * sizeMultiplier,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              count,
              style: TextStyle(
                fontSize: 22 * sizeMultiplier,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpTable(List<GeneralFollowUp> followUps) {
    print("followups ====>>> ${followUps}");
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: const Text(
              'Today\'s Reminders',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8.0),
          SingleChildScrollView(
            //scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 15.0,
              border: TableBorder.all(color: Colors.grey.shade300),
              columns: const [
                DataColumn(
                  label:
                      Text('Sr', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text(
                    'Reminder Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DataColumn(
                  label: Text('Due Date',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                DataColumn(
                  label: Text('Actions',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
              rows: followUps.asMap().entries.map((entry) {
                int index = entry.key;
                var followUp = entry.value;
                DateTime dueDate = DateTime.parse(followUp.dueDate!);
                Color bulletColor =
                    DateTime.now().difference(dueDate).inDays >= 3
                        ? Colors.red
                        : Colors.yellow;

                return DataRow(
                  cells: [
                    DataCell(Text(
                        (index + 1).toString())), // Sr No. will be (index + 1)
                    DataCell(Row(
                      children: [
                        Icon(Icons.circle, color: bulletColor, size: 10),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            (followUp.generalFollowUpName?.length ?? 0) > 15
                                ? '${followUp.generalFollowUpName!.substring(0, 10)}...'
                                : followUp.generalFollowUpName ?? 'N/A',
                            style: TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )),
                    DataCell(Text(DateFormat('yyyy-MM-dd').format(dueDate))),
                    DataCell(Row(
                      children: [
                        IconButton(
                            onPressed: () => _showEyeDialog(followUp),
                            icon: Icon(Icons.remove_red_eye))
                      ],
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showEyeDialogForInquery(Map<String, dynamic> inquiry) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Text('Inquiry Details'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            //crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                "Project Name:",
                '${inquiry['product']?['productName']}' ?? 'N/A',
              ),
              // // Text(
              // //   "Product Details:",
              // //   style: TextStyle(fontWeight: FontWeight.bold),
              // // ),
              // _buildDetailRow(
              //   "      Name:",
              //   '${inquiry['product']?['productName']}' ?? 'N/A',
              // ),
              // _buildDetailRow(
              //   "      Brand:",
              //   '${inquiry['product']?['brand']?['brandName']}' ?? 'N/A',
              // ),
              _buildDetailRow(
                "Status ",
                '${inquiry['inquiryStatus'] ?? 'N/A'}',
              ),
              _buildDetailRow(
                "Description ",
                '${inquiry['description'] ?? 'N/A'}',
              ),
              // Text(
              //   "Consumer Detail:",
              //   style: TextStyle(fontWeight: FontWeight.bold),
              // ),
              // _buildDetailRow(
              //   "       Name:",
              //   '${inquiry['consumer']?['consumerName'] ?? 'N/A'}',
              // ),
              // _buildDetailRow(
              //   "       Contact:",
              //   '${inquiry['consumer']?['contact'] ?? 'N/A'}',
              // ),
              // Text(
              //   "Consultant:",
              //   style: TextStyle(fontWeight: FontWeight.bold),
              // ),
              // _buildDetailRow(
              //   "       Name:",
              //   '${inquiry['consultant']?['consultantName'] ?? 'N/A'}',
              // ),
              // _buildDetailRow(
              //   "       Person:",
              //   '${inquiry['consultant']?['contactPerson'] ?? 'N/A'}',
              // ),
              // _buildDetailRow(
              //   "       Number:",
              //   '${inquiry['consultant']?['contactNumber'] ?? 'N/A'}',
              // ),
              _buildDetailRow(
                "Follow-Up User ",
                '${inquiry['followUpUser']?['name']}' ?? 'N/A',
              ),
              _buildDetailRow(
                "Follow-Up Quotation ",
                '${inquiry['followUpQuotation']?['name']}' ?? 'N/A',
              ),
              // _buildDetailRow(
              //   "Remark:",
              //   '${inquiry['remark'] ?? 'N/A'}',
              // ),
              // _buildDetailRow(
              //   "Created By:",
              //   '${inquiry['createdBy']?['name']}' ?? 'N/A',
              // ),
              // _buildDetailRow(
              //   "Created Date:",
              //   inquiry['createdAt'] != null
              //       ? DateFormat('yyyy-MM-dd').format(
              //           DateTime.parse(inquiry['createdAt']),
              //         )
              //       : 'N/A',
              // ),
              // _buildDetailRow(
              //   "Updated By:",
              //   '${inquiry['updatedBy']?['name']}' ?? 'N/A',
              // ),
              // _buildDetailRow(
              //   "Updated Date:",
              //   inquiry['updatedAt'] != null
              //       ? DateFormat('yyyy-MM-dd').format(
              //           DateTime.parse(inquiry['updatedAt']),
              //         )
              //       : 'N/A',
              // ),
              // _buildDetailRow(
              //   "Status:",
              //   inquiry['isWin'] == null
              //       ? 'N/A'
              //       : (inquiry['isWin'] ? 'True' : 'False'),
              // ),
              // _buildDetailRow(
              //   "Quotation Given:",
              //   '${inquiry['quotationGiven'] ?? 'N/A'}',
              // ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InquiryDetails(
                              inquiryId: inquiry[
                                  'inquiryId']), // Pass the integer directly
                        ),
                      );
                    },
                    child: Text("View More")),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  void _showEyeDialog(GeneralFollowUp followUp) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Text(
              'Reminder Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                    "Reminder Name", followUp.generalFollowUpName ?? 'N/A'),
                _buildDetailRow("Description", followUp.description ?? 'N/A'),
                _buildDetailRow("Created ON", followUp.createdAt ?? 'N/A'),
                _buildDetailRow("Due Date", followUp.dueDate ?? 'N/A'),
                _buildDetailRow(
                    "Created Person Name", followUp.createdBy.name ?? 'N/A'),
                _buildDetailRow("Status", followUp.status ?? 'N/A'),
                if (followUp.status == "COMPLETED") ...[
                  _buildDetailRow(
                      "Status Notes", followUp.statusNotes ?? 'N/A'),
                  _buildDetailRow(
                      "Updated Person Name", followUp.updatedBy?.name ?? 'N/A'),
                  _buildDetailRow("Updated ON", followUp.updatedAt ?? 'N/A'),
                ],
                SizedBox(height: 16),
                if (followUp.status != "COMPLETED") ...[
                  ListTile(
                    leading: Icon(Icons.edit, color: Colors.blue),
                    title: Text('Edit Follow-up'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _editFollowUp(followUp); // Open the edit functionality
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text('Mark as Completed'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showDescriptionDialog(followUp
                          .generalFollowUpId); // Show description dialog
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _editFollowUp(GeneralFollowUp followUp) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CreateGeneralFollowUpPage(followUp: followUp)),
    );
  }

  /// Fetch inquiries from the API
  Future<void> _fetchInquiries() async {
    try {
      // Fetch data from the API
      Map<String, dynamic> fetchedData =
          await ApiService.fetchInquiriesForDashboard();

      // Extract only the inquiryList from the fetched data
      List<dynamic> fetchedInquiries = fetchedData['inquiryList']['content'];

      setState(() {
        inquiries = fetchedInquiries; // Update state with fetched inquiries
        isLoading = false; // Stop loading indicator
      });
    } catch (e) {
      print('Error fetching inquiries: $e');
      setState(() {
        isLoading = false; // Stop loading in case of error
      });
    }
  }

  // Build inquiry table
  Widget _buildInquiryTable(List<dynamic>? inquiryList) {
    if (inquiryList == null || inquiryList.isEmpty) {
      return Center(
        child: Text('No records available', style: TextStyle(fontSize: 16)),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: const Text(
              'Inquiry',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8.0),
          SingleChildScrollView(
            //scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 7.0,
              border: TableBorder.all(color: Colors.grey.shade300),
              columns: const [
                DataColumn(
                  label: Text('Sr No.',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                DataColumn(
                  label: Text('Project',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                // DataColumn(
                //   label: Text('Consumer Name',
                //       style: TextStyle(fontWeight: FontWeight.bold)),
                // ),
                // DataColumn(
                //   label: Text('Brand Name',
                //       style: TextStyle(fontWeight: FontWeight.bold)),
                // ),
                DataColumn(
                  label: Text('Product ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                DataColumn(
                  label: Text('Status',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                DataColumn(
                  label: Text('Action',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
              rows: inquiryList.asMap().entries.map<DataRow>((entry) {
                int index = entry.key + 1; // Adding 1 to start Sr No. from 1
                var inquiry = entry.value;
                return DataRow(
                  cells: [
                    DataCell(Text(index.toString())), // Sr No.

                    DataCell(Text(inquiry['projectName'] ?? 'N/A')),
                    // DataCell(
                    //     Text(inquiry['consumer']?['consumerName'] ?? 'N/A')),
                    // DataCell(Text(
                    //     inquiry['product']?['brand']?['brandName'] ?? 'N/A')),
                    DataCell(Text(inquiry['product']?['productName'] ?? 'N/A')),
                    DataCell(Text(inquiry['inquiryStatus'] ?? 'N/A')),
                    DataCell(Row(
                      children: [
                        IconButton(
                            onPressed: () => _showEyeDialogForInquery(inquiry),
                            icon: Icon(Icons.remove_red_eye))
                      ],
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderPage(pageTitle: 'Dashboard'),
      body: Column(
        children: [
          Expanded(
            child: Scrollbar(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(10.0),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row for TENDER and PROCUREMENT inquiries
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  // Navigate to the TENDER inquiries page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => InquiryListPage(
                                          inquiryStatus: 'TENDER'),
                                    ),
                                  );
                                },
                                child: _buildInquiryCard(
                                  'TENDER',
                                  '$tenderInquiryCount',
                                  const Color.fromRGBO(106, 11, 195, 1),
                                  sizeMultiplier: 0.7,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // Navigate to the PROCUREMENT inquiries page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => InquiryListPage(
                                          inquiryStatus: 'PROCUREMENT'),
                                    ),
                                  );
                                },
                                child: _buildInquiryCard(
                                  'PROCUREMENT',
                                  '$procurementInquiryCount',
                                  const Color.fromRGBO(106, 11, 195, 1),
                                  sizeMultiplier: 0.7,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),

                          // Row for PURCHASE and URGENT inquiries
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  // Navigate to the PURCHASE inquiries page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => InquiryListPage(
                                          inquiryStatus: 'PURCHASE'),
                                    ),
                                  );
                                },
                                child: _buildInquiryCard(
                                  'PURCHASE',
                                  '$purchaseInquiryCount',
                                  const Color.fromRGBO(106, 11, 195, 1),
                                  sizeMultiplier: 0.7,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // Navigate to the URGENT inquiries page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => InquiryListPage(
                                          inquiryStatus: 'URGENT'),
                                    ),
                                  );
                                },
                                child: _buildInquiryCard(
                                  'URGENT',
                                  '$urgentInquiryCount',
                                  const Color.fromRGBO(106, 11, 195, 1),
                                  sizeMultiplier: 0.7,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),

                          // Today's Reminders section
                          // const Text(
                          //   'Today\'s Reminders',
                          //   style: TextStyle(
                          //       fontSize: 18, fontWeight: FontWeight.bold),
                          // ),
                          const SizedBox(height: 8.0),
                          FutureBuilder<List<GeneralFollowUp>>(
                            future: _futureFollowUps,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Center(
                                    child: Text('Error: ${snapshot.error}'));
                              } else if (snapshot.data == null ||
                                  snapshot.data!.isEmpty) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: const Text(
                                        'Reminders',
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(height: 10.0),
                                    const Center(
                                      child: Text(
                                        'Reminders Not Available.',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              final followUps = snapshot.data!;

                              return Column(
                                children: [
                                  _buildFollowUpTable(
                                      followUps), // Display follow-up table
                                  const SizedBox(
                                      height: 16.0), // Space between tables
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16.0),

                          // Inquiry section title
                          // const Text(
                          //   'Inquiry',
                          //   style: TextStyle(
                          //       fontSize: 18, fontWeight: FontWeight.bold),
                          // ),
                          const SizedBox(height: 8.0),

                          // Display today's inquiries
                          _buildInquiryTable(
                              inquiries), // Call to your inquiry table method
                          const SizedBox(height: 16.0),
                          _buildCalendarWithMonthSelector(),
                        ],
                      ),
              ),
            ),
          ),
          const NavBar(initialIndex: 0),
        ],
      ),
    );
  }

  // Calendar with embedded month selector
  Widget _buildCalendarWithMonthSelector() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: const Color.fromARGB(255, 117, 103, 103), width: 2.0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            // Custom calendar header with month selector
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Select Month: ",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, color: Colors.black),
                    label: Text(
                      _selectedMonth,
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    onPressed: () {
                      _pickMonth(context); // Call to open the month picker
                    },
                  ),
                ],
              ),
            ),
            // Calendar itself
            SizedBox(
              height: 400,
              child: SfCalendar(
                view: CalendarView.month,
                controller: _calendarController,
                dataSource: _events,
                showDatePickerButton: false,
                headerHeight: 0, // Disable the default header
                minDate: _selectedMonthStartDate,
                maxDate: _selectedMonthEndDate,
                monthViewSettings: const MonthViewSettings(
                  showAgenda: true,
                  numberOfWeeksInView: 6,
                ),
                timeSlotViewSettings: const TimeSlotViewSettings(
                  minimumAppointmentDuration: Duration(minutes: 60),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InquiryDetailsPage {
  const InquiryDetailsPage();
}

// Model class for meetings (events in the calendar)
class _Meeting {
  _Meeting(
    this.eventName,
    this.description,
    this.contactID,
    this.capacity,
    this.from,
    this.to,
    this.background,
    this.isAllDay,
    this.startTimeZone,
    this.endTimeZone,
    this.recurrenceRule,
  );

  String eventName;
  String description;
  String? contactID;
  int? capacity;
  DateTime from;
  DateTime to;
  Color background;
  bool isAllDay;
  String? startTimeZone;
  String? endTimeZone;
  String? recurrenceRule;
}

// Custom data source for calendar
class _MeetingDataSource extends CalendarDataSource {
  _MeetingDataSource(this.source);

  List<_Meeting> source;

  @override
  List<_Meeting> get appointments => source;

  @override
  DateTime getStartTime(int index) => source[index].from;

  @override
  DateTime getEndTime(int index) => source[index].to;

  @override
  bool isAllDay(int index) => source[index].isAllDay;

  @override
  String getSubject(int index) => source[index].eventName;

  @override
  Color getColor(int index) => source[index].background;
}
