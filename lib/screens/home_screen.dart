import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import './journal_screen.dart';
import './progress_screen.dart';
import './account_screen.dart';
import '../widgets/home_widgets/calander.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/home_widgets/journal_preview.dart';

// ---------------< Parent Widget >-----------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

// ---------------< State Class >-----------------------------

// set state is a function available in a any state class that triggers it to rebuild

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  DateTime selectedDate = DateTime.now();

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  String? email;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email');
    setState(() {}); // triggers rebuild
  }

  // ---------------< Top Nav Builder >-----------------------------

  @override
  Widget build(BuildContext context) {
    final avatarUrl =
        Supabase.instance.client.auth.currentUser?.userMetadata?['avatar_url'];

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(12.0), // optional: adjust spacing
          child: SizedBox(
            child: GestureDetector(
              child: CircleAvatar(
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null ? Icon(Icons.account_circle) : null,
              ),
            ),
          ),
        ),
        actions: [
          // Notification Bell with Dropdown Placeholder
          PopupMenuButton<String>(
            icon: const Icon(Icons.notifications),
            onSelected: (value) {
              // Placeholder: no action yet
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: '1',
                child: Text('No new notifications'),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeDashboard(
            // this just makes it overly complicated because this is basically homescreen in home screen
            selectedDate: selectedDate,
            onDateSelected: (date) => setState(() => selectedDate = date),
            email: email,
            onJournalTap: () => setState(() => _currentIndex = 1),
          ),
          JournalScreen(),
          ProgressScreen(),
          AccountScreen(),
        ],
      ),
      bottomNavigationBar: MyBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

// ---------------< Home Dashboard Builder >-----------------------------

// Separate widget for the actual home dashboard content
class HomeDashboard extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final String? email;
  final VoidCallback onJournalTap; // wtf is a void callback

  // Constructor
  // heres what the widget NEEDs so it can function
  const HomeDashboard({
    required this.selectedDate,
    required this.onDateSelected,
    required this.email,
    required this.onJournalTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // aligns left/top
        children: [
          Image.asset('assets/BioCue_logo_symbol.png', width: 80, height: 80),
          const SizedBox(height: 16),
          Text(
            'Welcome ${email ?? 'Guest'}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          HorizontalCalendar(
            startDate: DateTime.now().subtract(const Duration(days: 3)),
            selectedDate: selectedDate,
            onDateSelected: onDateSelected,
          ),
          const SizedBox(height: 20),
          JournalPreviewCard(onTap: onJournalTap),
        ],
      ),
    );
  }
}
