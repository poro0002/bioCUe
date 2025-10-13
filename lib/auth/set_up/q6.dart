import 'package:biocue/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:biocue/auth/set_up/q7.dart';
import 'package:provider/provider.dart';
import 'package:biocue/models/userProvider.dart';

class Q6 extends StatefulWidget {
  const Q6({super.key});

  @override
  _Q6State createState() => _Q6State();
}

class _Q6State extends State<Q6> {
  final List<String> dietOptions = [
    'Standard Healthy',
    'Moderate Healthy',
    'Poor Diet',
    'Carnivore',
    'Keto',
    'Non-Gluten',
    'Plant Based',
    'Vegan',
    'Vegetarian',
  ];

  String? selectedDiet;

  void goToNext() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (selectedDiet != null) {
      userProvider.setDiet(selectedDiet!);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Q7()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a Diet ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dietEntries = dietOptions
        .map((option) => DropdownMenuEntry(value: option, label: option))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Question 6')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.local_dining, size: 100.0, color: secondary2),
              SizedBox(height: 20),
              Text(
                'What type of diet do you have ?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              DropdownMenu<String>(
                dropdownMenuEntries: dietEntries,
                initialSelection: selectedDiet,
                onSelected: (value) {
                  setState(() {
                    selectedDiet = value;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: goToNext, child: Text('Next')),
            ],
          ),
        ),
      ),
    );
  }
}
