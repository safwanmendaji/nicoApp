import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nicoapp/url.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class InquiryDetails extends StatefulWidget {
  final int inquiryId;

  const InquiryDetails({Key? key, required this.inquiryId}) : super(key: key);

  @override
  _InquiryDetailsState createState() => _InquiryDetailsState();
}

class _InquiryDetailsState extends State<InquiryDetails> {
  Map<String, dynamic>? inquiryDetails;
  List<Map<String, dynamic>> inquiryHistory = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchInquiryDetails();
  }

  // Fetch inquiry details and history by ID
  Future<void> fetchInquiryDetails() async {
    try {
      final details = await fetchInquiryById(widget.inquiryId);
      setState(() {
        inquiryDetails = details;
        inquiryHistory = [
          {'date': '02/01/2024', 'action': 'Inquiry Received'},
          {'date': '03/02/2024', 'action': 'Follow-up Made'},
          {'date': '04/03/2024', 'action': 'Quotation Sent'},
          {'date': '05/04/2024', 'action': 'Awaiting Response'},
        ];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // Fetch inquiry by ID API
  static Future<Map<String, dynamic>?> fetchInquiryById(int inquiryId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final String url = '${Url.baseUrl}inquiry/get/inquiry-details/$inquiryId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody.containsKey('data')) {
          return responseBody['data'];
        } else {
          throw Exception('Inquiry data not found');
        }
      } else {
        throw Exception('Failed to load inquiry details: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching inquiry: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inquiry Details'),
        backgroundColor: const Color(0xFF5A3EBA),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? Center(child: Text('Error: $errorMessage'))
                : inquiryDetails != null
                    ? buildInquiryDetails()
                    : const Center(child: Text('No inquiry details found')),
      ),
    );
  }

  Widget buildInquiryDetails() {
    return Card(
      elevation: 4,
      child: SizedBox(
        width: double.infinity, // Full width
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Inquiry Details
                Text('Inquiry ID: ${inquiryDetails?['inquiryId'] ?? 'N/A'}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text(
                    'Project Name: ${inquiryDetails?['projectName'] ?? 'N/A'}'),
                Text(
                    'Inquiry Type: ${inquiryDetails?['inquiryType'] ?? 'N/A'}'),
                Text('Status: ${inquiryDetails?['inquiryStatus'] ?? 'N/A'}'),
                Text('Created At: ${formatDate(inquiryDetails?['createdAt'])}'),
                Text('Updated At: ${formatDate(inquiryDetails?['updatedAt'])}'),
                Text('Remark: ${inquiryDetails?['remark'] ?? 'N/A'}'),
                const SizedBox(height: 12),

                // Consumer Details
                const Text('Consumer Details',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                    'Name: ${inquiryDetails?['consumer']?['consumerName'] ?? 'N/A'}'),
                Text(
                    'Email: ${inquiryDetails?['consumer']?['emailId'] ?? 'N/A'}'),
                Text(
                    'Contact: ${inquiryDetails?['consumer']?['contact'] ?? 'N/A'}'),
                Text(
                    'Address: ${inquiryDetails?['consumer']?['address'] ?? 'N/A'}'),
                Text(
                    'Created By: ${inquiryDetails?['consumer']?['createdBy']?['name'] ?? 'N/A'}'),
                const SizedBox(height: 12),

                // Product Details
                const Text('Product Details',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                    'Product Name: ${inquiryDetails?['product']?['productName'] ?? 'N/A'}'),
                Text('Price: ${inquiryDetails?['product']?['price'] ?? 'N/A'}'),
                Text(
                    'Brand: ${inquiryDetails?['product']?['brand']?['brandName'] ?? 'N/A'}'),
                Text(
                    'Created By: ${inquiryDetails?['product']?['createdBy']?['name'] ?? 'N/A'}'),
                const SizedBox(height: 12),

                // Consultant Details
                const Text('Consultant Details',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                    'Name: ${inquiryDetails?['consultant']?['consultantName'] ?? 'N/A'}'),
                Text(
                    'Contact Person: ${inquiryDetails?['consultant']?['contactPerson'] ?? 'N/A'}'),
                Text(
                    'Contact Number: ${inquiryDetails?['consultant']?['contactNumber'] ?? 'N/A'}'),
                const SizedBox(height: 12),

                // Follow-Up User
                const Text('Follow-up User',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                    'Name: ${inquiryDetails?['followUpUser']?['name'] ?? 'N/A'}'),
                Text(
                    'Email: ${inquiryDetails?['followUpUser']?['email'] ?? 'N/A'}'),
                const SizedBox(height: 12),

                // Follow-Up Quotation
                const Text('Follow-up Quotation',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                    'Name: ${inquiryDetails?['followUpQuotation']?['name'] ?? 'N/A'}'),
                Text(
                    'Email: ${inquiryDetails?['followUpQuotation']?['email'] ?? 'N/A'}'),
                const SizedBox(height: 12),

                // Description Details
                const Text('Description Details',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...(inquiryDetails?['descriptionDetails'] as List? ?? [])
                    .map((description) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Description: ${description['description'] ?? 'N/A'}'),
                      Text(
                          'Follow-Up User: ${description['followUpUserName'] ?? 'N/A'}'),
                      Text(
                          'Created At: ${formatDate(description['createdAt'])}'),
                      const Divider(),
                    ],
                  );
                }).toList(),
                const SizedBox(height: 12),

                // // Quotation Given
                // Text(
                //     'Quotation Given: ${inquiryDetails?['quotationGiven'] == true ? 'Yes' : 'No'}'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Format date for display
  String formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    } catch (e) {
      return 'Invalid date'; // Handle parsing error
    }
  }
}
