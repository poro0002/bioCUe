import 'package:flutter/material.dart';
import 'package:biocue/models/userProvider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------< Parent Widget >-------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------

class FitBitKit extends StatefulWidget {
  const FitBitKit({super.key});

  @override
  State<FitBitKit> createState() => _FitBitKitState();
}

// ------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------< State Class >---------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------

class _FitBitKitState extends State<FitBitKit> {
  // the functions and states used here are going to be in the user provider so we can access it globally
  // grant access function will be here

  @override
  void initState() {
    super.initState();
    // if userProvider fitbitaccess state is true run the userProvider fetchfitbitdata function here
    Future.microtask(() {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.profile.hasFitBitAccess) {
        userProvider.fetchFitBitData(context);
      }
    });
  }

  void grantAccess() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userEmail = userProvider.profile.email;

    // scope=activity sleep heartrate profile give fitbit the data that you want back so it can give you an access token that will be able to grab that specific
    final authUrl =
        'https://www.fitbit.com/oauth2/authorize?response_type=code&client_id=23TPRM&redirect_uri=https%3A%2F%2Fungelatinized-disharmoniously-lenora.ngrok-free.dev%2Fapi%2FfitBit%2FhandleFitBitCallback&scope=activity%20sleep%20heartrate%20profile&expires_in=604800&state=$userEmail';

    final Uri url = Uri.parse(authUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      try {
        final response = await http.post(
          Uri.parse(
            '${AppConfig.backendBaseUrl}/api/fitBit/updateFitBitAccess',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': userEmail, 'fitBitAccess': true}),
        );

        if (response.statusCode == 200) {
          print('fitbitaccess bool has been updated in supabase');
          userProvider.profile.hasFitBitAccess = true;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => FitBitKit()),
          );
        } else {
          print('Failed to update Fitbit access bool: ${response.body}');
        }
      } catch (e) {
        print('there was an error trying to update the fitbit access bool');
      }
    } else {
      throw 'Could not launch Fitbit auth URL';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(
      context,
    ); // dont use listen: false here.... we want it true.  This will trigger a rebuild when notifyListeners() fires.
    return Scaffold(
      appBar: AppBar(title: const Text("FitBit")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!userProvider.profile.hasFitBitAccess) ...[
              // Apple logo or branding
              SizedBox(height: 50),
              Image.asset(
                'assets/Fitbit_logo_white.png',
                width: 200, // adjust path to match your asset folder
              ),
              SizedBox(height: 30),
              // Description text
              Text(
                "Connect FitBit to track your steps, heart rate, sleep, and more. Your data stays private and helps personalize your experience.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 40),
              Icon(Icons.warning, size: 30, color: Color(0xFFFF6F61)),
              SizedBox(height: 25),
              Text(
                "To ensure proper data syncing and integrity, please make sure you have a working Fitbit account and device.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),

              SizedBox(height: 24),

              // Grant access button
              ElevatedButton(
                onPressed: () => grantAccess(),
                child: Text("Grant Access"),
              ),
            ],

            if (userProvider.profile.hasFitBitAccess)
              FitBitDataPlaceholders(
                fitBitTotalSteps: userProvider.fitBitTotalSteps,
                fitBitTotalSleepHours: userProvider.fitBitTotalSleepHours,
                fitBitTotalDistance: userProvider.fitBitTotalDistance,
                fitBitTotalCalories: userProvider.fitBitTotalCalories,
                fitBitAvgHR: userProvider.fitBitAvgHR,
                fitBitMinHR: userProvider.fitBitMinHR,
                fitBitMaxHR: userProvider.fitBitMaxHR,
              ),
            // Add more widgets here later
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------------------------------------------------------------
// ------------------------------< Child widget that displays the fitbit metadata >--------------------------------
// ------------------------------------------------------------------------------------------------------------------------

class FitBitDataPlaceholders extends StatelessWidget {
  // vars
  final double fitBitTotalSteps;
  final double fitBitTotalSleepHours;
  final double fitBitTotalDistance;
  final double fitBitTotalCalories;

  final double fitBitAvgHR;
  final double fitBitMinHR;
  final double fitBitMaxHR;

  // constructors to pass props
  const FitBitDataPlaceholders({
    super.key,
    required this.fitBitTotalSteps,
    required this.fitBitTotalSleepHours,
    required this.fitBitTotalDistance,
    required this.fitBitTotalCalories,
    required this.fitBitAvgHR,
    required this.fitBitMinHR,
    required this.fitBitMaxHR,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final now = DateTime.now();
    final yesterday = DateFormat.yMMMMd().format(
      now.subtract(Duration(days: 1)),
    );
    final today = DateFormat.yMMMMd().format(now);
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/Fitbit_logo_white.png',
            width: 150, // adjust path to match your asset folder
          ),
          SizedBox(height: 24),
          Text(
            'Data For Dates',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text('$yesterday – $today', style: TextStyle(color: Colors.white)),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 320,
                height: 130,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black, blurRadius: 4)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Steps',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Icon(
                      Icons.directions_walk,
                      size: 32,
                      color: Color(0xFF4CC2C4),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '$fitBitTotalSteps',
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                width: 150,
                height: 150,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black, blurRadius: 4)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sleep',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Icon(Icons.bed, size: 32, color: Color(0xFF4CC2C4)),
                    SizedBox(height: 8),
                    Text(
                      '$fitBitTotalSleepHours',
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                width: 150,
                height: 150,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black, blurRadius: 4)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Distance',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Icon(Icons.place, size: 32, color: Color(0xFF4CC2C4)),
                    SizedBox(height: 8),
                    Text(
                      '$fitBitTotalDistance mi',
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 330,
                height: 130,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black, blurRadius: 4)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Calories',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Icon(
                      Icons.local_fire_department,
                      size: 32,
                      color: Color(0xFF4CC2C4),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '$fitBitTotalCalories',
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 330,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black, blurRadius: 4)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Low', style: TextStyle(color: Colors.black)),
                        SizedBox(height: 8),
                        Text(
                          '$fitBitMinHR BPM',
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'HeartRate',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.favorite,
                          size: 32,
                          color: Color(0xFF4CC2C4),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '$fitBitAvgHR BPM',
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('High', style: TextStyle(color: Colors.black)),
                        SizedBox(height: 8),
                        Text(
                          '$fitBitMaxHR BPM',
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: userProvider.RevokeFitBitAccess,
            child: Text('Revoke Fit Bit Access'),
          ),
        ],
      ),
    );
  }
}
