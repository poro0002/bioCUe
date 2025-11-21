import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:biocue/models/userProvider.dart';
import 'package:provider/provider.dart';
import '../../../config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppleHealthKit extends StatefulWidget {
  const AppleHealthKit({super.key});

  @override
  State<AppleHealthKit> createState() => _AppleHealthKitState();
}

// --------------------------------------------< State Class >------------------------------------------------------

// all the totalMetaData variables, fetchHealthData() function and _convertAppleKitData() function will need to be moved to userProvider
// this is so the function and metaData can be accessed globally and fetched when the user opens the app
// this is so when a journal entry is executed, the data can be pulled from the provider and given to the langchain ai all in one go

class _AppleHealthKitState extends State<AppleHealthKit> {
  // late` lets you defer initialization until `initState()`------ late means “I promise I’ll initialize this before I use it” its a promise essentially
  // late bools are not used now that the vars have been used to userProvider ^^^^disregard

  // initState runs once when the widget is first inserted into the widget tree. Think of it as the widget’s “constructor for state.”
  // Used to initialize variables, start animations, set up listeners, or trigger async logic

  @override
  void initState() {
    super.initState();

    // Schedules this to run right after initState completes,
    // ensuring the widget is mounted before accessing Provider (you can sometimes get errors if provider is accessed too early)
    Future.microtask(() {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.hasAppleAccess) {
        userProvider.fetchHealthData();
      }
    });
  }

  // for steps loop through all the returned HealthDataType.STEPS data and add it to a total sum variable ?
  //for heartrrate go through all the values and calucalte the average, and as well get the lowest BPM and Highest and save those as well
  // total sum of HealthDataType.SLEEP_ASLEEP bvalues and add them all together to get a double type number (8.36 (like 8hr and 36min))
  // get the total of  HealthDataType.ACTIVE_ENERGY_BURNED, and add it to the total of HealthDataType.BASAL_ENERGY_BURNED, to get total calories burned
  // get the total sum of HealthDataType.DISTANCE_WALKING_RUNNING,

  // --------------------------------------------< Convert Apple Data Function >------------------------------------------------------

  // --------------------------------------------< Fetch Health Data Function >------------------------------------------------------

  // --------------------------------------------< GrantAccess Function >------------------------------------------------------

  Future<void> grantAccess() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final types = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.ACTIVE_ENERGY_BURNED, // kcal
      HealthDataType.DISTANCE_WALKING_RUNNING, // meters
      HealthDataType.BASAL_ENERGY_BURNED,
    ];

    final permissions = [
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
    ];

    // Check if permissions are already granted
    final hasPermissions = await Health().hasPermissions(
      types,
      permissions: permissions,
    );
    print('🔐 HealthKit permissions still valid: $hasPermissions');

    if (hasPermissions != true) {
      final granted = await Health().requestAuthorization(
        types,
        permissions: permissions,
      );
      if (!granted) {
        print('Permission denied');
        return;
      }
    }

    final now = DateTime.now();
    final twentyFourHour = now.subtract(
      Duration(days: 1),
    ); // or Duration(hours: 24)

    // this returns a list of health data points if permission has been granted
    final data = await Health().getHealthDataFromTypes(
      types: types,
      startTime: twentyFourHour,
      endTime: now,
    );

    // extra shit for logging ---------------------------------------------------------------
    print('Fetched ${data.length} health data points');

    if (data.isEmpty) {
      print(
        ' No health data points returned. Check time window, permissions, and device sync.',
      );
    }

    for (var point in data) {
      print('RAW: ${point.type} → ${point.value}');

      if (point.value is! NumericHealthValue) {
        print('SKIPPED: ${point.type} is not numeric');
        continue;
      }

      final value = (point.value as NumericHealthValue).numericValue;
      print('PARSED: ${point.type} → $value');
    }

    // ^^^^^^^extra shit for logging ---------------------------------------------------------------

    // here we need to set the appleHealthAccess profile bool to true && we need to update the supabase bool for that user
    userProvider.setAppleAccess(true);

    // update the corro users applehealthaccess bool in the supabase database so the state is saved

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ?? '';
      final response = await http.post(
        Uri.parse(
          '${AppConfig.backendBaseUrl}/api/appleHealth/updateAppleHealthAccess',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'appleHealthAccess': true}),
      );

      if (response.statusCode == 200) {
        print('Successfully updated appleHealthAccess in Supabase');
      } else {
        print('Failed to update appleHealthAccess: ${response.body}');
      }
    } catch (e) {
      print('Error updating appleHealthAccess: $e');
    }

    // just one point of data would look something like this
    //   HealthDataPoint(
    //     type: HealthDataType.STEPS,
    //     value: NumericHealthValue(87.0),
    //     unit: HealthDataUnit.COUNT,
    //     dateFrom: DateTime(2025, 10, 28, 14, 00),
    //     dateTo: DateTime(2025, 10, 28, 14, 05),
    //     sourceName: "Apple Health",
    //     sourcePlatform: HealthPlatformType.IOS,
    // )

    //  and a full list returned would look like this
    // --------------------< Data >------------------------------------
    // [  HealthDataPoint(type: STEPS, value: NumericHealthValue(120.0), ...),
    //   HealthDataPoint(type: STEPS, value: NumericHealthValue(87.0), ...),
    //   HealthDataPoint(type: ACTIVE_ENERGY_BURNED, value: NumericHealthValue(300.0), ...),
    //   HealthDataPoint(type: DISTANCE_WALKING_RUNNING, value: NumericHealthValue(140.0), ...),
    //   ...
    // ]

    userProvider.convertAppleKitData(data);
    print('Fetched ${data.length} health data points');
  }

  // --------------------------------------------< Build Method >------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(
      context,
    ); // dont use listen: false here.... we want it true.  This will trigger a rebuild when notifyListeners() fires.
    return Scaffold(
      appBar: AppBar(title: const Text("Apple Health")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!userProvider.hasAppleAccess) ...[
              // Apple logo or branding
              SizedBox(height: 50),
              Image.asset(
                'assets/Apple_logo_white.svg.png',
                width: 48, // adjust path to match your asset folder
              ),
              SizedBox(height: 16),
              Text(
                'Apple Health',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 16),

              // Description text
              Text(
                "Connect Apple Health to track your steps, heart rate, sleep, and more. Your data stays private and helps personalize your experience.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 40),
              Icon(Icons.warning, size: 30, color: Color(0xFFFF6F61)),

              Text(
                "For optimal data accuracy, an Apple Watch is recommended. Using only an iPhone may result in limited or less detailed health metrics.",
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

            if (userProvider.hasAppleAccess)
              AppleKitDataPlaceholders(
                totalSteps: userProvider.totalSteps,
                totalSleepHours: userProvider.totalSleepHours,
                totalDistance: userProvider.totalDistance,
                totalCalories: userProvider.totalCalories,
                avgHR: userProvider.avgHR,
                minHR: userProvider.minHR,
                maxHR: userProvider.maxHR,
              ),
            // Add more widgets here later
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------------------------
// -----------------------    Data PlaceHolder Child Widget ----------------------------------------------
// --------------------------------------------------------------------------------------------

class AppleKitDataPlaceholders extends StatelessWidget {
  final double totalSteps;
  final double totalSleepHours;
  final double totalDistance;
  final double totalCalories;

  final double avgHR;
  final double minHR;
  final double maxHR;

  // pass the bpms as well
  // the distance and steps seems like its wrong or not calculating properly for a day

  const AppleKitDataPlaceholders({
    required this.totalSteps,
    required this.totalSleepHours,
    required this.totalDistance,
    required this.totalCalories,
    required this.avgHR,
    required this.minHR,
    required this.maxHR,
    super.key,
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
            'assets/Apple_logo_white.svg.png',
            width: 48, // adjust path to match your asset folder
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
                      color: Color(0xFFFF6F61),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '$totalSteps',
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
                    Icon(Icons.bed, size: 32, color: Color(0xFFFF6F61)),
                    SizedBox(height: 8),
                    Text(
                      '$totalSleepHours',
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
                    Icon(Icons.place, size: 32, color: Color(0xFFFF6F61)),
                    SizedBox(height: 8),
                    Text(
                      '$totalDistance mi',
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
                      color: Color(0xFFFF6F61),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '$totalCalories',
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
                          '$minHR BPM',
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
                          color: Color(0xFFFF6F61),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '$avgHR BPM',
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
                          '$maxHR BPM',
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
            onPressed: userProvider.RevokeAppleAccess,
            child: Text('Revoke Apple Health Access'),
          ),
        ],
      ),
    );
  }
}
