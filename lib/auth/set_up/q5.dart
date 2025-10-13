import 'package:biocue/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:biocue/auth/set_up/q6.dart';
import 'package:provider/provider.dart';
import 'package:biocue/models/userProvider.dart';

class Q5 extends StatefulWidget {
  const Q5({super.key});

  @override
  _Q5State createState() => _Q5State();
}

class _Q5State extends State<Q5> {
  final List<TextEditingController> _allergyControllers = [];

  void _addAllergyField() {
    setState(() {
      _allergyControllers.add(TextEditingController());
    });
  }

  void _goToNextScreen() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final allergies = _allergyControllers
        .map((controller) => controller.text.trim())
        .where((med) => med.isNotEmpty)
        .toList();

    // You can now store `medications` or pass it to the next screen
    userProvider.setAllergies(allergies);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Q6()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Question 5')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.warning, size: 100.0, color: secondary2),
              SizedBox(height: 20),
              Text(
                'Do you have any serious Allergies ?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ..._allergyControllers.map(
                (controller) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Allergy name',
                    ),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _addAllergyField,
                icon: Icon(Icons.add),
                label: Text('Add another Allergy'),
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
