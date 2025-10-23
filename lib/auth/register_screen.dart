import 'package:biocue/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:biocue/auth/login_screen.dart';
import 'dart:convert'; // For jsonEncode
import 'package:http/http.dart' as http; // For http.post

import '../config.dart';

// ------------------------------------< Parent Widget >-----------------------------------------

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

// ------------------------------------< State Class >------------------------------------------

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ---------------------------------------------------------
  // ---------------< Password Validate Function >---------------
  // ---------------------------------------------------------

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password needs to be at least 8 characters';
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password needs at least 1 lowercase letter';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password needs at least 1 uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password needs at least one number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password needs at least 1 symbol';
    }
    if (value != _confirmPasswordController.text) {
      return 'Passwords need to match';
    }

    return null;
  }
  // ---------------------------------------------------------
  // ---------------< Email Validate Function >---------------
  // ---------------------------------------------------------

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'email is required';

    final List<String> allowedDomains = [
      '@gmail.com',
      '@hotmail.com',
      '@outlook.com',
    ];

    bool isValidDomain = allowedDomains.any((domain) => value.endsWith(domain));

    if (!isValidDomain) {
      return 'Please use a valid email domain (gmail, outlook, hotmail)';
    }

    return null; // this jst makes it so it doesnt return an error
  }

  // ---------------------------------------------------------
  // ---------------< Register Account Function >---------------
  // ---------------------------------------------------------

  void registerAccount() async {
    // ← Need 'async' keyword
    final passwordError = validatePassword(_confirmPasswordController.text);
    final emailError = validateEmail(_emailController.text);

    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(passwordError),
          backgroundColor: Colors.primaries.first,
          duration: Duration(seconds: 3),
        ),
      );
    }

    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailError),
          backgroundColor: Colors.primaries.first,
          duration: Duration(seconds: 3),
        ),
      );
    }

    if (passwordError == null && emailError == null) {
      try {
        final response = await http.post(
          Uri.parse('${AppConfig.backendBaseUrl}/api/users/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text,
            'password': _passwordController.text,
            'firstTimeLogin': true,
          }),
        );
        // in dart(flutter) package http: uses response.statusCode // → int (e.g. 200, 201, 404, etc.) response.body // → raw response string
        // Handle success case
        if (response.statusCode == 200 || response.statusCode == 201) {
          // Navigate to login or show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration successful!'),
              backgroundColor: Colors.white,
            ),
          );

          // Navigate to login screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } else if (response.statusCode == 409) {
          // Duplicate email
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An account with this email already exists'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // ← 'catch' needs to be attached to 'try'
        print('Network error: $e'); // ← Fixed string interpolation
      }
    } else {
      // Handle validation errors
      print('Validation failed');
    }
  }

  // ---------------------------------------------------------
  // ---------------< Navigation Function >---------------
  // ---------------------------------------------------------

  void gotToLoginScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // we need to add rule base cases here when the user is creating a password
  // the users email will be there username essentially

  // ---------------------------------------------------------
  // ---------------< Build Method >-------------------
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(100.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/BioCue_logo_symbol.png',
                width: 75.0,
                height: 75.0,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'please enter your email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirm Password'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: registerAccount,
                child: Text('Register'),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: gotToLoginScreen,
                child: Text(
                  'Already have an Account ?',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: secondary2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
