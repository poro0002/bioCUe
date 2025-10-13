import 'package:biocue/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:biocue/auth/set_up/q2.dart';
import 'package:provider/provider.dart';
import 'package:biocue/models/userProvider.dart';

// ---------------< Parent Widget >-----------------------------

class Q1 extends StatefulWidget {
  const Q1({super.key});

  @override
  _Q1State createState() => _Q1State();
}

// ---------------< State Class >-----------------------------

class _Q1State extends State<Q1> {
  String? _selectedGender;

  void _goToNextScreen() {
    // void mean this doesnt return anything
    if (_selectedGender != null) {
      // print('Calling setGender with: $_selectedGender');
      Provider.of<UserProvider>(
        context,
        listen: false,
      ).setGender(_selectedGender!);

      Navigator.push(context, MaterialPageRoute(builder: (context) => Q2()));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a gender')));
    }
  }

  // ---------------< Button Builder >-----------------------------

  Widget _buildGenderButton(String label) {
    final isSelected = _selectedGender == label;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.secondary
            : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      onPressed: () {
        setState(() {
          _selectedGender = label;
        });
      },
      child: Text(label),
    );
  }

  // ---------------< Build Method >-----------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Question 1')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            Icon(Icons.transgender_sharp, size: 100.0, color: secondary2),
            SizedBox(height: 20),
            Text(
              'What gender do you identify as?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildGenderButton('Male'),
                _buildGenderButton('Female'),
                _buildGenderButton('Non-binary'),
                _buildGenderButton("I'd rather not say"),
              ],
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
