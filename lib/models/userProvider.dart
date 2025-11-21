import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'package:health/health.dart';
import 'dart:async';
import '../config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/home_widgets/subScreens/fitBitKit.dart';

class UserProvider with ChangeNotifier {
  // This creates a private instance of your UserProfile model.
  UserProfile _profile = UserProfile();

  // This is a getter.
  // It lets other parts of your app read the _profile safely, without exposing it for direct modification.
  UserProfile get profile => _profile;

  // ------------------< Restore User Session >------------------

  Future<void> restoreUserProfile() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    final userId = session.user.id;

    final response = await Supabase.instance.client
        .from('users')
        .select()
        .eq('uuid', userId)
        .single();

    if (response != null) {
      _profile.email = response['email'];
      _profile.hasFitBitAccess = response['fitbitaccess'] ?? false;
      _profile.appleHealthAccess = response['applehealthaccess'] ?? false;
      // any other fields you need
      notifyListeners();
    }
  }

  // ------------------< FitBit Functions >------------------

  double fitBitTotalSteps = 0;
  double fitBitTotalSleepHours = 0;
  double fitBitTotalDistance = 0;
  double fitBitTotalCalories = 0;

  double fitBitAvgHR = 0;
  double fitBitMinHR = 0;
  double fitBitMaxHR = 0;

  // convert incoming data function

  // fetchFitbitData function

  void fetchFitBitData(BuildContext context) async {
    isLoading = true;
    notifyListeners();
    print('is this running ?');

    final email = _profile.email;

    // ----------------------< hit the fetchFitBitData backend point >-------------------------------
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.backendBaseUrl}/api/fitBit/fetchFitBitData'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'appleHealthAccess': true}),
      );

      // write base code error handling for each process
      // once the fitbit api data is successfully fetched and sent back to here from the backend
      // save it to those variable states above ( you will need to see if you have to write a converter function for the data )

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Successfully fetched the users fitbit data: $data');

        // ----------------------< convert the data >------------------------
        final activitySummary = data['activity']?['summary'];
        final sleepSummary = data['sleep']?['summary'];
        final heartData = data['heartRate'];
        final calories = data['calories'];

        // to use list methods you need to make it a list so firstWhere() will be valid
        final distances = List<Map<String, dynamic>>.from(
          activitySummary?['distances'] ?? [],
        );

        fitBitTotalSteps = (activitySummary?['steps'] ?? 0).toDouble();

        fitBitTotalSleepHours =
            ((sleepSummary?['totalMinutesAsleep'] ?? 0).toDouble()) / 60;

        fitBitTotalDistance =
            (distances.firstWhere(
                      (d) => d['activity'] == 'total',
                      orElse: () => {'distance': 0},
                    )['distance'] ??
                    0)
                .toDouble();
        fitBitTotalCalories = (calories ?? 0).toDouble();

        print('$fitBitTotalSteps');

        // average min, max heartrate data convert functionality

        final intraday =
            heartData['activities-heart-intraday']?['dataset']
                as List<dynamic>?;

        // If the user didn’t wear their Fitbit or it didn’t sync intraday heart rate, this line will throw:
        if (intraday != null && intraday.isNotEmpty) {
          final values = intraday.map((d) => d['value'] as num).toList();

          fitBitAvgHR = values.reduce((a, b) => a + b) / values.length;
          fitBitMinHR = values.reduce((a, b) => a < b ? a : b).toDouble();
          fitBitMaxHR = values.reduce((a, b) => a > b ? a : b).toDouble();
        } else {
          fitBitAvgHR = 0;
          fitBitMinHR = 0;
          fitBitMaxHR = 0;
        }
        isLoading = false;
        notifyListeners();
      }
      // ----------------------------< if the user needs to reauth >-----------------------------
      else if (response.statusCode == 401 &&
          response.body.contains('needsReauth')) {
        showDialog(
          // show a prompt dialogue so the user knows what needs to be done before redirecting to fitbit sync again
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Reconnect Fitbit'),
            content: const Text(
              'Your Fitbit connection has expired. Please reauthorize to continue syncing your data.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(
                  ctx,
                ).pop(), // close the dialogue and dont do anything
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(
                    ctx,
                  ).pop(); // closes the dialogue making it so the rest of redirect code can run
                  final authUrl =
                      'https://www.fitbit.com/oauth2/authorize?response_type=code&client_id=23TPRM&redirect_uri=https%3A%2F%2Fungelatinized-disharmoniously-lenora.ngrok-free.dev%2Fapi%2FfitBit%2FhandleFitBitCallback&scope=activity%20sleep%20heartrate%20profile&expires_in=604800&state=${_profile.email}';

                  final Uri url = Uri.parse(authUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    print('Failed to launch Fitbit auth URL');
                  }
                },
                child: const Text('Reconnect'),
              ),
            ],
          ),
        );
      }
      // ----------------------------< fetch failure catch >-----------------------------
      else {
        print('Failed to update FitBitAccess bool: ${response.body}');
      }
    } catch (e) {
      print(
        'there was an issue trying to fetch fitbit meta data for from the user provider $e',
      );
    }
  }

  // --------------------------------------------< Revoke Fitbit Access function >------------------------------------------------------
  void RevokeFitBitAccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ?? '';
      final response = await http.post(
        Uri.parse('${AppConfig.backendBaseUrl}/api/fitBit/updateFitBitAccess'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'fitBitAccess': false}),
      );

      //  we need to write functionality on the backend that deletes the users access token
      // we also need to revoke form the api via POST https://api.fitbit.com/oauth2/revoke <-- maybe add this into the  updateFitBitAccess endpoint

      if (response.statusCode == 200) {
        print('Successfully updated fitbitAccess in Supabase');
        _profile.hasFitBitAccess = false;
        notifyListeners();
      } else {
        print('Failed to update fitbitAccess: ${response.body}');
      }
    } catch (e) {
      print('Error updating fitbitAccess: $e');
    }
  }

  // ------------------< Apple Health Kit Functions >------------------
  bool get hasAppleAccess => _profile.appleHealthAccess;

  bool isLoading = true;

  double totalSteps = 0;
  double totalSleepHours = 0;
  double totalDistance = 0;
  double totalCalories = 0;

  double avgHR = 0;
  double minHR = 0;
  double maxHR = 0;

  // these below are the final values so they can be accessed when the user does a journal entry later on
  // langchain will have the final values
  // these getters point to the final variable values in the convert function

  double get steps => totalSteps;
  double get sleepHours => totalSleepHours;
  double get distance => totalDistance;
  double get calories => totalCalories;

  double get averageHR => avgHR;
  double get minimumHR => minHR;
  double get maximumHR => maxHR;

  // --------------------------------------------< Fetch Health Data Function >------------------------------------------------------

  Future<void> fetchHealthData() async {
    isLoading = true;
    notifyListeners();

    final types = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.DISTANCE_WALKING_RUNNING,
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

    final now = DateTime.now();
    final startTime = now.subtract(
      Duration(days: 2),
    ); // include yesterday// or Duration(hours: 24)

    final data = await Health().getHealthDataFromTypes(
      types: types,
      startTime: startTime,
      endTime: now,
    );

    convertAppleKitData(data);
    print('Fetched ${data.length} health data points');

    isLoading = false;
    notifyListeners();
  }

  // --------------------------------------------< Convert Apple Data Function >------------------------------------------------------

  void convertAppleKitData(List<HealthDataPoint> data) {
    // locals that get converted and sanitized and then will be = to the global vars above
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

    totalSteps = steps.roundToDouble();
    totalSleepHours = sleep;
    totalDistance = double.parse((distance * 0.000621371).toStringAsFixed(2));
    totalCalories = totalCals.roundToDouble();
    avgHR = avg.roundToDouble();
    minHR = min;
    maxHR = max;

    notifyListeners();

    // print('Steps: ${steps.toStringAsFixed(0)}');
    // print('Sleep: ${sleep.toStringAsFixed(2)} hrs');
    // print('Distance: ${(distance / 1000).toStringAsFixed(2)} km');
    // print('Calories: ${totalCalories.toStringAsFixed(0)} kcal');
    // print(
    //   'Heart Rate: avg ${avg.toStringAsFixed(1)} bpm, min ${min.toStringAsFixed(0)}, max ${max.toStringAsFixed(0)}',
    // );
  }

  // --------------------------------------------< Revoke Apple Access function >------------------------------------------------------

  void RevokeAppleAccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ?? '';
      final response = await http.post(
        Uri.parse(
          '${AppConfig.backendBaseUrl}/api/appleHealth/updateAppleHealthAccess',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'appleHealthAccess': false}),
      );

      if (response.statusCode == 200) {
        print('Successfully updated appleHealthAccess in Supabase');
        _profile.appleHealthAccess = false;
        notifyListeners();
      } else {
        print('Failed to update appleHealthAccess: ${response.body}');
      }
    } catch (e) {
      print('Error updating appleHealthAccess: $e');
    }
  }

  // ------------------< Reusable Functions >------------------

  void setName(String name) {
    _profile.name = name;
    print('Name updated to: ${_profile.name}');
    notifyListeners();
  }

  void setAge(int age) {
    _profile.age = age;
    print('Age updated to: ${_profile.age}');
    notifyListeners();
  }

  void setGender(String gender) {
    _profile.gender = gender;
    print('Gender updated to: ${_profile.gender}');
    notifyListeners();
  }

  void setHeight(double height) {
    _profile.height = height;
    print('Height updated to: ${_profile.height}');
    notifyListeners();
  }

  void setWeight(double weight) {
    _profile.weight = weight;
    print('Weight updated to: ${_profile.weight}');
    notifyListeners();
  }

  void setDiet(String diet) {
    _profile.diet = diet;
    print('Diet updated to: ${_profile.diet}');
    notifyListeners();
  }

  // ------------------< Health Info >------------------

  void setSelectedIllnesses(List<String> illnesses) {
    _profile.selectedIllnesses = illnesses;
    print('Selected illnesses updated to: ${_profile.selectedIllnesses}');
    notifyListeners();
  }

  void setAllergies(List<String> allergies) {
    _profile.allergies = allergies;
    print('Allergies updated to: ${_profile.allergies}');
    notifyListeners();
  }

  void setPrescribedMedications(List<String> medications) {
    _profile.prescribedMedications = medications;
    print(
      'Prescribed medications updated to: ${_profile.prescribedMedications}',
    );
    notifyListeners();
  }

  // ------------------< Personality Traits >------------------

  void setNeuroticism(double value) {
    _profile.neuroticism = value;
    print('Neuroticism updated to: ${_profile.neuroticism}');
    notifyListeners();
  }

  void setOpenness(double value) {
    _profile.openness = value;
    print('Openness updated to: ${_profile.openness}');
    notifyListeners();
  }

  void setConscientiousness(double value) {
    _profile.conscientiousness = value;
    print('Conscientiousness updated to: ${_profile.conscientiousness}');
    notifyListeners();
  }

  void setExtraversion(double value) {
    _profile.extraversion = value;
    print('Extraversion updated to: ${_profile.extraversion}');
    notifyListeners();
  }

  void setAgreeableness(double value) {
    _profile.agreeableness = value;
    print('Agreeableness updated to: ${_profile.agreeableness}');
    notifyListeners();
  }

  void setEmail(String email) {
    profile.email = email;
    notifyListeners();
  }

  // ------------------< Bulk Update >------------------

  void updateProfile(UserProfile newProfile) {
    _profile = newProfile;
    print('Profile updated: ${_profile.toJson()}');
    notifyListeners();
  }

  void resetProfile() {
    _profile = UserProfile(); // resets to default values
    print('Profile reset to default values');
    notifyListeners();
  }

  // ------------------< Authentication >------------------

  void login(String userEmail) {
    _profile.isLoggedIn = true;
    _profile.email = userEmail;
    print('isLoggedIn updated to: ${_profile.isLoggedIn}');
    print('email updated to: ${_profile.email}');
    notifyListeners();
  }

  void logout() {
    _profile.isLoggedIn = false;
    _profile.email = '';
    print('isLoggedIn updated to: ${_profile.isLoggedIn}');
    print('email updated to: ${_profile.email}');

    // Note: Don't reset firstTimeLogin on logout
    notifyListeners();
  }

  void completeFirstTimeSetup() {
    _profile.firstTimeLogin = false;
    print('firstTimeLogin var set to: ${_profile.firstTimeLogin}');
    notifyListeners();
  }

  void setAppleAccess(bool value) {
    _profile.appleHealthAccess = value;
    print('apple health access set to: ${_profile.appleHealthAccess}');
    notifyListeners();
  }

  void setFitBitAccess(bool value) {
    _profile.hasFitBitAccess = value;
    print('fit bit access set to: ${_profile.hasFitBitAccess}');
    notifyListeners();
  }

  // Check if user needs to complete profile setup
  bool needsProfileSetup() {
    return _profile.firstTimeLogin || _profile.name.isEmpty;
  }
}
