import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:biocue/themes/colors.dart';
import '../../screens/journal_screen.dart';

class JournalPreviewCard extends StatelessWidget {
  final VoidCallback onTap;

  const JournalPreviewCard({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat.yMMMMd().format(DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 0,
              left: 0,
              child: Icon(
                Icons.healing, // 🩺 You can swap this for any relevant icon
                size: 28,
                color: Color(0xFFFF6F61),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(
                left: 36,
              ), // offset to avoid overlap
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Symptom Journal',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap to log today’s symptoms or view past entries.',
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Text(
                today,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
