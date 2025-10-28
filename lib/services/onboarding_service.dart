import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService extends ChangeNotifier {
  static OnboardingService? _instance;
  static OnboardingService get instance => _instance ??= OnboardingService._();

  OnboardingService._();

  late SharedPreferences _prefs;
  bool _initialized = false;
  static const String _onboardingKey = 'has_completed_onboarding';

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  bool shouldShowOnboarding() {
    if (!_initialized) {
      throw Exception(
          'OnboardingService not initialized. Call initialize() first.');
    }
    final value = _prefs.getBool(_onboardingKey);
    // If null (never set), default to showing onboarding (true).
    return value == null ? true : !value;
  }

  Future<void> completeOnboarding() async {
    if (!_initialized) {
      throw Exception(
          'OnboardingService not initialized. Call initialize() first.');
    }
    await _prefs.setBool(_onboardingKey, true);
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    if (!_initialized) {
      throw Exception(
          'OnboardingService not initialized. Call initialize() first.');
    }
    await _prefs.remove(_onboardingKey);
    notifyListeners();
  }
}
