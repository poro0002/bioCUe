import 'package:biocue/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:biocue/auth/set_up/q5.dart';
import 'package:provider/provider.dart';
import 'package:biocue/models/userProvider.dart';

class Q4 extends StatefulWidget {
  const Q4({super.key});

  @override
  _Q4State createState() => _Q4State();
}

class _Q4State extends State<Q4> {
  final List<TextEditingController> _medicationControllers = [];

  void _addMedicationField() {
    setState(() {
      _medicationControllers.add(TextEditingController());
    });
  }

  void _goToNextScreen() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final medications = _medicationControllers
        .map((controller) => controller.text.trim())
        .where((med) => med.isNotEmpty)
        .toList();

    // You can now store `medications` or pass it to the next screen
    userProvider.setPrescribedMedications(medications);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Q5()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Question 4')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.medication, size: 100.0, color: secondary2),
              SizedBox(height: 20),
              Text(
                'Do you take any prescribed medications?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ..._medicationControllers.map(
                (controller) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Medication name',
                    ),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _addMedicationField,
                icon: Icon(Icons.add),
                label: Text('Add another medication'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(onPressed: _goToNextScreen, child: Text('Next')),
            ],
          ),
        ),
      ),
    );
  }
}
