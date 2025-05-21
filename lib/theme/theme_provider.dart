import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _prefKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Get device setting if using system theme
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
  
  ThemeProvider() {
    _loadThemePreference();
  }
  
  Future<void> _loadThemePreference() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? themeModeString = prefs.getString(_prefKey);
    
    if (themeModeString != null) {
      if (themeModeString == 'light') {
        _themeMode = ThemeMode.light;
      } else if (themeModeString == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    }
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    switch (mode) {
      case ThemeMode.light:
        await prefs.setString(_prefKey, 'light');
        break;
      case ThemeMode.dark:
        await prefs.setString(_prefKey, 'dark');
        break;
      case ThemeMode.system:
        await prefs.setString(_prefKey, 'system');
        break;
    }
  }
}
