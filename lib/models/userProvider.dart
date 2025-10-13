import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class UserProvider with ChangeNotifier {
  // This creates a private instance of your UserProfile model.
  UserProfile _profile = UserProfile();

  // This is a getter.
  // It lets other parts of your app read the _profile safely, without exposing it for direct modification.
  UserProfile get profile => _profile;

  // ------------------< Basic Info >------------------

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

  // Check if user needs to complete profile setup
  bool needsProfileSetup() {
    return _profile.firstTimeLogin || _profile.name.isEmpty;
  }
}
