import './subScreens/healingCenter.dart';
import 'package:flutter/material.dart';

//-------------------------< HEALING CENTER HOME WIDGET >-----------------------------------

class HealingContent extends StatelessWidget {
  final VoidCallback onTap;
  const HealingContent({required this.onTap, super.key});

  // props
  // constructors
  // if needed

  @override
  Widget build(BuildContext context) {
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
          // stack is similar to z-index allowing you to stack widgets on top of eachother
          children: [
            const Positioned(
              top: 0,
              left: 0,
              child: Icon(
                Icons.self_improvement,
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
                    'Healing Center',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap to see recommended meditation, yoga, lifestyle, white noise content',
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
