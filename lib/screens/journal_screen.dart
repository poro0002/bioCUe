import 'package:flutter/material.dart';
import '../themes/colors.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.book, size: 40, color: secondary1),
          SizedBox(height: 10),
          Text('Journal', style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}
