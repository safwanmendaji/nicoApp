import 'package:flutter/material.dart';
import 'package:nicoapp/pages/navbar.dart';
import 'package:nicoapp/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateBrandPage extends StatefulWidget {
  final Map<String, dynamic>? brand; // Optional brand object for updating

  const CreateBrandPage({super.key, this.brand});

  @override
  _CreateBrandPageState createState() => _CreateBrandPageState();
}

class _CreateBrandPageState extends State<CreateBrandPage> {
  final TextEditingController _brandNameController = TextEditingController();
  bool isLoading = false;
  bool isUpdate = false; // Flag to determine if it's an update

  final _formKey = GlobalKey<FormState>(); // Form key for validation

  @override
  void initState() {
    super.initState();

    // Check if brand object is passed, if yes, this is an update
    if (widget.brand != null) {
      isUpdate = true;
      _brandNameController.text = widget.brand!['brandName'] ?? '';
    }
  }

  Future<void> _saveOrUpdateBrand() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        final brandName = _brandNameController.text.trim();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString('userId');

        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User ID not found. Please log in.')),
          );
          return;
        }

        if (isUpdate) {
          // Call the update API if it's an update
          final response = await ApiService.updateBrand(
            brandId: widget.brand!['brandId'],
            brandName: brandName,
            updatedBy: int.parse(userId),
          );

          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Brand updated successfully!')),
            );
            Navigator.pop(context); // Go back after successful update
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Failed to update brand: ${response.body}')),
            );
          }
        } else {
          // Call the save API if it's a new brand
          final response = await ApiService.saveBrand(brandName);

          if (response['statusCode'] == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Brand saved successfully!')),
            );
            Navigator.pop(context); // Go back after successful save
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Failed to save brand: ${response['message']}')),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
          isUpdate ? 'Update Brand' : 'Create Brand',
          style: const TextStyle(
            color: Colors.white, // Title color set to white
          ),
        ),
        backgroundColor: const Color(0xFF5A3EBA),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey, // Assign the form key
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.purple.shade100,
                      child: const Icon(
                        Icons.branding_watermark,
                        size: 50,
                        color: Color(0xFF5A3EBA),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isUpdate ? 'Update Brand' : 'Create Brand',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Text color set to white
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Brand Name',
                      controller: _brandNameController,
                      hintText: 'Enter brand name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a brand name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveOrUpdateBrand,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A3EBA),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isUpdate ? 'Update Brand' : 'Save Brand',
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
            validator: validator, // Attach the validator here
          ),
        ],
      ),
    );
  }
}
