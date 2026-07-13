import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isGuest = false;
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';

  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;
  bool get isAuthenticated => _isLoggedIn || _isGuest;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;

  void login(String name, String email) {
    _isLoggedIn = true;
    _isGuest = false;
    _userName = name;
    _userEmail = email;
    notifyListeners();
  }

  void loginAsGuest(String name, String phone) {
    _isLoggedIn = false;
    _isGuest = true;
    _userName = name;
    _userPhone = phone;
    _userEmail = '';
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _isGuest = false;
    _userName = '';
    _userEmail = '';
    _userPhone = '';
    notifyListeners();
  }
}
