import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'navigation.dart';

class StartingPage extends StatefulWidget {
  @override
  _StartingPageState createState() => _StartingPageState();
}

class _StartingPageState extends State<StartingPage> {
  @override
  void initState() {
    super.initState();
    // Check if user is already logged in
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    // Add a short delay to ensure the widget is mounted
    await Future.delayed(Duration.zero);
    
    // Check if the context is still mounted before proceeding
    if (!mounted) return;
    
    // Check if user is already logged in
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is already logged in, navigate to NavigationScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => NavigationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.search, size: 100, color: const Color(0xFF8cb0df)),
            SizedBox(height: 20),
            Text(
              'ProJobTracker',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8cb0df),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Your job searching companion',
              style: TextStyle(
                fontSize: 18,
                color: const Color(0xFF34444C),
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login'); // Navigate to login page
              },
              child: Text('Start'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8CB0DF),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}