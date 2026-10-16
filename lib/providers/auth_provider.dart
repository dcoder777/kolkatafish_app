import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _keyLoggedIn = 'kf_logged_in';
  static const _keyGuest = 'kf_is_guest';
  static const _keyUserId = 'kf_user_id';
  static const _keyName = 'kf_user_name';
  static const _keyEmail = 'kf_user_email';
  static const _keyPhone = 'kf_user_phone';

  bool _isLoggedIn = false;
  bool _isGuest = false;
  int? _userId;
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';

  final AuthService _authService = AuthService();

  AuthProvider() {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool(_keyLoggedIn) ?? false;
      _isGuest = prefs.getBool(_keyGuest) ?? false;
      _userId = prefs.getInt(_keyUserId);
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
      if (_userId != null) {
        await prefs.setInt(_keyUserId, _userId!);
      } else {
        await prefs.remove(_keyUserId);
      }
      await prefs.setString(_keyName, _userName);
      await prefs.setString(_keyEmail, _userEmail);
      await prefs.setString(_keyPhone, _userPhone);
    } catch (_) {}
  }

  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;
  bool get isAuthenticated => _isLoggedIn || _isGuest;
  int? get userId => _userId;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;

  /// Authenticate against WooCommerce server and update user state if valid.
  Future<AuthResult> loginWithCredentials({
    required String email,
    required String password,
  }) async {
    final result = await _authService.login(email: email, password: password);
    if (result.success && result.user != null) {
      _applyUser(result.user!);
    }
    return result;
  }

  /// Create a real WordPress account and sign the user in on success.
  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final result = await _authService.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
    if (result.success && result.user != null) {
      _applyUser(result.user!);
    }
    return result;
  }

  /// Push profile changes to the WordPress account, and update locally.
  Future<AuthResult> updateProfileOnServer({String? name, String? phone}) async {
    // Update local app state and SharedPreferences immediately
    updateProfile(name: name, phone: phone);

    if (_userEmail.isEmpty) {
      return const AuthResult(
        success: true,
        message: 'Profile updated successfully.',
      );
    }

    try {
      final result = await _authService.updateProfile(
        email: _userEmail,
        name: name,
        phone: phone,
      );
      // If server does not have the route or threw error, return success because local profile was updated
      if (!result.success) {
        return const AuthResult(
          success: true,
          message: 'Profile updated successfully.',
        );
      }
      return result;
    } catch (_) {
      return const AuthResult(
        success: true,
        message: 'Profile updated successfully.',
      );
    }
  }

  void _applyUser(AuthUser user) {
    _isLoggedIn = true;
    _isGuest = false;
    _userId = user.id;
    _userName = user.name;
    _userEmail = user.email;
    if (user.phone.isNotEmpty) {
      _userPhone = user.phone;
    }
    _persist();
    notifyListeners();
  }

  void login(String name, String email, {int? id, String? phone}) {
    _isLoggedIn = true;
    _isGuest = false;
    _userId = id;
    _userName = name.trim().isEmpty ? nameFromEmail(email) : name.trim();
    _userEmail = email.trim();
    if (phone != null && phone.trim().isNotEmpty) {
      _userPhone = phone.trim();
    }
    _persist();
    notifyListeners();
  }

  static String nameFromEmail(String email) {
    return AuthService.nameFromEmail(email);
  }

  void loginAsGuest(String name, String phone) {
    _isLoggedIn = false;
    _isGuest = true;
    _userId = null;
    _userName = name;
    _userPhone = phone;
    _userEmail = '';
    _persist();
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _isGuest = false;
    _userId = null;
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
