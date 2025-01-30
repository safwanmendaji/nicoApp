import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nicoapp/pages/navbar.dart';
import 'package:nicoapp/pages/create_list_page.dart';
import 'package:nicoapp/services/api_services.dart';

class CreateConsumerPage extends StatefulWidget {
  final Map<String, dynamic>? consumer; // Optional consumer object for updating

  const CreateConsumerPage({super.key, this.consumer});

  @override
  _CreateConsumerPageState createState() => _CreateConsumerPageState();
}

class _CreateConsumerPageState extends State<CreateConsumerPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  bool isUpdate = false; // Track if this is an update operation

  @override
  void initState() {
    super.initState();
    if (widget.consumer != null) {
      isUpdate = true; // If a consumer object is passed, this is an update
      _populateFields(); // Populate fields with existing data
    }
  }

  // Populate fields with the consumer data for updating
  void _populateFields() {
    _nameController.text = widget.consumer!['consumerName'] ?? '';
    _emailController.text = widget.consumer!['emailId'] ?? '';
    _addressController.text = widget.consumer!['address'] ?? '';
    _contactController.text = widget.consumer!['contact'] ?? '';
  }

  // Method to create or update consumer using ApiService
  Future<void> _saveConsumer() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId =
          prefs.getString('userId'); // Fetch userId from SharedPreferences

      if (userId != null) {
        if (isUpdate) {
          // If updating consumer
          final response = await ApiService.updateConsumer(
            consumerId: widget.consumer!['consumerId'],
            consumerName: _nameController.text,
            emailId: _emailController.text,
            address: _addressController.text,
            contact: _contactController.text,
            updatedBy: int.parse(userId),
          );

          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Consumer updated successfully!')),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Failed to update consumer: ${response.body}')),
            );
          }
        } else {
          // If creating new consumer
          final response = await ApiService.createConsumer(
            consumerName: _nameController.text,
            emailId: _emailController.text,
            address: _addressController.text,
            contact: _contactController.text,
            createdBy: int.parse(userId),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Consumer created successfully!')),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Failed to create consumer: ${response.body}')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not found in local storage')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isUpdate ? 'Update Consumer' : 'Create Consumer', // Corrected title
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
          key: _formKey, // Attach the form key
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.purple.shade100,
                child: const Icon(
                  Icons.people,
                  size: 50,
                  color: Color(0xFF5A3EBA),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isUpdate ? 'Update Consumer' : 'Create Consumer',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Customer Name*',
                hintText: 'Enter Customer name',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              _buildTextField(
                label: 'Email*',
                hintText: 'Enter Email',
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              _buildTextField(
                label: 'Address*',
                hintText: 'Enter Address',
                controller: _addressController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              _buildTextField(
                label: 'Mobile Number*',
                hintText: 'Enter Mobile number',
                controller: _contactController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter mobile number';
                  }
                  if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                    return 'Please enter a valid 10-digit mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveConsumer, // Call API on button press
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A3EBA),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isUpdate ? 'Update Consumer' : 'Create Consumer',
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
    required String hintText,
    required TextEditingController controller,
    required String? Function(String?)? validator, // Add validator
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
            validator: validator, // Attach validator
          ),
        ],
      ),
    );
  }
}
