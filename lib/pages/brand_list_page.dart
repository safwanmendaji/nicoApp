import 'package:flutter/material.dart';
import 'package:nicoapp/services/api_services.dart';
import 'package:nicoapp/pages/navbar.dart';
import 'package:nicoapp/pages/create_brand_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BrandListPage extends StatefulWidget {
  const BrandListPage({super.key});

  @override
  _BrandListPageState createState() => _BrandListPageState();
}

class _BrandListPageState extends State<BrandListPage> {
  int currentPage = 1;
  int totalPages = 1;
  int totalRecords = 0;
  int pageSize = 10;
  bool isLoading = true;
  List brands = [];
  String? userId;
  String searchQuery = "";

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
    if (userId != null) {
      await fetchBrands();
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

  Future<void> fetchBrands() async {
    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      final data = await ApiService.fetchBrands(
        currentPage,
        pageSize,
        searchQuery,
      );

      setState(() {
        totalRecords = data['data'].length;
        totalPages = (totalRecords / pageSize).ceil();
        brands = data['data'] ?? [];
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load brands: $error')),
      );
    }
  }

  void onEditBrand(int index) {
    final brand = brands[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateBrandPage(brand: brand),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Brand List',
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
                      hintText: 'Search brands...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: (query) {
                      setState(() {
                        searchQuery = query;
                        currentPage = 1;
                      });
                      fetchBrands();
                    },
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
              : brands.isEmpty
                  ? const Expanded(
                      child: Center(
                        child: Text('No brands found'),
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
                              DataColumn(label: Text('Brand Name')),
                              DataColumn(label: Text('Created At')),
                              DataColumn(label: Text('Created By')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: brands.asMap().entries.map((entry) {
                              int index = entry.key;
                              var brand = entry.value;
                              return DataRow(
                                cells: [
                                  // Display Sr No instead of brandId
                                  DataCell(Text((index + 1)
                                      .toString())), // Sr No starts from 1
                                  DataCell(Text(brand['brandName'] ?? 'N/A')),
                                  DataCell(Text(brand['createdAt'] ?? 'N/A')),
                                  DataCell(Text(
                                      brand['createdBy']['name'] ?? 'N/A')),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          color: Colors.blue,
                                          onPressed: () => onEditBrand(index),
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
        ],
      ),
      // bottomNavigationBar: const NavBar(),
    );
  }
}
