import 'package:flutter/material.dart';
import 'package:nicoapp/pages/analytics_page.dart';
import 'package:nicoapp/pages/loginPage.dart'; // Import your LoginPage
import 'package:nicoapp/pages/create_list_page.dart'; // Import the CreateListPage
import 'package:nicoapp/pages/main_list_page.dart'; // Import the ListsPage
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nicoapp/pages/dashboard.dart'; // Import Dashboard

class NavBar extends StatefulWidget {
  final int initialIndex; // Add an index parameter

  const NavBar({Key? key, required this.initialIndex})
      : super(key: key); // Make initialIndex required

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    // Set the initial selected index from the parameter
    _selectedIndex = widget.initialIndex;
  }

  // Function to handle Logout
  Future<void> _logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('userId');

    // Navigate back to LoginPage and clear the navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  // Function to handle item taps
  void _onItemTapped(int index) {
    if (index == 4) {
      _showLogoutConfirmationDialog();
      return;
    }

    setState(() {
      // Fallback to 0 if an invalid index is passed
      _selectedIndex = index < 0 || index > 4 ? 0 : index;
    });

    // Navigate to the corresponding page based on the selected index
    if (_selectedIndex == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    } else if (_selectedIndex == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AnalyticsPage()),
      );
    } else if (_selectedIndex == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CreateListPage()),
      );
    } else if (_selectedIndex == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainListPage()),
      );
    }
  }

  // Function to show logout confirmation dialog
  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.logout,
                  color: Color.fromARGB(255, 106, 11, 195),
                  size: 48.0,
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'Are you sure you want to logout?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 24.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'No',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        _logout(); // Call the logout function
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 106, 11, 195),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 24.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Yes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      iconSize: 24.0,
      selectedFontSize: 12,
      unselectedFontSize: 10,
      selectedItemColor: const Color.fromARGB(
          255, 106, 11, 195), // Highlighted color for selected item
      unselectedItemColor: Colors.grey, // Color for unselected items
      items: const [
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/images/home.png')),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/images/Graph.png')),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/images/create.png')),
          label: 'Create',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/images/list.png')),
          label: 'Lists',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage('assets/images/logout.png')),
          label: 'Logout',
        ),
      ],
      type: BottomNavigationBarType.fixed,
      onTap: _onItemTapped,
    );
  }
}
