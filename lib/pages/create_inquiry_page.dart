import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nicoapp/services/api_services.dart'; // Import your ApiService
import 'package:nicoapp/pages/navbar.dart'; // Import your NavBar

class CreateInquiryPage extends StatefulWidget {
  final Map<String, dynamic>? inquiryData; // Existing inquiry data for update

  const CreateInquiryPage({super.key, this.inquiryData});

  @override
  // ignore: library_private_types_in_public_api
  _CreateInquiryPageState createState() => _CreateInquiryPageState();
}

class _CreateInquiryPageState extends State<CreateInquiryPage> {
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _inquiryTypeController = TextEditingController();
  final TextEditingController _inquiryStatusController =
      TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _consumerSearchController =
      TextEditingController();
  final TextEditingController _consultantSearchController =
      TextEditingController();
  final TextEditingController _followUpUserSearchController =
      TextEditingController();
  final TextEditingController _followUpQuotationSearchController =
      TextEditingController();

  bool isLoading = false;
  bool isUpdate = false; // Flag to check if we are updating an inquiry
  int? createdById;

  List<dynamic> consumers = [];
  List<dynamic> filteredConsumers = [];
  List<dynamic> consultants = [];
  List<dynamic> filteredConsultants = [];
  List<dynamic> followUpUsers = [];
  List<dynamic> filteredFollowUpUsers = [];
  List<dynamic> followUpQuotations = [];
  List<dynamic> filteredFollowUpQuotations = [];
  List<dynamic> brands = [];
  List<dynamic> filteredBrands = [];
  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];

  int? selectedConsumerId;
  String? selectedConsumerName;
  int? selectedConsultantId;
  String? selectedConsultantName;
  int? selectedFollowUpUserId;
  String? selectedFollowUpUserName;
  int? selectedFollowUpQuotationId;
  String? selectedFollowUpQuotationName;
  int? selectedBrandId;
  String? selectedBrandName;
  int? selectedProductId;
  String? selectedProductName;

  bool _showConsumerOptions = false;
  bool _showConsultantOptions = false;
  bool _showFollowUpUserOptions = false;
  bool _showFollowUpQuotationOptions = false;
  bool _showBrandOptions = false;
  bool _showProductOptions = false;

  String? _selectedInquiryType; // Variable for selected inquiry type
  final List<String> _inquiryTypes = [
    'Tendering',
    'Urgent',
    'Procurement'
  ]; // Dropdown options

  String? _selectedInquiryStatus; // Variable for selected inquiry status
  final List<String> _inquiryStatuses = [
    'TENDER',
    'PROCUREMENT',
    'PURCHASE',
    'URGENT',
  ]; // Status options

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserId(); // Load user ID
    if (widget.inquiryData != null) {
      isUpdate = true;
      _initializeForm();
      _fetchInitialData();
    } else {
      _fetchInitialData();
    }
  }

  Future<void> _fetchProductsByBrand(int brandId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.fetchProductsByBrand(brandId);
      print(response); // Log the response here to inspect the raw data
      setState(() {
        products = (response).map((product) {
          return {
            'productId': product['productId'] ?? 0, // Default to 0 if null
            'productName': product['productName'] ?? 'Unknown',
            'price': product['price'] ?? 0.0,
          };
        }).toList();
        filteredProducts = products;
        isLoading = false;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? createdByIdString = prefs.getString('userId');
    if (createdByIdString != null) {
      setState(() {
        createdById = int.tryParse(createdByIdString);
      });
    }
  }

  void _initializeForm() {
    if (widget.inquiryData != null) {
      // This is an update, populate the fields with existing inquiry data
      final data = widget.inquiryData!;

      // Map the data from the API response to form fields
      _projectNameController.text = data['projectName'] ?? '';
      _remarkController.text = data['remark'] ?? '';
      _descriptionController.text = data['description'] ?? '';

      // Set the selected inquiry type and status for dropdowns
      _selectedInquiryType = data['inquiryType'] ?? null;
      _selectedInquiryStatus = data['inquiryStatus'] ?? null;

      // Set consumer, consultant, follow-up user, and other related fields
      selectedConsumerId = data['consumer']['consumerId'];
      selectedConsumerName = data['consumer']['consumerName'];
      selectedConsultantId = data['consultant']['consultantId'];
      selectedConsultantName = data['consultant']['consultantName'];
      selectedFollowUpUserId = data['followUpUser']['id'];
      selectedFollowUpUserName = data['followUpUser']['name'];
      selectedFollowUpQuotationId = data['followUpQuotation']['id'];
      selectedFollowUpQuotationName = data['followUpQuotation']['name'];

      // Set product and brand fields
      selectedBrandId = data['product']['brand']['brandId'];
      selectedBrandName = data['product']['brand']['brandName'];
      selectedProductId = data['product']['productId'];
      selectedProductName = data['product']['productName'];
    } else {
      // This is a new inquiry, so clear the fields
      _selectedInquiryType = null;
      _selectedInquiryStatus = null;
      selectedConsumerId = null;
      selectedConsultantId = null;
      selectedFollowUpUserId = null;
      selectedFollowUpQuotationId = null;
      selectedBrandId = null;
      selectedProductId = null;
    }
  }

  Future<void> _fetchInitialData() async {
    await _fetchConsumers();
    await _fetchConsultants();
    await _fetchFollowUpUsers();
    await _fetchFollowUpQuotations();
    await _fetchBrands();
  }

  Future<void> _fetchBrands([String searchQuery = '']) async {
    setState(() {
      isLoading = true; // Show loading state
    });

    try {
      final response = await ApiService.fetchBrands(1, 10, searchQuery);
      setState(() {
        brands = response['data'] ?? [];
        filteredBrands = brands;
        isLoading = false; // Hide loading state
      });
    } catch (e) {
      setState(() {
        isLoading = false; // Hide loading state
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load brands: $e')),
      );
    }
  }

  Future<void> _fetchConsumers([String searchQuery = '']) async {
    setState(() {
      isLoading = true; // Show loading
    });

    try {
      final data = await ApiService.fetchConsumers(1, 20, searchQuery);
      setState(() {
        consumers = data['consumers'];
        filteredConsumers = consumers;
        isLoading = false; // Hide loading after data is fetched
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load consumers: $e')),
      );
    }
  }

  Future<void> _fetchConsultants([String searchQuery = '']) async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await ApiService.fetchConsultants(1, 20, searchQuery);
      setState(() {
        consultants = data['Consultants'];
        filteredConsultants = consultants;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load consultants: $e')),
      );
    }
  }

  Future<void> _fetchFollowUpUsers([String searchQuery = '']) async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await ApiService.fetchUsers(1, 20, searchQuery);
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

  Future<void> _fetchFollowUpQuotations([String searchQuery = '']) async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await ApiService.fetchUsers(1, 20, searchQuery);
      setState(() {
        followUpQuotations = data['list'];
        filteredFollowUpQuotations = followUpQuotations;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load follow-up quotations: $e')),
      );
    }
  }

  Future<void> _saveInquiry() async {
    if (_formKey.currentState!.validate()) {
      if (createdById == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('User ID not found.')));
        return;
      }

      if (selectedConsumerId == null ||
          selectedConsultantId == null ||
          selectedFollowUpUserId == null ||
          selectedFollowUpQuotationId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select all required fields.')));
        return;
      }

      setState(() {
        isLoading = true;
      });

      try {
        var saveInquiry;
        if (isUpdate) {
          saveInquiry = ApiService.updateInquiry(
            inquiryId: widget.inquiryData!['inquiryId'],
            projectName: _projectNameController.text,
            inquiryStatus: _selectedInquiryStatus!,
            consumerId: selectedConsumerId!,
            productId: selectedProductId!,
            brandId: selectedBrandId!,
            consultantId: selectedConsultantId!,
            remark: _remarkController.text,
            updatedBy: createdById!,
            followUpUser: selectedFollowUpUserId!,
            followUpQuotation: selectedFollowUpQuotationId!,
            description: _descriptionController.text,
          );
        } else {
          saveInquiry = ApiService.saveInquiry(
            projectName: _projectNameController.text,
            inquiryStatus: _selectedInquiryStatus!,
            consumerId: selectedConsumerId!,
            productId: selectedProductId!,
            brandId: selectedBrandId!,
            consultantId: selectedConsultantId!,
            remark: _remarkController.text,
            createdAt: DateTime.now().toString(),
            createdBy: createdById!,
            followUpUser: selectedFollowUpUserId!,
            followUpQuotation: selectedFollowUpQuotationId!,
            description: _descriptionController.text,
          );
        }

        final response = await saveInquiry;

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(isUpdate
                  ? 'Inquiry updated successfully!'
                  : 'Inquiry created successfully!')));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Failed to save inquiry.')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isUpdate ? 'Update Inquiry' : 'Create Inquiry', // Corrected title
          style: const TextStyle(
            color: Colors.white, // Title color set to white
          ),
        ),
        backgroundColor: const Color(0xFF5A3EBA),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildTextField(
                      label: 'Project Name',
                      controller: _projectNameController,
                      hintText: 'Enter project name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter project name';
                        }
                        return null;
                      },
                    ),
                    // _buildInquiryTypeDropdown(),
                    _buildInquiryStatusDropdown(),
                    _buildConsumerSearchField(),
                    _buildBrandSearchField(),
                    _buildProductSearchField(),
                    _buildConsultantSearchField(),
                    _buildFollowUpUserSearchField(),
                    _buildFollowUpQuotationSearchField(),
                    _buildTextField(
                      label: 'Remark',
                      controller: _remarkController,
                      hintText: 'Enter remark',
                      validator: (value) {
                        return null; // Optional field
                      },
                    ),
                    _buildTextField(
                      label: 'Description',
                      controller: _descriptionController,
                      hintText: 'Enter description',
                      validator: (value) {
                        return null; // Optional field
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveInquiry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A3EBA),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isUpdate ? 'Update Inquiry' : 'Save Inquiry',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      // bottomNavigationBar: const NavBar(),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  // Widget _buildInquiryTypeDropdown() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 10),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           'Inquiry Type',
  //           style: TextStyle(
  //             fontSize: 16,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.black87,
  //           ),
  //         ),
  //         const SizedBox(height: 8),
  //         DropdownButtonFormField<String>(
  //           decoration: InputDecoration(
  //             border: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(10),
  //             ),
  //             contentPadding:
  //                 const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  //           ),
  //           value: _selectedInquiryType != '' ? _selectedInquiryType : null,
  //           hint: const Text('Select Inquiry Type'),
  //           items: _inquiryTypes.map((String type) {
  //             return DropdownMenuItem<String>(
  //               value: type,
  //               child: Text(type),
  //             );
  //           }).toList(),
  //           onChanged: (newValue) {
  //             setState(() {
  //               _selectedInquiryType = newValue;
  //             });
  //           },
  //           validator: (value) {
  //             if (value == null || value.isEmpty) {
  //               return 'Please select an inquiry type';
  //             }
  //             return null;
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildInquiryStatusDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inquiry Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            value: _selectedInquiryStatus != '' ? _selectedInquiryStatus : null,
            hint: const Text('Select Inquiry Status'),
            items: _inquiryStatuses.map((String status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedInquiryStatus = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select an inquiry status';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConsumerSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Consumer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: selectedConsumerId,
            hint: const Text('Search Consumer'),
            items: filteredConsumers.map((consumer) {
              return DropdownMenuItem<int>(
                value: consumer['consumerId'],
                child: Text(consumer['consumerName']),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedConsumerId = value;
                selectedConsumerName = filteredConsumers.firstWhere(
                    (consumer) =>
                        consumer['consumerId'] == value)['consumerName'];
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select a consumer';
              }
              return null;
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
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
            controller: TextEditingController(text: selectedBrandName),
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
                filteredBrands = brands
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
                  shrinkWrap: true,
                  itemCount: filteredBrands.length,
                  itemBuilder: (context, index) {
                    final brand = filteredBrands[index];
                    return ListTile(
                      title: Text(brand['brandName'] ?? 'N/A'),
                      onTap: () {
                        setState(() {
                          selectedBrandId = brand['brandId']; // Get brandId
                          selectedBrandName = brand['brandName'];
                          _showBrandOptions = false;
                        });
                        // Fetch products based on selected brandId
                        _fetchProductsByBrand(selectedBrandId!);
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

  Widget _buildProductSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Product',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: TextEditingController(text: selectedProductName),
            decoration: InputDecoration(
              hintText: 'Search Product',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: const Icon(Icons.search),
            ),
            onChanged: (String query) {
              setState(() {
                filteredProducts = products
                    .where((product) => product['productName']
                        .toLowerCase()
                        .contains(query.toLowerCase()))
                    .toList();
              });
            },
            onTap: () {
              setState(() {
                _showProductOptions = true;
              });
            },
          ),
          const SizedBox(height: 8),
          if (_showProductOptions)
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return ListTile(
                      title: Text(product['productName'] ?? 'N/A'),
                      onTap: () {
                        setState(() {
                          selectedProductId = product['productId'];
                          selectedProductName = product['productName'];
                          _showProductOptions = false;
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

  Widget _buildConsultantSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Consultant',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _consultantSearchController,
            decoration: InputDecoration(
              hintText: 'Search Consultant',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: const Icon(Icons.search),
            ),
            onChanged: (String query) {
              setState(() {
                filteredConsultants = consultants
                    .where((consultant) => consultant['consultantName']
                        .toLowerCase()
                        .contains(query.toLowerCase()))
                    .toList();
              });
            },
            onTap: () {
              setState(() {
                _showConsultantOptions = true;
              });
            },
          ),
          const SizedBox(height: 8),
          if (_showConsultantOptions)
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredConsultants.length,
                  itemBuilder: (context, index) {
                    final consultant = filteredConsultants[index];
                    return ListTile(
                      title: Text(consultant['consultantName'] ?? 'N/A'),
                      onTap: () {
                        setState(() {
                          selectedConsultantId = consultant['consultantId'];
                          selectedConsultantName = consultant['consultantName'];
                          _consultantSearchController.text =
                              consultant['consultantName'];
                          _showConsultantOptions = false;
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

  Widget _buildFollowUpUserSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Follow-Up User',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _followUpUserSearchController,
            decoration: InputDecoration(
              hintText: 'Search Follow-Up User',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: const Icon(Icons.search),
            ),
            onChanged: (String query) {
              setState(() {
                filteredFollowUpUsers = followUpUsers
                    .where((user) => user['name']
                        .toLowerCase()
                        .contains(query.toLowerCase()))
                    .toList();
                _addMyselfOnTopUser(); // Add "Myself" to the filtered list
              });
            },
            onTap: () {
              setState(() {
                _showFollowUpUserOptions = true;
                _addMyselfOnTopUser(); // Add "Myself" to the list when the field is tapped
              });
            },
          ),
          const SizedBox(height: 8),
          if (_showFollowUpUserOptions)
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredFollowUpUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredFollowUpUsers[index];
                    return ListTile(
                      title: Text(user['name'] ?? 'N/A'),
                      onTap: () async {
                        if (user['name'] == 'Myself') {
                          // Fetch the userId from SharedPreferences when "Myself" is selected
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          String? storedUserIdString = prefs
                              .getString('userId'); // Fetch userId as String

                          if (storedUserIdString != null) {
                            selectedFollowUpUserId =
                                int.parse(storedUserIdString); // Convert to int
                          } else {
                            selectedFollowUpUserId =
                                0; // Fallback ID if userId is not found
                          }
                          selectedFollowUpUserName =
                              'Myself'; // Set "Myself" as the selected name
                        } else {
                          selectedFollowUpUserId =
                              user['Id']; // Normal behavior for other users
                          selectedFollowUpUserName = user['name'];
                        }

                        setState(() {
                          _followUpUserSearchController.text = user['name'];
                          _showFollowUpUserOptions = false;
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

// Add the "Myself" option at the top of the list for Follow-Up Users
  void _addMyselfOnTopUser() {
    final myself = {'Id': 0, 'name': 'Myself'};

    filteredFollowUpUsers
        .removeWhere((user) => user['Id'] == 0); // Avoid duplicate "Myself"
    filteredFollowUpUsers.insert(0, myself);
  }

  Widget _buildFollowUpQuotationSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Follow-Up Quotation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _followUpQuotationSearchController,
            decoration: InputDecoration(
              hintText: 'Search Follow-Up Quotation',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: const Icon(Icons.search),
            ),
            onChanged: (String query) {
              setState(() {
                filteredFollowUpQuotations = followUpQuotations
                    .where((quotation) => quotation['name']
                        .toLowerCase()
                        .contains(query.toLowerCase()))
                    .toList();
                _addMyselfOnTop(); // Add "Myself" on top
              });
            },
            onTap: () {
              setState(() {
                _showFollowUpQuotationOptions = true;
                _addMyselfOnTop(); // Ensure "Myself" is shown when dropdown is tapped
              });
            },
          ),
          const SizedBox(height: 8),
          if (_showFollowUpQuotationOptions)
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredFollowUpQuotations.length,
                  itemBuilder: (context, index) {
                    final quotation = filteredFollowUpQuotations[index];
                    return ListTile(
                      title: Text(quotation['name'] ?? 'N/A'),
                      onTap: () async {
                        if (quotation['name'] == 'Myself') {
                          // Fetch the userId from SharedPreferences when "Myself" is selected
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          String? storedUserIdString = prefs
                              .getString('userId'); // Fetch userId as String

                          if (storedUserIdString != null) {
                            selectedFollowUpQuotationId = int.parse(
                                storedUserIdString); // Convert String to int
                          } else {
                            selectedFollowUpQuotationId =
                                0; // Fallback ID if not found
                          }
                          selectedFollowUpQuotationName =
                              'Myself'; // Set "Myself" as the selected name
                        } else {
                          selectedFollowUpQuotationId = quotation[
                              'Id']; // Normal behavior for other quotations
                          selectedFollowUpQuotationName = quotation['name'];
                        }

                        setState(() {
                          _followUpQuotationSearchController.text =
                              quotation['name'];
                          _showFollowUpQuotationOptions = false;
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

// Add the "Myself" option at the top of the list
  void _addMyselfOnTop() {
    final myself = {'Id': 0, 'name': 'Myself'};

    filteredFollowUpQuotations.removeWhere(
        (quotation) => quotation['Id'] == 0); // Avoid duplicate "Myself"
    filteredFollowUpQuotations.insert(0, myself);
  }

  // Add the rest of your widget builders for the dropdowns and search fields here...
}
