import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static late final SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get locationEnabled => _prefs.getBool('locationEnabled') ?? true;
  static Future<void> setLocationEnabled(bool value) => _prefs.setBool('locationEnabled', value);

  static bool get pushNotifs => _prefs.getBool('pushNotifs') ?? true;
  static Future<void> setPushNotifs(bool value) => _prefs.setBool('pushNotifs', value);

  static bool get emailNotifs => _prefs.getBool('emailNotifs') ?? true;
  static Future<void> setEmailNotifs(bool value) => _prefs.setBool('emailNotifs', value);

  static bool get notificationsEnabled => _prefs.getBool('notificationsEnabled') ?? true;
  static Future<void> setNotificationsEnabled(bool value) => _prefs.setBool('notificationsEnabled', value);

  static String get languageCode => _prefs.getString('languageCode') ?? 'en';
  static Future<void> setLanguageCode(String value) => _prefs.setString('languageCode', value);

  static bool get isDarkMode => _prefs.getBool('isDarkMode') ?? false;
  static Future<void> setDarkMode(bool value) => _prefs.setBool('isDarkMode', value);
}
