import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nicoapp/pages/create_user_page.dart';
import 'package:nicoapp/pages/navbar.dart';
import 'package:nicoapp/pages/create_consultant_page.dart';
import 'package:nicoapp/pages/create_inquiry_page.dart';
import 'package:nicoapp/pages/create_consumer_page.dart';
import 'package:nicoapp/pages/create_general_followUp_page.dart';
import 'package:nicoapp/pages/create_product_page.dart'; // Import your CreateProductPage
import 'package:nicoapp/pages/create_brand_page.dart'; // Import your CreateBrandPage
import 'package:nicoapp/pages/header_page.dart'; // Import your HeaderPage
import 'package:nicoapp/pages/create_role_page.dart';

import '../Model/general_followUp.dart';

class CreateListPage extends StatefulWidget {
  const CreateListPage({super.key});

  @override
  _CreateListPageState createState() => _CreateListPageState();
}

class _CreateListPageState extends State<CreateListPage> {
  String? userRole; // To store user role
  int? generalFollowUpId; // To store the follow-up ID if present

  @override
  void initState() {
    super.initState();
    _loadUserRole(); // Load the role on page load
    _loadGeneralFollowUpId(); // Load follow-up ID if present
  }

  // Function to load the role from SharedPreferences
  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('role');
    });
  }

  // Function to load the generalFollowUpId if it exists in SharedPreferences
  Future<void> _loadGeneralFollowUpId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      generalFollowUpId = prefs
          .getInt('generalFollowUpId'); // Load from SharedPreferences if set
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderPage(
          pageTitle: 'Create List'), // Use HeaderPage with dynamic title
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Conditionally show Create User Button if role is ADMIN
              if (userRole == 'ADMIN')
                _buildCreateButton(
                  context,
                  icon: Icons.person_add_alt_1,
                  label: 'Create User',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CreateUserPage()),
                    );
                  },
                ),
              const SizedBox(height: 10), // Space between buttons

              // Create Consultant Button
              _buildCreateButton(
                context,
                icon: Icons.person,
                label: 'Create Consultant',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreateConsultantPage(
                              consultant: null,
                            )),
                  );
                },
              ),
              const SizedBox(height: 10), // Space between buttons

              // Create Inquiry Button
              _buildCreateButton(
                context,
                icon: Icons.inbox,
                label: 'Create Inquiry',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreateInquiryPage(
                              inquiryData: null,
                            )),
                  );
                },
              ),
              const SizedBox(height: 10), // Space between buttons

              // Create Consumer Button
              _buildCreateButton(
                context,
                icon: Icons.people,
                label: 'Create Consumer',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreateConsumerPage(
                              consumer: null,
                            )),
                  );
                },
              ),
              const SizedBox(height: 10), // Space between buttons

              // Create General Follow-Up Button with conditional check for follow-up ID
              _buildCreateButton(
                context,
                icon: Icons.assignment_turned_in,
                label: 'Create FollowUp',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateGeneralFollowUpPage(
                        followUp: generalFollowUpId != null
                            ? GeneralFollowUp(
                                generalFollowUpId: generalFollowUpId!,
                                generalFollowUpName: 'Some follow-up',
                                description: '',
                                status: '',
                                statusNotes: '',
                                dueDate: '',
                                followUpPerson: FollowUpPerson(
                                  id: 0,
                                  name: 'Unknown',
                                  email: '',
                                  designation: '',
                                  mobileNo: '',
                                ),
                                createdBy: CreatedBy(
                                  id: 0,
                                  name: 'Unknown',
                                  email: '',
                                  designation: '',
                                  mobileNo: '',
                                ),

                                updatedBy: UpdatedBy(
                                  id: 0,
                                  name: 'Unknown',
                                  email: '',
                                  designation: '',
                                  mobileNo: '',
                                ), // Provide a default FollowUpPerson object
                              )
                            : GeneralFollowUp(
                                generalFollowUpId: 0,
                                generalFollowUpName: '',
                                description: '',
                                status: '',
                                statusNotes: '',
                                dueDate: '',
                                followUpPerson: FollowUpPerson(
                                  id: 0,
                                  name: 'Unknown',
                                  email: '',
                                  designation: '',
                                  mobileNo: '',
                                ),
                                createdBy: CreatedBy(
                                  id: 0,
                                  name: 'Unknown',
                                  email: '',
                                  designation: '',
                                  mobileNo: '',
                                ),
                                updatedBy: UpdatedBy(
                                  id: 0,
                                  name: 'Unknown',
                                  email: '',
                                  designation: '',
                                  mobileNo: '',
                                ),
                              ), // Provide an empty GeneralFollowUp object if generalFollowUpId is null
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Create Product Button
              _buildCreateButton(
                context,
                icon: Icons.production_quantity_limits,
                label: 'Create Product',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CreateProductPage(
                              productData: null,
                            )),
                  );
                },
              ),
              const SizedBox(height: 10), // Space between buttons

              // Create Brand Button
              _buildCreateButton(
                context,
                icon: Icons.branding_watermark,
                label: 'Create Brand',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreateBrandPage(
                              brand: null,
                            )),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Conditionally show Create Role Button if role is ADMIN
              if (userRole == 'ADMIN')
                _buildCreateButton(
                  context,
                  icon: Icons.security,
                  label: 'Create Role',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CreateRolePage()),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const NavBar(
        initialIndex: 2,
      ),
    );
  }

  // Helper method to build the button widget according to the design
  // Helper method to build the button widget according to the design
  Widget _buildCreateButton(BuildContext context,
      {required IconData icon,
      required String label,
      required Function onTap}) {
    return InkWell(
      onTap: () => onTap(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: const Color(0xFF5A3EBA)),
            const SizedBox(width: 20), // Spacing between icon and text
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(
                    106, 11, 195, 1), // Change the font color here
              ),
            ),
          ],
        ),
      ),
    );
  }
}
