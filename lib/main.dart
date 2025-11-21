import 'package:flutter/material.dart';
import 'package:biocue/screens/home_screen.dart';
import 'themes/themes.dart';
import 'package:provider/provider.dart';
import 'package:biocue/models/userProvider.dart';
import 'package:biocue/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'package:uni_links/uni_links.dart';

// ---------------< main app entry >-----------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  await Supabase.initialize(
    url: 'https://chcwwdrvzlnaygqyjhnw.supabase.co',
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final prefs = await SharedPreferences.getInstance();

  // Checks if there’s a valid Supabase session via supabase methods built in for user auth flow
  final isLoggedIn = Supabase.instance.client.auth.currentSession != null;

  await prefs.setBool('isLoggedIn', isLoggedIn);

  final userProvider = UserProvider();

  if (isLoggedIn) {
    await userProvider.restoreUserProfile();
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) =>
          userProvider, // access user provider anywhere in the app as its at the top level
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

// ---------------< Parent Widget >-----------------------------

class MyApp extends StatefulWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

// ---------------< State Class >-----------------------------

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;

  // the reason these are in the main is because when the user is redirected and loggedin outside the app the whole app has to rerender and reauthenticate and mount again

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
    _handleInitialUri();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // Deep Link: is a login callback that brings you back to the app
  // Handle the initial URI when app is opened from a deep link

  // Supabase handles the OAuth callback automatically
  // these two functions below are literally just for debugging

  Future<void> _handleInitialUri() async {
    try {
      // Checks if the app was opened from a deep link to see if the user has been redirected back to the app from a external page
      final uri = await getInitialUri();
      if (uri != null) {
        print('Initial URI: $uri');
        // Supabase will automatically handle the OAuth callback
      }
    } catch (e) {
      print('Error getting initial URI: $e');
    }
  }

  // Handle deep links while app is running

  void _handleIncomingLinks() {
    _sub = uriLinkStream.listen(
      // scans for incoming redirection via deep link
      (Uri? uri) {
        if (uri != null) {
          print('Deep link received: $uri');
          // Supabase will automatically handle the OAuth callback
        }
      },
      onError: (err) {
        print('Error listening to URI stream: $err');
      },
    );
  }

  // ---------------< Build Method >-----------------------------

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BioCue',
      theme: appTheme,
      home: widget.isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
