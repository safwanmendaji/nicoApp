import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for input formatters
import 'package:nicoapp/services/api_services.dart'; // Import your ApiService

class CreateUserPage extends StatefulWidget {
  final int? userId;

  const CreateUserPage({Key? key, this.userId}) : super(key: key);

  @override
  _CreateUserPageState createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _mobileNoController = TextEditingController();

  int? selectedRoleId; // Store the selected role ID as an integer
  String? selectedRoleName; // Store the selected role name
  List<dynamic> roles = [];
  bool isLoading = true;

  final _formKey = GlobalKey<FormState>(); // Form key for validation

  @override
  void initState() {
    super.initState();
    _fetchRoles();
    if (widget.userId != null && widget.userId! > 0) {
      _fetchUserDetails(widget.userId!); // Fetch user details for editing
    }
  }

  // Fetch roles from the API
  Future<void> _fetchRoles({String searchQuery = ""}) async {
    try {
      final fetchedRoles = await ApiService.fetchRoles(
        page: 1,
        size: 10,
        searchQuery: searchQuery,
      );

      setState(() {
        roles = fetchedRoles['roles'] ?? [];
        isLoading = false;

        if (widget.userId != null && widget.userId! > 0) {
          _fetchUserDetails(widget.userId!);
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load roles: $e')),
      );
    }
  }

  // Fetch user details for editing
  Future<void> _fetchUserDetails(int userId) async {
    try {
      final user = await ApiService.fetchUserById(userId);
      if (user != null) {
        _nameController.text = user['name']?.trim() ?? '';
        _emailController.text =
            user['email']?.replaceFirst('mailto:', '') ?? '';
        _designationController.text = user['designation'] ?? '';
        _mobileNoController.text = user['mobileNo'] ?? '';

        // Set the selected role ID and role name based on the user's current role
        setState(() {
          selectedRoleId = user['role']?['id'];
          selectedRoleName = user['role']?['roleName']; // Store role name
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch user details: $e')),
      );
    }
  }

  // Add or update user
  Future<void> _addUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (selectedRoleId != null) {
          // Check if we are updating a user
          if (widget.userId != null && widget.userId! > 0) {
            // If updating, don't include password in the request
            final response = await ApiService.updateUser(
              userId: widget.userId!,
              name: _nameController.text,
              email: _emailController.text,
              designation: _designationController.text,
              mobileNo: _mobileNoController.text,
              roleId: selectedRoleId!,
            );

            if (response.statusCode == 200 || response.statusCode == 201) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User updated successfully!')),
              );
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to update user')),
              );
            }
          } else {
            // If creating a new user, send the password
            final response = await ApiService.addUser(
              name: _nameController.text,
              email: _emailController.text,
              password:
                  _passwordController.text, // Password included for new user
              designation: _designationController.text,
              mobileNo: _mobileNoController.text,
              roleId: selectedRoleId!,
            );

            if (response.statusCode == 200 || response.statusCode == 201) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User created successfully!')),
              );
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to create user')),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a valid role')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate = widget.userId != null && widget.userId! > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isUpdate ? 'Update User' : 'Create User'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      isUpdate ? 'Update User' : 'Create User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Name',
                      controller: _nameController,
                      hintText: 'Enter name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      label: 'Email',
                      controller: _emailController,
                      hintText: 'Enter email',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email';
                        }
                        return null;
                      },
                    ),
                    // Password field only for new user creation
                    if (!isUpdate)
                      _buildTextField(
                        label: 'Password',
                        controller: _passwordController,
                        hintText: 'Enter password',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          return null;
                        },
                        obscureText: true,
                      ),
                    _buildTextField(
                      label: 'Designation',
                      controller: _designationController,
                      hintText: 'Enter designation',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a designation';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      label: 'Mobile No',
                      controller: _mobileNoController,
                      hintText: 'Enter mobile number',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a mobile number';
                        } else if (value.length != 10) {
                          return 'Please enter exactly 10 digits';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(10),
                        FilteringTextInputFormatter.digitsOnly,
                      ], // Limit to 10 digits and allow only digits
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      value: selectedRoleId,
                      hint: Text(selectedRoleName ?? 'Select Role'),
                      onChanged: (newValue) {
                        setState(() {
                          selectedRoleId = newValue;
                          selectedRoleName = roles.firstWhere(
                              (role) => role['Id'] == newValue)['name'];
                        });
                      },
                      items: roles
                          .map((role) => DropdownMenuItem<int>(
                                value: role['Id'],
                                child: Text(role['name']),
                              ))
                          .toList(),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a role';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A3EBA),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isUpdate ? 'Update User' : 'Save User',
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
    );
  }

  // Helper method to create TextFormField
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
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
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: validator,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
          ),
        ],
      ),
    );
  }
}
