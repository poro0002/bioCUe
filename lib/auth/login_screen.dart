import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:biocue/auth/register_screen.dart';
import 'package:biocue/themes/colors.dart';
import 'package:biocue/auth/set_up/q1.dart';
import 'package:biocue/screens/home_screen.dart';
import 'package:biocue/models/userProvider.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

import '../config.dart';

// ------------------------------------< Parent Widget >-----------------------------------------

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

// ------------------------------------< State Class >------------------------------------------

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final StreamSubscription<supabase.AuthState> _authSubscription;
  bool _isGoogleLoading = false;

  // ---------------------------------------------------------
  // ---------------< Init State >---------------------------
  // ---------------------------------------------------------

  // these are basically Reload or Clean functions

  //is required to make sure Flutter does its own setup too.
  @override
  void initState() {
    super
        .initState(); // this ensures your app reacts immediately when a user logs in with Google — even if they come back from an external browser or app.
    _setupAuthListener(); // calls to start listening for changes in the user’s authentication state (like logging in or out).
  }

  // This runs when your widget is being destroyed — like when the user navigates away from the login screen.
  // Cancels the Supabase auth listener so it doesn’t keep running in the background.
  // Disposes of the email and password text controllers to free up memory.

  @override
  void dispose() {
    _authSubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // ---------------< Google/Supabase Auth Listener >-----------
  // ---------------------------------------------------------

  // This sets up a listener for Supabase’s authentication state changes that the front end manages

  // ---------------< this is what happens after the user is redirected back to the app via callback >-----------
  // so here it then grabs the auth info it needs from the auth user that was created in supabase

  void _setupAuthListener() {
    // Supabase sends a data object that contains a session.
    _authSubscription = supabase.Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          final session = data
              .session; // This is the actual user object inside the session.

          if (session != null && mounted) {
            // if the required user data aka session is there we run the next function
            _handleSuccessfulGoogleLogin(
              session.user,
            ); // run the next part of the login and pass the user data as parameter
          }
        });
  }

  // this is then put inside a initState function that ensures your app reacts immediately when a user logs in with Google

  // ---------------------------------------------------------
  // ---------------< Handle Google Login Success >-----------
  // ---------------------------------------------------------

  // "Future" is a keyword that makes it so it returns a promise
  // you dont necessarily need it if its a void async function

  Future<void> _handleSuccessfulGoogleLogin(supabase.User user) async {
    //
    // grabs the locally stored variable and sets to true
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('email', user.email ?? '');

    // Set user email info in provider
    Provider.of<UserProvider>(
      context,
      listen: false,
    ).setEmail(user.email ?? '');

    // runs the login function for provider with the user.email

    Provider.of<UserProvider>(context, listen: false).login(user.email ?? '');

    // mounted is a built-in property of every State class in Flutter. checks if the widget is doen loading or not
    // If mounted == true, the widget is alive and you can safely call setState() or use context.
    if (mounted) {
      // Stop the loading spinner
      setState(() => _isGoogleLoading = false);

      // Check if user exists in your custom users table
      try {
        // asking backend: does this Supabase-authenticated user also exist in our custom app database?
        final response = await http.get(
          Uri.parse(
            '${AppConfig.backendBaseUrl}/api/users/check-user?email=${Uri.encodeComponent(user.email ?? '')}',
          ),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // If the user is new or it’s their first time logging in, you:

          if (data['exists'] == false || data['firstTimeLogin'] == true) {
            // Store the Supabase auth UUID in local storage for later use
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'pendingGoogleUuid',
              user.id,
            ); // set the uuid in local storage so we can use it later on

            await http.post(
              Uri.parse(
                '${AppConfig.backendBaseUrl}/api/users/create-google-user',
              ),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'uuid': user.id,
                'email': user.email,
                'firstTimeLogin': true,
                // optionally include other fields like name, age, etc.
              }),
            );

            // New Google user - send to onboarding questions
            Navigator.of(
              context,
            ).pushReplacement(MaterialPageRoute(builder: (_) => const Q1()));
          } else {
            // Existing user - go to home
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          }
        }
      } catch (e) {
        print('Error checking user: $e');
        // Default to Q1 if the user exists check fails
        if (mounted) {
          setState(() => _isGoogleLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unable to check if user exists. Please try again.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  // ---------------------------------------------------------
  // ---------------< Google Sign In >------------------------
  // ---------------------------------------------------------

  // "Future" you dont necessarily need it if its a void async function

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    // Supabase opens a browser and redirects the user to Google's OAuth login page.
    // The user hasn't selected an account yet — this just starts the login flow.
    // Supabase handles the handshake and will receive the user info after the google login is complete.
    // -----> this piece of code only waits for Supabase to launch the external browser and initiate the OAuth flow. <-------

    try {
      await supabase.Supabase.instance.client.auth.signInWithOAuth(
        supabase.OAuthProvider.google,
        authScreenLaunchMode: supabase.LaunchMode.externalApplication,
        redirectTo: 'com.kieran.biocue://login-callback',
      );

      print('Google OAuth initiated');
    } catch (e) {
      print('Google sign in error: $e');
      if (mounted) {
        setState(() => _isGoogleLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Google sign in failed: $e')));
      }
    }
  }

  // ---------------------------------------------------------
  // ---------------< Navigation Function >-------------------
  // ---------------------------------------------------------

  void gotToRegScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  // ---------------------------------------------------------
  // ---------------< Login Function >------------------------
  // ---------------------------------------------------------

  void login() async {
    print('Login function triggered');
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendBaseUrl}/api/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        final data = jsonDecode(response.body);
        final userEmail = data['user']['email'];

        Provider.of<UserProvider>(context, listen: false).setEmail(userEmail);
        Provider.of<UserProvider>(context, listen: false).login(userEmail);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login Successful'),
            duration: Duration(seconds: 3),
          ),
        );

        if (data['user']['firstTimeLogin'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Q1()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      print('there was a problem with the login fetch: $e');
    }
  }

  // ---------------------------------------------------------
  // ---------------< Build Method >--------------------------
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(100.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/BioCue_logo_symbol.png'),
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
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    login();
                  }
                },
                child: Text('Login'),
              ),
              SizedBox(height: 10),
              _isGoogleLoading
                  ? const CircularProgressIndicator()
                  : SignInButton(Buttons.google, onPressed: _signInWithGoogle),
              SizedBox(height: 20),
              TextButton(
                onPressed: gotToRegScreen,
                child: Text(
                  'Dont have an account?',
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
