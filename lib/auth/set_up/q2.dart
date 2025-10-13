import 'package:biocue/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:biocue/auth/set_up/q3.dart';
import 'package:provider/provider.dart';
import 'package:biocue/models/userProvider.dart';

class Q2 extends StatefulWidget {
  const Q2({super.key});

  @override
  _Q2State createState() => _Q2State();
}

class _Q2State extends State<Q2> {
  double _height = 170; // in cm
  double _weight = 70; // in kg

  List<int> ageOptions = List.generate(100, (index) => index + 1);
  int? selectedAge;

  void _goToNextScreen() {
    if (selectedAge != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      userProvider.setHeight(_height);
      userProvider.setWeight(_weight);
      userProvider.setAge(selectedAge!);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Q3()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please input a valid age')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Question 2')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.straighten, size: 100.0, color: secondary2),
            SizedBox(height: 20),
            Text(
              'What is your Height and Weight?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            Text('Height: ${_height.toStringAsFixed(1)} cm'),
            Slider(
              value: _height,
              min: 100,
              max: 220,
              divisions: 120,
              activeColor: secondary1,
              inactiveColor: secondary2,
              thumbColor: Colors.white,
              label: '${_height.toStringAsFixed(1)} cm',
              onChanged: (value) {
                setState(() {
                  _height = value;
                });
              },
            ),

            const SizedBox(height: 20),

            Text('Weight: ${_weight.toStringAsFixed(1)} kg'),
            Slider(
              value: _weight,
              min: 30,
              max: 150,
              divisions: 120,
              activeColor: secondary1,
              inactiveColor: secondary2,
              thumbColor: Colors.white,
              label: '${_weight.toStringAsFixed(1)} kg',
              onChanged: (value) {
                setState(() {
                  _weight = value;
                });
              },
            ),
            const SizedBox(height: 20),

            DropdownButton<int>(
              value: selectedAge,
              hint: Text('Select Age'),
              items: ageOptions.map((int age) {
                return DropdownMenuItem<int>(
                  value: age,
                  child: Text(age.toString()),
                );
              }).toList(),
              onChanged: (int? item) {
                setState(() {
                  selectedAge = item;
                });
              },
            ),

            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: _goToNextScreen,
                child: Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
