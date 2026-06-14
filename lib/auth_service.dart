import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class AuthException implements Exception {
  final String code;
  AuthException(this.code);
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Map<String, dynamic>? _currentUser;

  Map<String, dynamic>? get currentUser => _currentUser;
  String? get userEmail => _currentUser?['email'] as String?;
  int? get userId => _currentUser?['id'] as int?;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('current_user_id');
    if (userId != null) {
      _currentUser = await DatabaseService.getUserById(userId);
    }
  }

  Future<void> _saveLoginState() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_user_id', _currentUser!['id'] as int);
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    final hash = sha256.convert(utf8.encode(password)).toString();
    final user = await DatabaseService.getUserByEmail(email);
    if (user == null) throw AuthException('user-not-found');
    if (user['password_hash'] != hash) throw AuthException('wrong-password');
    _currentUser = user;
    await _saveLoginState();
  }

  Future<void> createUserWithEmailAndPassword(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    final existing = await DatabaseService.getUserByEmail(email);
    if (existing != null) throw AuthException('email-already-in-use');
    final hash = sha256.convert(utf8.encode(password)).toString();
    final id = await DatabaseService.createUser(email, hash, firstName, lastName);
    _currentUser = await DatabaseService.getUserById(id);
    await _saveLoginState();
  }

  Future<void> signOut() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
  }

  Future<Map<String, dynamic>?> getUserData() async {
    if (_currentUser == null) return null;
    return {
      'firstName': _currentUser!['first_name'],
      'lastName': _currentUser!['last_name'],
      'email': _currentUser!['email'],
    };
  }
}
