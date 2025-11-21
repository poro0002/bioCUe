import 'package:flutter/material.dart';
import 'package:biocue/models/userProvider.dart';
import 'package:provider/provider.dart';

class FitBit extends StatelessWidget {
  final VoidCallback onTap;

  const FitBit({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return (GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
        padding: const EdgeInsets.all(16.0),
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
            Positioned(
              top: 10,
              left: 7,
              child: Image.asset('assets/Fitbit_logo.png', width: 100),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 50,
                left: 10,
              ), // offset to avoid overlap
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Text(
                    'Tap to see sync your FitBit analytics to help track your symptoms',
                    style: TextStyle(fontSize: 10, color: Colors.black),
                  ),
                  SizedBox(height: 27),
                  if (userProvider.profile.hasFitBitAccess) ...[
                    Row(
                      children: [
                        Text(
                          'Connected',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const Icon(
                          Icons.check_circle,
                          size: 20,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
