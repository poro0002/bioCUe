import 'package:biocue/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:biocue/auth/set_up/finished.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:biocue/models/userProvider.dart';

class Q7 extends StatefulWidget {
  const Q7({super.key});

  @override
  _Q7State createState() => _Q7State();
}

class _Q7State extends State<Q7> {
  double neuroticismValue = 50.0;
  double opennessValue = 50.0;
  double conscientiousnessValue = 50.0;
  double extraversionValue = 50.0;
  double agreeablenessValue = 50.0;

  void goToNext() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    userProvider.setAgreeableness(agreeablenessValue);
    userProvider.setConscientiousness(conscientiousnessValue);
    userProvider.setExtraversion(extraversionValue);
    userProvider.setNeuroticism(neuroticismValue);
    userProvider.setOpenness(opennessValue);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const finished()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Question 7')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.psychology, size: 100.0, color: secondary2),
              SizedBox(height: 40),
              Text(
                'Please Select where you score on each personality trait',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text('Not sure ? Take the test below'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  launchUrl(
                    Uri.parse(
                      'https://www.truity.com/test/big-five-personality-test',
                    ),
                  );
                },
                child: Text('Take the Big Five Test'),
              ),
              SizedBox(height: 100),
              Text(
                // --------------------------------------< Neuroticism >----------------------------------------------
                'Neuroticism',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                'Measures emotional stability. Higher scores indicate more emotional reactivity and sensitivity to stress.',
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Less'),
                  Expanded(
                    child: Slider(
                      value: neuroticismValue,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: neuroticismValue.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          neuroticismValue = value;
                        });
                      },
                    ),
                  ),
                  Text('More'),
                ],
              ), // --------------------------------------< Openness >----------------------------------------------
              SizedBox(height: 100),
              Text(
                'Openness',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                'Reflects your level of creativity, curiosity, and willingness to explore new experiences. Higher scores indicate greater imagination and openness to ideas.',
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Less'),
                  Expanded(
                    child: Slider(
                      value: opennessValue,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: opennessValue.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          opennessValue = value;
                        });
                      },
                    ),
                  ),
                  Text('More'),
                ],
              ), // --------------------------------------< Conscientiousness >----------------------------------------------
              SizedBox(height: 100),
              Text(
                'Conscientiousness',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                'Represents your level of organization, discipline, and reliability. Higher scores indicate greater attention to detail and goal-oriented behavior.',
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Less'),
                  Expanded(
                    child: Slider(
                      value: conscientiousnessValue,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: conscientiousnessValue.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          conscientiousnessValue = value;
                        });
                      },
                    ),
                  ),
                  Text('More'),
                ],
              ), // --------------------------------------< Extraversion >----------------------------------------------
              SizedBox(height: 100),
              Text(
                'Extraversion',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                'Indicates your level of sociability, energy, and assertiveness. Higher scores reflect a preference for social interaction and stimulation.',
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Less'),
                  Expanded(
                    child: Slider(
                      value: extraversionValue,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: extraversionValue.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          extraversionValue = value;
                        });
                      },
                    ),
                  ),
                  Text('More'),
                ],
              ), // --------------------------------------< Agreeableness >----------------------------------------------
              SizedBox(height: 100),
              Text(
                'Agreeableness',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                'Reflects your tendency to be compassionate, cooperative, and trusting. Higher scores indicate a more empathetic and harmonious approach to others.',
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Less'),
                  Expanded(
                    child: Slider(
                      value: agreeablenessValue,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: agreeablenessValue.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          agreeablenessValue = value;
                        });
                      },
                    ),
                  ),
                  Text('More'),
                ],
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
