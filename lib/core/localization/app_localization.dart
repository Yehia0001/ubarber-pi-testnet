import 'ar.dart';
import 'en.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalization extends ChangeNotifier {
  static final AppLocalization _instance = AppLocalization._internal();

  factory AppLocalization() => _instance;

  AppLocalization._internal() {
    _loadLanguage();
  }

  String _currentLang = 'ar';

  String get currentLang => _currentLang;

  final Map<String, Map<String, String>> _values = {
    'ar': ar,
    'en': en,
  };

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    _currentLang = prefs.getString('lang') ?? 'ar';

    notifyListeners();
  }

  Future<void> setLang(String lang) async {
    _currentLang = lang;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);

    notifyListeners();
  }

  String tr(String key) {
    return _values[_currentLang]?[key]
        ?? _values['ar']?[key]
        ?? key;
  }
}