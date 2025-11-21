class UserProfile {
  // -----------------------------------------------------------------------------------------------
  // -------------------------------< Declare the variables >---------------------------------------
  // -----------------------------------------------------------------------------------------------

  // Basic Info
  String name;
  int age;
  String gender;
  double height; // in cm
  double weight; // in kg
  String diet;

  //log in
  bool isLoggedIn;
  String email;
  bool firstTimeLogin;
  bool appleHealthAccess;
  bool hasFitBitAccess;

  // Health Info
  List<String> selectedIllnesses;
  List<String> allergies;
  List<String> prescribedMedications;

  // Personality Traits
  double neuroticism;
  double openness;
  double conscientiousness;
  double extraversion;
  double agreeableness;

  // -----------------------------------------------------------------------------------------------
  // -------------------------------< Constructor >-------------------------------------------------
  // -----------------------------------------------------------------------------------------------

  UserProfile({
    this.name = '',
    this.age = 0,
    this.gender = '',
    this.height = 170.0,
    this.weight = 70.0,
    this.diet = '',
    this.selectedIllnesses = const [],
    this.allergies = const [],
    this.prescribedMedications = const [],
    this.neuroticism = 50.0,
    this.openness = 50.0,
    this.conscientiousness = 50.0,
    this.extraversion = 50.0,
    this.agreeableness = 50.0,
    this.isLoggedIn = false,
    this.email = '',
    this.firstTimeLogin = true,
    this.appleHealthAccess = false,
    this.hasFitBitAccess = false,
  });

  // -----------------------------------------------------------------------------------------------
  // -------------------------------< TO JSON >---------------------------------------
  // -----------------------------------------------------------------------------------------------

  // This method below converts your UserProfile object into a JSON-like map — basically a format that can be:

  //  Sent to a server (like Firebase or REST API)
  //  Saved locally (like in SharedPreferences or a file)
  //  Printed for debugging

  Map<String, dynamic> toJson() => {
    // dynamic means the values can be any type
    'name': name,
    'age': age,
    'gender': gender,
    'height': height,
    'weight': weight,
    'diet': diet,
    'selectedIllnesses': selectedIllnesses,
    'allergies': allergies,
    'prescribedMedications': prescribedMedications,
    'neuroticism': neuroticism,
    'openness': openness,
    'conscientiousness': conscientiousness,
    'extraversion': extraversion,
    'agreeableness': agreeableness,
    'isLoggedIn': isLoggedIn,
    'firstTimeLogin': firstTimeLogin,
    'email': email,
    'appleHealthAccess': appleHealthAccess,
    'hasFitBitAccess': hasFitBitAccess,
  };

  // -----------------------------------------------------------------------------------------------
  // -------------------------------< back to class code syntax >------------------------------------
  // ------------------------------------------------------------------------------------------------

  // factory means this constructor can return a custom instance (not just a default one)
  // fromJson(...) is a common naming convention for decoding JSON.

  // so after all of it is set, this makes it so it turns back into a class code that can be used in my app on the front end

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      height: (json['height'] as num?)?.toDouble() ?? 170.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 70.0,
      diet: json['diet'] ?? '',
      selectedIllnesses: List<String>.from(json['selectedIllnesses'] ?? []),
      allergies: List<String>.from(json['allergies'] ?? []),
      prescribedMedications: List<String>.from(
        json['prescribedMedications'] ?? [],
      ),
      neuroticism: (json['neuroticism'] as num?)?.toDouble() ?? 50.0,
      openness: (json['openness'] as num?)?.toDouble() ?? 50.0,
      conscientiousness:
          (json['conscientiousness'] as num?)?.toDouble() ?? 50.0,
      extraversion: (json['extraversion'] as num?)?.toDouble() ?? 50.0,
      agreeableness: (json['agreeableness'] as num?)?.toDouble() ?? 50.0,
      email: json['email'] ?? '',
      isLoggedIn: json['isLoggedIn'] ?? false,
      firstTimeLogin: json['firstTimeLogin'] ?? true,
      appleHealthAccess: json['appleHealthAccess'] ?? false,
      hasFitBitAccess: json['hasFitBitAccess'] ?? false,
    );
  }
}
