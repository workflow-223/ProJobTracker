import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart';
import 'charts_screen.dart';
import 'calendar_page.dart';

class NavigationScreen extends StatefulWidget {
  @override
  _NavigationScreenState createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    ChartsScreen(),
    CalendarPage(allJobs: []),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer after selection
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login'); // Navigate to login screen
    } catch (e) {
      // Show error message if logout fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user information
    User? user = FirebaseAuth.instance.currentUser;
    String userEmail = user?.email ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: Text('Pro Job Tracker'),
        backgroundColor: const Color(0xFF8CB0DF),
      ),
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF8CB0DF),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Navigation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    userEmail,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: Icon(Icons.dashboard),
                    title: Text('Dashboard'),
                    onTap: () => _onItemTapped(0),
                  ),
                  ListTile(
                    leading: Icon(Icons.bar_chart),
                    title: Text('Charts'),
                    onTap: () => _onItemTapped(1),
                  ),
                  ListTile(
                    leading: Icon(Icons.calendar_today),
                    title: Text('Calendar'),
                    onTap: () => _onItemTapped(2),
                  ),
                ],
              ),
            ),
            Divider(), // Visual separation
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: _logout,
                child: Text('Log Out', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}