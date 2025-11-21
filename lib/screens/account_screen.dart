import 'package:flutter/material.dart';
import '../themes/colors.dart';
import 'package:biocue/auth/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:biocue/models/userProvider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// this page will eventually update local and supabase state because ity will give users the option to update their personal questions data
// amongst other things like push notifications toggles ect..

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  void logout() async {
    // Sign out from Supabase
    await Supabase.instance.client.auth.signOut();

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    // Clear UserProvider
    Provider.of<UserProvider>(context, listen: false).logout();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final email = userProvider.profile.email;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, size: 40, color: secondary1),
          SizedBox(height: 20),
          Text('Account', style: TextStyle(fontSize: 20)),
          SizedBox(height: 20),
          Text(email, style: TextStyle(fontSize: 13)),
          SizedBox(height: 20),
          ElevatedButton(onPressed: logout, child: Text('Logout')),
        ],
      ),
    );
  }
}
