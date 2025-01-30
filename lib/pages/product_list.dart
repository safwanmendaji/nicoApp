import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Make sure to import http package
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nicoapp/pages/create_product_page.dart';
import 'package:nicoapp/services/api_services.dart'; // Import your ApiService file
import 'package:nicoapp/pages/navbar.dart'; // Import your NavBar file

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  int currentPage = 1;
  int totalPages = 1;
  int totalRecords = 0;
  int pageSize = 10;
  bool isLoading = true;
  List products = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch userId from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId'); // Fetching userId

      if (userId == null) {
        throw Exception('User ID not found in local storage');
      }

      // Call the API service with the userId
      final data = await ApiService.fetchProducts(
          currentPage, pageSize, searchQuery, userId);
      setState(() {
        totalRecords =
            data['totalRecords'] ?? 0; // Use lowercase 'totalRecords'
        totalPages = (totalRecords / pageSize).ceil();
        products = data['productList'] ?? [];
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load products: $error')),
      );
      debugPrint('Error fetching products: $error');
    }
  }

  // Search query handler
  void onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
      currentPage = 1;
    });
    fetchProducts();
  }

  // Load the next page of products
  Future<void> loadNextPage() async {
    if (currentPage < totalPages) {
      setState(() {
        isLoading = true; // Show loading indicator
        currentPage++;
      });
      await fetchProducts();
    }
  }

  // Load the previous page of products
  Future<void> loadPreviousPage() async {
    if (currentPage > 1) {
      setState(() {
        isLoading = true; // Show loading indicator
        currentPage--;
      });
      await fetchProducts();
    }
  }

  void onEditProduct(int index) {
    final product = products[index]; // Assuming 'products' is your product list
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateProductPage(
          productData: product, // Pass the product data to the edit page
        ),
      ),
    );
  }

  // Delete product handler
  void onDeleteProduct(int index) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this product?'),
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
      // Call the delete API
      final productId =
          products[index]['productId']; // Assuming 'productId' is the key
      final success = await ApiService.deleteProduct(productId);

      if (success) {
        setState(() {
          products.removeAt(index); // Remove the product from the local list
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete product')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Product List',
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
                      hintText: 'Search products...',
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
              : products.isEmpty
                  ? const Expanded(
                      child: Center(
                        child: Text('No products found'),
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
                                  DataColumn(label: Text('Product Name')),
                                  DataColumn(label: Text('Price')),
                                  DataColumn(label: Text('Brand Name')),
                                  DataColumn(
                                      label: Text(
                                          'Running Inquires')), // New Column
                                  DataColumn(label: Text('Created At')),
                                  DataColumn(label: Text('Updated At')),
                                  DataColumn(
                                      label: Text('Actions')), // Actions column
                                ],
                                rows: products.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  var product = entry.value;
                                  return DataRow(
                                    cells: [
                                      DataCell(Text((index + 1)
                                          .toString())), // Sr No starts from 1
                                      DataCell(Text(
                                          product['productName'] ?? 'N/A')),
                                      DataCell(Text(
                                          product['price']?.toString() ??
                                              'N/A')),
                                      DataCell(Text(product['brand']
                                              ?['brandName'] ??
                                          'N/A')),
                                      DataCell(Text(
                                          product['inquiryCount']?.toString() ??
                                              'N/A')), // Display inquiryCount
                                      DataCell(
                                          Text(product['createdAt'] ?? 'N/A')),
                                      DataCell(
                                          Text(product['updatedAt'] ?? 'N/A')),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              color: Colors.blue,
                                              onPressed: () =>
                                                  onEditProduct(index),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              color: Colors.red,
                                              onPressed: () =>
                                                  onDeleteProduct(index),
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
