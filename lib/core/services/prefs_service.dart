import 'package:shared_preferences/shared_preferences.dart';

/// Petites préférences locales (avant connexion).
class PrefsService {
  static const _kOnboarding = 'onboarding_vu';

  static Future<bool> onboardingVu() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kOnboarding) ?? false;
  }

  static Future<void> marquerOnboardingVu() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOnboarding, true);
  }
}
