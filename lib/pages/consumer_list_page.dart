// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:nicoapp/pages/create_consumer_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nicoapp/pages/navbar.dart';
import 'package:nicoapp/services/api_services.dart';

class ConsumerListPage extends StatefulWidget {
  const ConsumerListPage({super.key});

  @override
  _ConsumerListPageState createState() => _ConsumerListPageState();
}

class _ConsumerListPageState extends State<ConsumerListPage> {
  int currentPage = 1;
  int totalPages = 1;
  int totalRecords = 0;
  int pageSize = 10;
  bool isLoading = true;
  List consumers = [];
  String? userId;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadUserId(); // Load userId when the page is initialized
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
    fetchConsumers(); // Fetch consumers after loading userId
  }

  Future<void> fetchConsumers() async {
    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      final data = await ApiService.fetchConsumers(
        currentPage,
        pageSize,
        searchQuery,
      );

      setState(() {
        totalRecords = data['totalRecords'] ?? 0;
        totalPages = (totalRecords / pageSize).ceil();
        consumers = data['consumers'] ?? [];
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load consumers: $error')),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
      await fetchConsumers();
    }
  }

  Future<void> loadPreviousPage() async {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
      await fetchConsumers();
    }
  }

  void onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
      currentPage = 1; // Reset to the first page when search changes
    });
    fetchConsumers();
  }

  void onEditConsumer(int index) {
    final consumer = consumers[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateConsumerPage(consumer: consumer),
      ),
    );
  }

  Future<void> onDeleteConsumer(int index) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this consumer?'),
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
      final consumerId = consumers[index]['consumerId'];

      bool deleted = await ApiService.deleteConsumer(consumerId);
      if (deleted) {
        setState(() {
          consumers.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consumer deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete consumer')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Consumer  List',
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search consumers...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: onSearchChanged,
                  ),
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
              : consumers.isEmpty
                  ? const Expanded(
                      child: Center(
                        child: Text('No consumers found'),
                      ),
                    )
                  : Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Sr No')),
                                  DataColumn(label: Text('Name')),
                                  DataColumn(label: Text('Email')),
                                  DataColumn(label: Text('Address')),
                                  DataColumn(label: Text('Contact')),
                                  DataColumn(label: Text('Created At')),
                                  DataColumn(label: Text('Created By')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: consumers.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  var consumer = entry.value;
                                  return DataRow(
                                    cells: [
                                      // Replace consumerId with Sr No
                                      DataCell(Text((index + 1)
                                          .toString())), // Sr No starts from 1
                                      DataCell(Text(
                                          consumer['consumerName'] ?? 'N/A')),
                                      DataCell(
                                          Text(consumer['emailId'] ?? 'N/A')),
                                      DataCell(
                                          Text(consumer['address'] ?? 'N/A')),
                                      DataCell(
                                          Text(consumer['contact'] ?? 'N/A')),
                                      DataCell(
                                          Text(consumer['createdAt'] ?? 'N/A')),
                                      DataCell(Text(consumer['createdBy']
                                              ?['name'] ??
                                          'N/A')),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              color: Colors.blue,
                                              onPressed: () =>
                                                  onEditConsumer(index),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              color: Colors.red,
                                              onPressed: () =>
                                                  onDeleteConsumer(index),
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
