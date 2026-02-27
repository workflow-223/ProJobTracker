import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // Create singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['https://www.googleapis.com/auth/calendar.events.readonly']);
  final storage = const FlutterSecureStorage();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
    String email, 
    String password, 
    String firstName, 
    String lastName
  ) async {
    // Create the user
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Save additional user data to Firestore
    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'authProvider': 'email',  // Indicate auth method
    });

    return userCredential;
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled sign-in

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credentials
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Store access token securely
        await storage.write(key: 'google_access_token', value: googleAuth.accessToken);

        // Check if user exists in Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          // New user, save to Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'firstName': user.displayName?.split(" ").first ?? '',
            'lastName': user.displayName?.split(" ").last ?? '',
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
            'authProvider': 'google',  // Indicate auth method
          });
        }
      }
      return userCredential;
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  // Link Google account to existing email/password account
  Future<void> linkGoogleAccount() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link Google credential to existing Firebase account
      await _auth.currentUser?.linkWithCredential(credential);

      // Update Firestore with provider info
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'authProvider': 'email_google',
      });

      // Store access token securely
      await storage.write(key: 'google_access_token', value: googleAuth.accessToken);
    } catch (e) {
      print("Error linking Google account: $e");
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await storage.delete(key: 'google_access_token');
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    return await _auth.sendPasswordResetEmail(email: email);
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update(data);
    }
  }
}
