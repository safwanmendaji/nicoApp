import 'package:flutter/material.dart';
import 'package:nicoapp/pages/consultant_list_page.dart';
import 'package:nicoapp/pages/navbar.dart';
import 'package:nicoapp/pages/inquiry_List_page.dart';
import 'package:nicoapp/pages/product_list.dart';
import 'package:nicoapp/pages/role_list_page.dart';
import 'package:nicoapp/pages/user_list_page.dart';
import 'package:nicoapp/pages/consumer_list_page.dart';
import 'package:nicoapp/pages/generalFollowUp_list_page.dart';
import 'package:nicoapp/pages/brand_list_page.dart'; // Import BrandListPage
import 'package:nicoapp/pages/header_page.dart'; // Import HeaderPage
import 'package:shared_preferences/shared_preferences.dart';

class MainListPage extends StatefulWidget {
  const MainListPage({super.key});

  @override
  _MainListPageState createState() => _MainListPageState();
}

class _MainListPageState extends State<MainListPage> {
  String? userRole;

  @override
  void initState() {
    super.initState();
    loadUserRole();
  }

  Future<void> loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('role'); // Fetch the user role
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderPage(
          pageTitle: 'List'), // Use HeaderPage with a dynamic title
      body: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16.0, vertical: 20.0), // Consistent padding
        child: ListView(
          children: <Widget>[
            // Conditionally show the User List only if the user role is ADMIN
            if (userRole == 'ADMIN')
              buildListItem(
                  context, 'Users List', const UserListPage(), Icons.people),
            buildListItem(context, 'Consultant List',
                const ConsultantListPage(), Icons.person_outline),
            buildListItem(
                context,
                'Inquiry List',
                InquiryListPage(
                  inquiryStatus: '',
                ),
                Icons.inbox_outlined),
            buildListItem(context, 'Consumer List', const ConsumerListPage(),
                Icons.shopping_cart_outlined),
            buildListItem(
                context,
                'General Follow-Up',
                const GeneralFollowUpListPage(),
                Icons.follow_the_signs_outlined),
            buildListItem(context, 'Brand List', const BrandListPage(),
                Icons.branding_watermark),
            buildListItem(context, 'Product List', const ProductListPage(),
                Icons.production_quantity_limits),
            // Conditionally show the Role List only if the user role is ADMIN
            if (userRole == 'ADMIN')
              buildListItem(
                  context, 'Role List', const RoleListPage(), Icons.security),
          ],
        ),
      ),
      bottomNavigationBar: const NavBar(
        initialIndex: 3,
      ), // Use the NavBar widget
    );
  }

  Widget buildListItem(BuildContext context, String title,
      Widget destinationPage, IconData icon) {
    return Card(
      elevation: 4, // Subtle elevation for a clean look
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Smooth corners
      ),
      margin: const EdgeInsets.symmetric(
          vertical: 10.0), // Proper spacing between cards
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.shade100,
          radius: 25,
          child: Icon(
            icon,
            color: Colors.deepPurple,
            size: 28,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color:
                Colors.deepPurple.shade700, // More subtle purple color for text
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.deepPurple.shade700,
          size: 18,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destinationPage),
          );
        },
      ),
    );
  }
}
