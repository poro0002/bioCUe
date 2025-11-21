// prompts users too hook up apple health to track their bio data
// with an apple watch bpm, sleep analysis, respiratory rate, HRV and more are available
// but most people didnt have apple watches, just phones
// so a lot the data that we will be logging is just steps, kcals, distance, flights climbed ?
// we should still try to get that apple watch data if is there

// this screen will show all their bio data displayed nicely so they can see it
// behind the scenes the ai in charge of the user data will get access to this when the user does a journal entry for that day
// so basically im going to fetch it, display it (if its available) and store it locally so when they user finishes a journal entry it will be sent to the ai along with the rest of the data in the journal entry

// build THIS widget tomorrow as well and test it

import 'package:biocue/models/userProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppleHealth extends StatelessWidget {
  final VoidCallback onTap;

  const AppleHealth({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
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
            Positioned(
              top: 0,
              left: 50,
              child: Image.asset(
                'assets/Apple_logo_black.svg.png',
                width: 20, // match icon size or adjust as needed
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(
                left: 10,
              ), // offset to avoid overlap
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 35),
                  Text(
                    'Apple Health',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap to sync Apple Health analytics to help track your symptoms',
                    style: TextStyle(fontSize: 10, color: Colors.black),
                  ),
                  SizedBox(height: 8),
                  if (userProvider.hasAppleAccess) ...[
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
    );
  }
}
