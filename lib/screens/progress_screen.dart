import 'package:flutter/material.dart';
import '../themes/colors.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.show_chart, size: 40, color: secondary1),
          SizedBox(height: 10),
          Text('Progress', style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}
