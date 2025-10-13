import 'package:biocue/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:biocue/auth/set_up/q4.dart';
import 'package:provider/provider.dart';
import 'package:biocue/models/userProvider.dart';

class Q3 extends StatefulWidget {
  const Q3({super.key});

  @override
  _Q3State createState() => _Q3State();
}

class _Q3State extends State<Q3> {
  String? _selectedIllness;
  final TextEditingController _otherIllnessController = TextEditingController();

  final List<String> _illnessOptions = [
    'Depression',
    'Anxiety',
    'Chronic Fatigue Syndrome (CFS)',
    'Myalgic Encephalomyelitis (ME)',
    'Post-COVID Syndrome',
    'Post-Concussion Syndrome',
    'Rheumatoid Arthritis',
    'Fibromyalgia',
    'Irritable Bowel Syndrome (IBS)',
    'Crohn’s Disease',
    'Ulcerative Colitis',
    'Lupus',
    'Multiple Sclerosis',
    'Type 1 Diabetes',
    'Type 2 Diabetes',
    'Asthma',
    'COPD',
    'Migraines',
    'Epilepsy',
    'Endometriosis',
    'PCOS',
    'Chronic Pain',
    'Insomnia',
    'Bipolar Disorder',
    'PTSD',
    'Other',
  ];

  void goToNextScreen() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final selected = _selectedIllness == 'Other'
        ? _otherIllnessController.text.trim()
        : _selectedIllness;

    if (selected != null && selected.isNotEmpty) {
      userProvider.setSelectedIllnesses([_selectedIllness!]);
      Navigator.push(context, MaterialPageRoute(builder: (context) => Q4()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select or enter an illness')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOtherSelected = _selectedIllness == 'Other';

    return Scaffold(
      appBar: AppBar(title: Text('Question 3')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.healing, size: 100.0, color: secondary2),
            SizedBox(height: 20),
            Text(
              'Which chronic illness do you struggle with?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedIllness,
              items: _illnessOptions.map((illness) {
                return DropdownMenuItem(value: illness, child: Text(illness));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedIllness = value;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Select illness',
              ),
            ),
            if (isOtherSelected) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _otherIllnessController,
                decoration: InputDecoration(
                  labelText: 'Please specify your illness',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: goToNextScreen,
                child: Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
