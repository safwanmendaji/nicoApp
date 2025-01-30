import 'package:flutter/material.dart';
import 'package:nicoapp/pages/navbar.dart';
import 'package:nicoapp/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateConsultantPage extends StatefulWidget {
  final Map<String, dynamic>?
      consultant; // Optional consultant object for updating

  const CreateConsultantPage({super.key, this.consultant});

  @override
  _CreateConsultantPageState createState() => _CreateConsultantPageState();
}

class _CreateConsultantPageState extends State<CreateConsultantPage> {
  // Controllers for form fields
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();

  final _formKey = GlobalKey<FormState>(); // Key for the form

  bool isUpdate = false; // Flag to determine if it's an update or create

  @override
  void initState() {
    super.initState();

    // If consultant data is passed, this is an update, so pre-populate the fields
    if (widget.consultant != null) {
      isUpdate = true;
      _companyNameController.text = widget.consultant!['consultantName'] ?? '';
      _contactPersonController.text = widget.consultant!['contactPerson'] ?? '';
      _contactInfoController.text = widget.consultant!['contactNumber'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isUpdate ? 'Update Consultant' : 'Create Consultant',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon at the top
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.purple.shade100,
                child: const Icon(
                  Icons.headset_mic,
                  size: 50,
                  color: Color(0xFF5A3EBA),
                ),
              ),
              const SizedBox(height: 20),

              // Page title
              Text(
                isUpdate ? 'Update Consultant' : 'Create Consultant',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Company Name Input Field
              _buildTextField(
                label: 'Company Name',
                controller: _companyNameController,
                hintText: 'Enter Company name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the company name';
                  }
                  return null;
                },
              ),

              // Contact Person Name Input Field
              _buildTextField(
                label: 'Contact Person Name',
                controller: _contactPersonController,
                hintText: 'Enter Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the contact person\'s name';
                  }
                  return null;
                },
              ),

              // Contact Info Input Field (Phone Number)
              _buildTextField(
                label: 'Contact Info',
                controller: _contactInfoController,
                hintText: 'Enter phone number',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the contact information';
                  } else if (value.length != 10 ||
                      !RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'Phone number must be exactly 10 digits';
                  }
                  return null;
                },
                maxLength: 10, // Set maxLength to 10 digits
              ),

              // Save or Update Consultant button
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (isUpdate) {
                        _updateConsultant();
                      } else {
                        _createConsultant();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A3EBA),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isUpdate ? 'Update Consultant' : 'Add Consultant',
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

  // Helper method to create text fields with consistent design and validation
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?)? validator,
    int? maxLength,
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
            maxLength: maxLength, // Limit the length of input if provided
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

  // Method to create consultant using API call
  Future<void> _createConsultant() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // API call to create consultant
      final response = await ApiService.createConsultant(
        consultantName: _companyNameController.text,
        contactPerson: _contactPersonController.text,
        contactNumber: _contactInfoController.text,
        createdBy: int.parse(userId),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultant created successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create consultant')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Method to update consultant using API call
  Future<void> _updateConsultant() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId =
          prefs.getString('userId'); // Retrieve user ID from storage

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // API call to update consultant
      final response = await ApiService.updateConsultant(
        consultantId: widget.consultant!['consultantId'],
        consultantName: _companyNameController.text,
        contactPerson: _contactPersonController.text,
        contactNumber: _contactInfoController.text,
        updatedBy: int.parse(userId),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultant updated successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update consultant')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
