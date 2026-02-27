import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirebaseDebugHelper {
  static Future<void> checkFirebaseSetup(BuildContext context) async {
    try {
      // Check Firebase initialization
      final FirebaseApp app = Firebase.app();
      
      print('Firebase initialized successfully.');
      print('Firebase App Name: ${app.name}');
      print('Firebase Options:');
      print('- API Key: ${app.options.apiKey}');
      print('- Project ID: ${app.options.projectId}');
      print('- Messaging Sender ID: ${app.options.messagingSenderId}');
      print('- App ID: ${app.options.appId}');
      
      // Check if Firebase Auth is accessible
      final auth = FirebaseAuth.instance;
      print('FirebaseAuth initialized: ${auth != null}');
      
      // Try a simple Firebase Auth operation
      final authMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail('test@example.com');
      print('Auth test successful. Sign-in methods for test email: $authMethods');
      
      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase connection successful. Check console for details.'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseException catch (e) {
      print('Firebase initialization error: ${e.code} - ${e.message}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print('Unexpected error checking Firebase: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking Firebase: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}