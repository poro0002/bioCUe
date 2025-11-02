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
import 'dart:async';

class AppleHealthKit extends StatefulWidget {
  const AppleHealthKit({super.key});

  @override
  State<AppleHealthKit> createState() => _AppleHealthKitState();
}

class _AppleHealthKitState extends State<AppleHealthKit> {
  late bool
  appleAccess; // late` lets you defer initialization until `initState()`------ late means “I promise I’ll initialize this before I use it” its a promise essentially
  late bool hasAccess;

  double totalSteps = 0;
  double totalSleepHours = 0;
  double totalDistance = 0;
  double totalCalories = 0;

  double avgHR = 0;
  double minHR = 0;
  double maxHR = 0;

  @override
  void initState() {
    super.initState();

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    appleAccess = userProvider.profile.appleHealthAccess;
    hasAccess = appleAccess;

    if (hasAccess) {
      fetchHealthData(); // fetch the data if the hasAccess is already true
    }
  }

  // for steps loop through all the returned HealthDataType.STEPS data and add it to a total sum variable ?
  //for heartrrate go through all the values and calucalte the average, and as well get the lowest BPM and Highest and save those as well
  // total sum of HealthDataType.SLEEP_ASLEEP bvalues and add them all together to get a double type number (8.36 (like 8hr and 36min))
  // get the total of  HealthDataType.ACTIVE_ENERGY_BURNED, and add it to the total of HealthDataType.BASAL_ENERGY_BURNED, to get total calories burned
  // get the total sum of HealthDataType.DISTANCE_WALKING_RUNNING,

  void convertAppleKitData(List<HealthDataPoint> data) {
    double steps = 0;
    double sleep = 0;
    double distance = 0;
    double active = 0;
    double basal = 0;

    List<double> heartRates = [];

    for (var point in data) {
      if (point.value is! NumericHealthValue) continue;
      final value = (point.value as NumericHealthValue).numericValue;

      print('${point.type}: $value');

      switch (point.type) {
        case HealthDataType.STEPS:
          steps += value;
          break;
        case HealthDataType.HEART_RATE:
          heartRates.add(value.toDouble());
          break;
        case HealthDataType.SLEEP_ASLEEP:
          sleep += value / 3600; // seconds → hours
          break;
        case HealthDataType.ACTIVE_ENERGY_BURNED:
          active += value;
          break;
        case HealthDataType.BASAL_ENERGY_BURNED:
          basal += value;
          break;
        case HealthDataType.DISTANCE_WALKING_RUNNING:
          distance += value; // meters
          break;
        default:
          break;
      }
    }

    double avg = heartRates.isNotEmpty
        ? heartRates.reduce((a, b) => a + b) / heartRates.length
        : 0;
    double min = heartRates.isNotEmpty
        ? heartRates.reduce((a, b) => a < b ? a : b)
        : 0;
    double max = heartRates.isNotEmpty
        ? heartRates.reduce((a, b) => a > b ? a : b)
        : 0;

    double totalCals = active + basal;

    setState(() {
      totalSteps = steps;
      totalSleepHours = sleep;
      totalDistance = distance;
      totalCalories = totalCals;
      avgHR = avg;
      minHR = min;
      maxHR = max;
    });

    // print('Steps: ${steps.toStringAsFixed(0)}');
    // print('Sleep: ${sleep.toStringAsFixed(2)} hrs');
    // print('Distance: ${(distance / 1000).toStringAsFixed(2)} km');
    // print('Calories: ${totalCalories.toStringAsFixed(0)} kcal');
    // print(
    //   'Heart Rate: avg ${avg.toStringAsFixed(1)} bpm, min ${min.toStringAsFixed(0)}, max ${max.toStringAsFixed(0)}',
    // );
  }

  Future<void> fetchHealthData() async {
    final types = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.DISTANCE_WALKING_RUNNING,
      HealthDataType.BASAL_ENERGY_BURNED,
    ];

    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 1));

    final data = await Health().getHealthDataFromTypes(
      types: types,
      startTime: yesterday,
      endTime: now,
    );

    convertAppleKitData(data);
    print('Fetched ${data.length} health data points');
  }

  Future<void> grantAccess() async {
    final types = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.ACTIVE_ENERGY_BURNED, // kcal
      HealthDataType.DISTANCE_WALKING_RUNNING, // meters
      HealthDataType.BASAL_ENERGY_BURNED,
    ];

    // Check if permissions are already granted
    final hasPermissions = await Health().hasPermissions(types);

    if (hasPermissions != true) {
      final granted = await Health().requestAuthorization(types);
      if (!granted) {
        print('Permission denied');
        return;
      }
    }

    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 1));

    // this returns a list of health data points
    final data = await Health().getHealthDataFromTypes(
      types: types,
      startTime: yesterday,
      endTime: now,
    );
    setState(() {
      // here we need to set the appleHealthAccess profile bool to true && we need to update the supabase bool for that user
      hasAccess = true;

      Provider.of<UserProvider>(
        context,
        listen: false,
      ).setAppleAccess(hasAccess);
    });

    // update the corro users applehealthaccess bool in the supabase database so the state is saved

    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ?? '';
      final response = await http.post(
        Uri.parse(
          '${AppConfig.backendBaseUrl}/api/users/updateAppleHealthAccess',
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

    convertAppleKitData(data);
    print('Fetched ${data.length} health data points');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Apple Health")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!hasAccess) ...[
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

              SizedBox(height: 24),

              // Grant access button
              ElevatedButton(
                onPressed: () => grantAccess(),
                child: Text("Grant Access"),
              ),
            ],

            if (hasAccess)
              AppleKitDataPlaceholders(
                totalSteps: totalSteps,
                totalSleepHours: totalSleepHours,
                totalDistance: totalDistance,
                totalCalories: totalCalories,
                avgHR: avgHR,
                minHR: minHR,
                maxHR: maxHR,
              ),
            // Add more widgets here later
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
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
    final today = DateFormat.yMMMMd().format(DateTime.now());
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Today',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(today, style: TextStyle(color: Colors.white)),
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
                      '${(totalDistance / 1609.344).toStringAsFixed(2)} mi',
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
                          '$minHR',
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
                          '$avgHR',
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
                          '$maxHR',
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
