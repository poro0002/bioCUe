import 'package:biocue/models/userProvider.dart';
import 'package:biocue/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:biocue/screens/home_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../config.dart';

class finished extends StatefulWidget {
  const finished({super.key});

  @override
  _finishedState createState() => _finishedState();
}

class _finishedState extends State<finished> {
  @override
  void goToNext() async {
    final userProfile = Provider.of<UserProvider>(
      context,
      listen: false,
    ).profile;

    try {
      // Check if this is a Google user
      final prefs = await SharedPreferences.getInstance();
      final googleUuid = prefs.getString('pendingGoogleUuid');

      // Get current Supabase user (will be null if regular email/password login)
      final supabaseUser = supabase.Supabase.instance.client.auth.currentUser;

      // Create the payload
      final payload = userProfile.toJson();

      // Add UUID to the userProfile if this is a Google OAuth user
      if (googleUuid != null) {
        payload['uuid'] = googleUuid;
      } else if (supabaseUser != null) {
        // Fallback: use current Supabase user ID if available
        payload['uuid'] = supabaseUser.id;
      }

      // ^^ this makes it so any user whether its a google sign up or just a traditional sign has a id that can be used for reference on a account

      // sends the payload of userprofile data to the updateUserData endpoint
      final response = await http.post(
        Uri.parse('${AppConfig.backendBaseUrl}/api/users/updateUserData'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('userdata successfully saved to supabase');

        // Clear the pending UUID if it exists
        if (googleUuid != null) {
          await prefs.remove(
            'pendingGoogleUuid',
          ); // get rid of the local uuid once its saved to that users data
        }

        Provider.of<UserProvider>(
          context,
          listen: false,
        ).completeFirstTimeSetup(); // call userProvider function to complete the registration log in.
      } else {
        print('there was an issue with saving userdata questions to supabase');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('there was a problem with the finished screen fetch $e');
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Completed')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.check_box, size: 100.0, color: secondary2),
              SizedBox(height: 20),
              Text(
                'Nice work!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                'you may change these answers in your account settings at any time',
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: goToNext,
                child: Text('Go to landing page'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
