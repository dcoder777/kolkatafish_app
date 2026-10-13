import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  static const _keyLoggedIn = 'kf_logged_in';
  static const _keyGuest = 'kf_is_guest';
  static const _keyName = 'kf_user_name';
  static const _keyEmail = 'kf_user_email';
  static const _keyPhone = 'kf_user_phone';

  bool _isLoggedIn = false;
  bool _isGuest = false;
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';

  AuthProvider() {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool(_keyLoggedIn) ?? false;
      _isGuest = prefs.getBool(_keyGuest) ?? false;
      _userName = prefs.getString(_keyName) ?? '';
      _userEmail = prefs.getString(_keyEmail) ?? '';
      _userPhone = prefs.getString(_keyPhone) ?? '';
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyLoggedIn, _isLoggedIn);
      await prefs.setBool(_keyGuest, _isGuest);
      await prefs.setString(_keyName, _userName);
      await prefs.setString(_keyEmail, _userEmail);
      await prefs.setString(_keyPhone, _userPhone);
    } catch (_) {}
  }

  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;
  bool get isAuthenticated => _isLoggedIn || _isGuest;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;

  void login(String name, String email) {
    _isLoggedIn = true;
    _isGuest = false;
    _userName = name.trim().isEmpty ? nameFromEmail(email) : name.trim();
    _userEmail = email.trim();
    _persist();
    notifyListeners();
  }

  static String nameFromEmail(String email) {
    final local = email.trim().split('@').first.replaceAll(RegExp(r'[._-]+'), ' ').trim();
    if (local.isEmpty) return 'Fish Lover';
    return local
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  void loginAsGuest(String name, String phone) {
    _isLoggedIn = false;
    _isGuest = true;
    _userName = name;
    _userPhone = phone;
    _userEmail = '';
    _persist();
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _isGuest = false;
    _userName = '';
    _userEmail = '';
    _userPhone = '';
    _persist();
    notifyListeners();
  }

  void updateProfile({String? name, String? phone}) {
    if (name != null && name.trim().isNotEmpty) _userName = name.trim();
    if (phone != null) _userPhone = phone.trim();
    _persist();
    notifyListeners();
  }
}
