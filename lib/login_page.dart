import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pro_job_tracker/auth_service.dart'; // Ensure this points to your AuthService file
import 'navigation.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  // Use AuthService instead of direct FirebaseAuth
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // Sign in with email and password using AuthService
        await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );

        // Navigate to the main screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => NavigationScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = _getErrorMessage(e.code);
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      UserCredential? user = await _authService.signInWithGoogle();
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NavigationScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google Sign-In failed. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user has been disabled.';
      default:
        return 'An error occurred during login. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8CB0DF),
        title: Text('Welcome Back!'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    color: Colors.red.shade100,
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),
              _isLoading
                  ? CircularProgressIndicator(color: const Color(0xFF8CB0DF))
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: _login,
                          child: Text('Log In'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8CB0DF),
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            textStyle: TextStyle(fontSize: 18),
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _signInWithGoogle,
                          icon: Image.asset('assets/google_logo.png', height: 24),
                          label: Text('Sign in with Google'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            textStyle: TextStyle(fontSize: 18),
                            side: BorderSide(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/create_account');
                },
                child: Text('Don\'t have an account? Create one'),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  _authService.sendPasswordResetEmail(_emailController.text.trim());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password reset email sent.'), backgroundColor: Colors.green),
                  );
                },
                child: Text('Forgot password?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
