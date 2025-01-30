import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nicoapp/Model/User.dart';
import 'package:nicoapp/Model/general_followUp.dart';
import 'package:nicoapp/services/api_services.dart';
import 'package:nicoapp/pages/navbar.dart';
import 'package:nicoapp/pages/create_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateGeneralFollowUpPage extends StatefulWidget {
  final GeneralFollowUp? followUp;

  const CreateGeneralFollowUpPage({super.key, this.followUp});

  @override
  _CreateGeneralFollowUpPageState createState() =>
      _CreateGeneralFollowUpPageState();
}

class _CreateGeneralFollowUpPageState extends State<CreateGeneralFollowUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _statusNotesController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _followUpPersonSearchController =
      TextEditingController();

  String? selectedStatus;
  int? selectedUserId; // Holds the ID of the selected user
  bool isLoading = false;
  bool isUpdate = false;
  bool _showFollowUpPersonOptions = false;
  List<User> followUpPersonList = [];
  List<User> filteredFollowUpPersons = [];

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.followUp != null && widget.followUp!.generalFollowUpId != 0) {
      isUpdate = true;
      _setFollowUpDetails(); // Populate data for update
    }
    _fetchFollowUpPersons(); // Fetch list of users for follow-up
  }

  void _setFollowUpDetails() {
    if (widget.followUp != null) {
      _nameController.text = widget.followUp!.generalFollowUpName ?? '';
      _descriptionController.text = widget.followUp!.description ?? '';
      _statusNotesController.text = widget.followUp!.statusNotes ?? '';

      if (widget.followUp!.dueDate != null) {
        DateTime parsedDate = DateTime.parse(widget.followUp!.dueDate!);
        _dueDateController.text =
            DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(parsedDate);
      }

      selectedStatus = widget.followUp!.status;

      if (widget.followUp!.followUpPerson != null) {
        selectedUserId = widget.followUp!.followUpPerson!.id;
        _followUpPersonSearchController.text =
            widget.followUp!.followUpPerson!.name ?? '';
      }
    }
  }

  Future<void> _fetchFollowUpPersons() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await ApiService.fetchUsers(1, 10, '');

      if (data != null && data['list'] != null) {
        final users = (data['list'] as List)
            .map((userJson) => User.fromJson(userJson))
            .toList();

        setState(() {
          followUpPersonList = users;
          filteredFollowUpPersons = followUpPersonList;
          _addMyselfOnTop();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No users found.')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching users: $e')));
    }
  }

  Future<void> _saveGeneralFollowUp() async {
    if (_formKey.currentState!.validate()) {
      if (selectedUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a follow-up person.')),
        );
        return;
      }

      setState(() {
        isLoading = true;
      });

      try {
        if (isUpdate) {
          await ApiService.updateGeneralFollowUp(
            widget.followUp!.generalFollowUpId,
            _nameController.text,
            selectedUserId!,
            _descriptionController.text,
            selectedStatus!,
            _statusNotesController.text,
            _dueDateController.text,
          );
        } else {
          await ApiService.saveGeneralFollowUp(
            _nameController.text,
            selectedUserId!,
            _descriptionController.text,
            selectedStatus!,
            _statusNotesController.text,
            _dueDateController.text,
          );
        }

        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('General Follow-Up saved successfully!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CreateListPage()),
        );
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isUpdate ? 'Update Follow-Up' : 'Create Follow-Up', // Corrected title
          style: const TextStyle(
            color: Colors.white, // Title color set to white
          ),
        ),
        backgroundColor: const Color(0xFF5A3EBA),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      label: 'Task Name',
                      controller: _nameController,
                      hintText: 'Enter follow-up name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a follow-up name';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      label: 'Description',
                      controller: _descriptionController,
                      hintText: 'Enter description',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    _buildStatusDropdown(),
                    _buildFollowUpPersonSearchField(),
                    _buildDueDateField(),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveGeneralFollowUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A3EBA),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isUpdate
                              ? 'Update Follow-Up'
                              : 'Save Follow-Up', // Corrected title
                          style: const TextStyle(
                            color: Colors.white, // Title color set to white
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
    required String? Function(String?)? validator,
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
            decoration: InputDecoration(
              hintText: hintText,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpPersonSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Follow-Up Person',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _followUpPersonSearchController,
            decoration: InputDecoration(
              hintText: 'Search Follow-Up Person',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _followUpPersonSearchController.clear();
                  setState(() {
                    filteredFollowUpPersons = followUpPersonList;
                    _addMyselfOnTop();
                  });
                },
              ),
            ),
            onChanged: (String query) {
              setState(() {
                filteredFollowUpPersons = followUpPersonList
                    .where((person) =>
                        person.name.toLowerCase().contains(query.toLowerCase()))
                    .toList();
                _addMyselfOnTop();
              });
            },
            onTap: () {
              setState(() {
                _showFollowUpPersonOptions = true;
                _addMyselfOnTop();
              });
            },
          ),
          const SizedBox(height: 8),
          if (_showFollowUpPersonOptions && filteredFollowUpPersons.isNotEmpty)
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Scrollbar(
                child: ListView.builder(
                  itemCount: filteredFollowUpPersons.length,
                  itemBuilder: (context, index) {
                    final person = filteredFollowUpPersons[index];
                    return ListTile(
                      title: Text(person.name),
                      onTap: () async {
                        if (person.name == 'Myself') {
                          // Fetch the userId from SharedPreferences when "Myself" is selected
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          String? storedUserIdString = prefs
                              .getString('userId'); // Fetch userId as String

                          if (storedUserIdString != null) {
                            selectedUserId = int.parse(
                                storedUserIdString); // Parse the String to an int
                          } else {
                            selectedUserId = 0; // Fallback ID
                          }
                        } else {
                          selectedUserId =
                              person.id; // Set selectedUserId for other users
                        }

                        setState(() {
                          _followUpPersonSearchController.text = person.name;
                          _showFollowUpPersonOptions = false;
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          if (_showFollowUpPersonOptions && filteredFollowUpPersons.isEmpty)
            const Text(
              'No follow-up persons found',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }

  void _addMyselfOnTop() {
    final myself = User(
      id: 0,
      name: 'Myself',
      phone: '',
      email: '',
      department: '',
    );

    filteredFollowUpPersons.removeWhere((person) => person.id == 0);
    filteredFollowUpPersons.insert(0, myself);
  }

  Widget _buildStatusDropdown() {
    List<String> statusOptions = ['PENDING', 'ONGOING', 'MODIFY'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedStatus,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            hint: const Text('Select status'),
            items: statusOptions.map((String status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedStatus = newValue;
              });
            },
            validator: (value) =>
                value == null ? 'Please select a status' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Due Date & Time',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _dueDateController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: 'YYYY-MM-DD HH:mm',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () {
                  _selectDueDate(context);
                },
              ),
            ),
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter a due date and time'
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _dueDateController.text =
              DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(finalDateTime);
        });
      }
    }
  }
}

extension StringDescription on String {
  String get description => this.isEmpty ? 'No Description Available' : this;
}
