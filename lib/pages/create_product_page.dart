import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nicoapp/services/api_services.dart';
import 'package:nicoapp/pages/create_list_page.dart';

class CreateProductPage extends StatefulWidget {
  final Map<String, dynamic>? productData; // Optional product data for editing

  const CreateProductPage({super.key, this.productData});

  @override
  _CreateProductPageState createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  List<dynamic> _brands = [];
  List<dynamic> filteredBrands = [];
  String? selectedBrandId;
  String? selectedBrandName;
  bool _showBrandOptions = false;

  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _brandSearchController = TextEditingController();

  int? _userId;
  bool isLoading = true;
  bool isUpdate = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchUserId();
    _fetchBrandList();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.productData != null) {
      // It's an update, so populate fields with existing product data
      setState(() {
        isUpdate = true;
        _productNameController.text = widget.productData!['productName'];
        _productPriceController.text = widget.productData!['price'].toString();
        selectedBrandId = widget.productData!['brand']['brandId'].toString();
        selectedBrandName = widget.productData!['brand']['brandName'];
        _brandSearchController.text = selectedBrandName!;
      });
    }
  }

  Future<void> _fetchUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userIdString = prefs.getString('userId');
    if (userIdString != null) {
      setState(() {
        _userId = int.tryParse(userIdString);
      });
    }
  }

  Future<void> _fetchBrandList() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.fetchBrands(1, 10, '');
      setState(() {
        _brands = response['data'];
        filteredBrands = _brands;
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

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      if (selectedBrandId == null || _userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Please select a brand and ensure user is logged in')),
        );
        return;
      }

      final productData = {
        "productName": _productNameController.text,
        "price": double.parse(_productPriceController.text),
        "brand": {"brandId": int.parse(selectedBrandId!)},
        "createdBy": {"id": _userId}
      };

      try {
        if (isUpdate) {
          // Call update API
          await ApiService.updateProduct(
            productId: widget.productData!['productId'],
            productName: _productNameController.text,
            price: double.parse(_productPriceController.text),
            brandId: int.parse(selectedBrandId!),
            updatedById: _userId!,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully!')),
          );
        } else {
          // Call create API
          await ApiService.createProduct(
            productName: _productNameController.text,
            price: double.parse(_productPriceController.text),
            brandId: int.parse(selectedBrandId!),
            createdById: _userId!,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product created successfully!')),
          );
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CreateListPage()),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save product: $error')),
        );
      }
    }
  }

  Widget _buildBrandSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Brand',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _brandSearchController,
            decoration: InputDecoration(
              hintText: 'Search Brand',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: const Icon(Icons.search),
            ),
            onChanged: (String query) {
              setState(() {
                filteredBrands = _brands
                    .where((brand) => brand['brandName']
                        .toLowerCase()
                        .contains(query.toLowerCase()))
                    .toList();
              });
            },
            onTap: () {
              setState(() {
                _showBrandOptions = true;
              });
            },
          ),
          const SizedBox(height: 8),
          if (_showBrandOptions)
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Scrollbar(
                child: ListView.builder(
                  itemCount: filteredBrands.length,
                  itemBuilder: (context, index) {
                    final brand = filteredBrands[index];
                    return ListTile(
                      title: Text(brand['brandName'] ?? 'N/A'),
                      onTap: () {
                        setState(() {
                          selectedBrandId = brand['brandId'].toString();
                          selectedBrandName = brand['brandName'];
                          _brandSearchController.text = selectedBrandName!;
                          _showBrandOptions = false;
                        });
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isUpdate ? 'Update Product' : 'Create Product', // Corrected title
          style: const TextStyle(
            color: Colors.white, // Title color set to white
          ),
        ),
        backgroundColor:
            const Color(0xFF5A3EBA), // Ensure background color is set
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous page
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrandSearchField(),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Product Name',
                      controller: _productNameController,
                      hintText: 'Enter product name',
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter product name'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Product Price',
                      controller: _productPriceController,
                      hintText: 'Enter product price',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A3EBA),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isUpdate ? 'Update Product' : 'Save Product',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }
}
