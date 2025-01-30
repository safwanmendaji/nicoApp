import 'package:flutter/material.dart';
import 'package:nicoapp/services/api_services.dart';
import 'package:nicoapp/pages/navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateRolePage extends StatefulWidget {
  final int? roleId;
  final VoidCallback? onSaveSuccess; // Callback to reload roles list

  const CreateRolePage({super.key, this.roleId, this.onSaveSuccess});

  @override
  _CreateRolePageState createState() => _CreateRolePageState();
}

class _CreateRolePageState extends State<CreateRolePage> {
  final TextEditingController _roleNameController = TextEditingController();
  bool isLoading = false;
  bool isUpdate = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.roleId != null) {
      isUpdate = true;
      _fetchRoleData();
    }
  }

  // Fetch role data by ID
  Future<void> _fetchRoleData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final roleData = await ApiService.fetchRoleById(widget.roleId!);
      if (roleData != null) {
        _roleNameController.text = roleData['name'] ?? '';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching role: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Save or update the role
  Future<void> _saveOrUpdateRole() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        final roleName = _roleNameController.text.trim();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString('userId');

        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User ID not found. Please log in.')),
          );
          return;
        }

        if (isUpdate) {
          final response = await ApiService.updateRole(
            roleId: widget.roleId!,
            roleName: roleName,
            updatedBy: int.parse(userId),
          );

          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Role updated successfully!')),
            );
            _fetchRoleData();
            widget.onSaveSuccess?.call(); // Call the callback to refresh roles
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Failed to update role: ${response.body}')),
            );
          }
        } else {
          final response = await ApiService.saveRole(roleName: roleName);

          if (response.statusCode == 200 || response.statusCode == 201) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Role created successfully!')),
            );
            widget.onSaveSuccess?.call(); // Call the callback to refresh roles
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to create role')),
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
          isUpdate ? 'Update Role' : 'Create Role',
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
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      isUpdate ? 'Update Role' : 'Create Role',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Role Name',
                      controller: _roleNameController,
                      hintText: 'Enter role name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a role name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveOrUpdateRole,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A3EBA),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isUpdate ? 'Update Role' : 'Save Role',
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
}
