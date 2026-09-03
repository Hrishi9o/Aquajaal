import 'package:flutter/material.dart';
import '../data/services/local_db_service.dart';

/// Provider for managing Theme Mode (Light / Dark)
class ThemeProvider with ChangeNotifier {
  late bool _isDarkMode;

  ThemeProvider() {
    _isDarkMode = LocalDbService.instance.getSettings().isDarkMode;
  }

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    final settings = LocalDbService.instance.getSettings();
    await LocalDbService.instance.saveSettings(
      settings.copyWith(isDarkMode: _isDarkMode),
    );
  }

  void setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();

    final settings = LocalDbService.instance.getSettings();
    await LocalDbService.instance.saveSettings(
      settings.copyWith(isDarkMode: _isDarkMode),
    );
  }
}
