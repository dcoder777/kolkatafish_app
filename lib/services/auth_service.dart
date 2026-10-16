import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Authenticated user representation.
class AuthUser {
  final int? id;
  final String name;
  final String email;
  final String phone;

  const AuthUser({
    this.id,
    required this.name,
    required this.email,
    this.phone = '',
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'email': email,
        'phone': phone,
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}'),
      name:
          (json['name'] ?? json['display_name'] ?? json['user_nicename'] ?? '')
              .toString(),
      email: (json['email'] ?? json['user_email'] ?? '').toString(),
      phone: (json['phone'] ?? json['billing_phone'] ?? '').toString(),
    );
  }
}

/// Result returned from an authentication attempt (login / password reset).
class AuthResult {
  final bool success;
  final String message;
  final AuthUser? user;

  /// Machine-readable failure code (e.g. 'rest_no_route' when the endpoint
  /// is not deployed on the WordPress site yet).
  final String? code;

  const AuthResult({
    required this.success,
    required this.message,
    this.user,
    this.code,
  });

  factory AuthResult.successResult(AuthUser user,
      [String message = 'Login successful']) {
    return AuthResult(success: true, message: message, user: user);
  }

  factory AuthResult.failureResult(String message, {String? code}) {
    return AuthResult(success: false, message: message, code: code);
  }
}

/// Internal exception carrying a user-friendly message.
class _AuthServiceException implements Exception {
  final String message;
  final String? code;
  const _AuthServiceException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Minimal response snapshot for the wp-login.php flows.
///
/// Holds `Set-Cookie` values as a list because the http package collapses
/// them into a single comma-joined header, which mangles cookies whose
/// expiry dates contain commas.
class _WpResponse {
  final int statusCode;
  final String location;
  final String body;
  final List<String> setCookies;

  const _WpResponse({
    required this.statusCode,
    required this.location,
    required this.body,
    this.setCookies = const [],
  });
}

/// Service for verifying credentials against KolkataFish WooCommerce / WordPress API.
class AuthService {
  static const String loginUrl =
      'https://kolkatafish.com/wp-json/kolkatafish/v1/login';
  static const String sendOtpUrl =
      'https://kolkatafish.com/wp-json/kolkatafish/v1/send-otp';
  static const String verifyOtpUrl =
      'https://kolkatafish.com/wp-json/kolkatafish/v1/verify-otp';
  static const String forgotPasswordUrl =
      'https://kolkatafish.com/wp-json/kolkatafish/v1/forgot-password';
  static const String resetPasswordUrl =
      'https://kolkatafish.com/wp-json/kolkatafish/v1/reset-password';
  static const String registerUrl =
      'https://kolkatafish.com/wp-json/kolkatafish/v1/register';
  static const String updateProfileUrl =
      'https://kolkatafish.com/wp-json/kolkatafish/v1/update-profile';

  /// WordPress core lost-password page (works without any custom endpoint).
  static const String webResetUrl =
      'https://kolkatafish.com/wp-login.php?action=lostpassword';

  /// Base URL of wp-login.php. The app drives WordPress core's own
  /// lost-password / reset-password flow over plain HTTP so the whole flow
  /// stays inside the app (no browser redirect, no custom plugin needed).
  static const String wpLoginUrl = 'https://kolkatafish.com/wp-login.php';

  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  /// Verify user credentials with KolkataFish WooCommerce endpoint.
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    final cleanPass = password;

    if (cleanEmail.isEmpty || cleanPass.isEmpty) {
      return AuthResult.failureResult('Email and password are required.');
    }

    try {
      final decoded = await _postJson(loginUrl, {
        'email': cleanEmail,
        'password': cleanPass,
      });

      final bool isSuccess = decoded['success'] == true;
      final String msg = decoded['message']?.toString() ??
          (isSuccess ? 'Login successful' : 'Invalid email or password.');

      if (isSuccess) {
        // Extract user information safely from any common response layout
        final dynamic rawUser =
            decoded['user'] ?? decoded['data'] ?? decoded['customer'];
        Map<String, dynamic> userMap = {};
        if (rawUser is Map<String, dynamic>) {
          userMap = rawUser;
        } else {
          userMap = decoded;
        }

        final String displayName = (userMap['display_name'] ??
                userMap['name'] ??
                userMap['first_name'] ??
                '')
            .toString()
            .trim();

        final String finalName =
            displayName.isNotEmpty ? displayName : nameFromEmail(cleanEmail);

        // Extract customer billing phone from any standard WooCommerce format
        final dynamic billingData =
            userMap['billing'] ?? userMap['billing_address'];
        String billingPhone = '';
        if (billingData is Map<String, dynamic>) {
          billingPhone = (billingData['phone'] ?? '').toString().trim();
        }

        final String userPhone = [
          userMap['billing_phone'],
          userMap['phone'],
          billingPhone,
          userMap['shipping_phone'],
          userMap['mobile'],
          userMap['contact_number'],
        ]
            .firstWhere(
              (p) => p != null && p.toString().trim().isNotEmpty,
              orElse: () => '',
            )
            .toString()
            .trim();

        final int? userId = userMap['id'] is int
            ? userMap['id']
            : int.tryParse(
                '${userMap['id'] ?? userMap['customer_id'] ?? userMap['user_id']}');

        final user = AuthUser(
          id: userId,
          name: finalName,
          email: cleanEmail,
          phone: userPhone,
        );

        return AuthResult.successResult(user, msg);
      }

      return AuthResult.failureResult(msg);
    } on _AuthServiceException catch (e) {
      return AuthResult.failureResult(e.message);
    }
  }

  /// Send a 6-digit password reset OTP to [email].
  Future<AuthResult> sendResetOtp({required String email}) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !isValidEmail(cleanEmail)) {
      return AuthResult.failureResult('Please enter a valid email address.');
    }

    try {
      final decoded = await _postJson(sendOtpUrl, {'email': cleanEmail});
      final bool isSuccess = decoded['success'] == true;
      final String msg = decoded['message']?.toString() ??
          (isSuccess ? 'OTP sent to your email.' : 'Could not send OTP.');

      if (isSuccess) {
        return AuthResult(success: true, message: msg);
      }
      return AuthResult.failureResult(msg);
    } on _AuthServiceException catch (e) {
      return AuthResult.failureResult(e.message);
    } catch (_) {
      return AuthResult.failureResult('Failed to send OTP. Please try again.');
    }
  }

  /// Verify the 6-digit [otp] sent to [email].
  Future<AuthResult> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    final cleanEmail = email.trim();
    final cleanOtp = otp.trim();

    if (cleanEmail.isEmpty || cleanOtp.isEmpty) {
      return AuthResult.failureResult('Email and OTP are required.');
    }

    try {
      final decoded = await _postJson(verifyOtpUrl, {
        'email': cleanEmail,
        'otp': cleanOtp,
      });

      final bool isSuccess = decoded['success'] == true;
      final String msg = decoded['message']?.toString() ??
          (isSuccess
              ? 'OTP verified successfully.'
              : 'Invalid or expired OTP.');

      if (isSuccess) {
        return AuthResult(success: true, message: msg);
      }
      return AuthResult.failureResult(msg);
    } on _AuthServiceException catch (e) {
      return AuthResult.failureResult(e.message);
    } catch (_) {
      return AuthResult.failureResult(
          'Failed to verify OTP. Please try again.');
    }
  }

  /// Reset account password using the verified [otp].
  Future<AuthResult> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final cleanEmail = email.trim();
    final cleanOtp = otp.trim();

    if (cleanEmail.isEmpty || cleanOtp.isEmpty) {
      return AuthResult.failureResult('Email and OTP are required.');
    }
    if (newPassword.length < 6) {
      return AuthResult.failureResult(
          'Password must be at least 6 characters.');
    }

    try {
      final decoded = await _postJson(resetPasswordUrl, {
        'email': cleanEmail,
        'otp': cleanOtp,
        'password': newPassword,
        'new_password': newPassword,
      });

      final bool isSuccess = decoded['success'] == true;
      final String msg = decoded['message']?.toString() ??
          (isSuccess
              ? 'Password updated successfully. You can now log in.'
              : 'Failed to update password.');

      if (isSuccess) {
        return AuthResult(success: true, message: msg);
      }
      return AuthResult.failureResult(msg);
    } on _AuthServiceException catch (e) {
      return AuthResult.failureResult(e.message);
    } catch (_) {
      return AuthResult.failureResult(
          'Failed to update password. Please try again.');
    }
  }

  /// Ask WordPress to email a password reset link to [email].
  ///
  /// Drives WordPress core's own lost-password form over HTTP so the request
  /// stays inside the app. The server answers with a clear error when no
  /// account uses that address, so the UI can tell the user before an email
  /// is (not) sent.
  Future<AuthResult> forgotPassword({required String email}) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty || !isValidEmail(cleanEmail)) {
      return AuthResult.failureResult('Please enter a valid email address.');
    }

    try {
      final res = await _postForm(
        '$wpLoginUrl?action=lostpassword',
        {
          'user_login': cleanEmail,
          'redirect_to': '',
          'wp-submit': 'Get New Password',
        },
      ).timeout(const Duration(seconds: 30));

      final String body = res.body;
      final String? wpError = _extractWpError(body);

      if (wpError != null) {
        final lowered = wpError.toLowerCase();
        if (lowered.contains('no account with that username or email') ||
            lowered.contains('invalid username or email')) {
          return AuthResult.failureResult(
            'No KolkataFish account found with this email address.',
            code: 'no_account',
          );
        }
        if (lowered.contains('too many') || lowered.contains('attempt')) {
          return AuthResult.failureResult(
            'Too many reset attempts. Please wait a few minutes and try again.',
          );
        }
        return AuthResult.failureResult(wpError);
      }

      // WordPress answers a successful request with a 302 to
      // wp-login.php?checkemail=confirm. Any other 200 response means the
      // form was re-rendered, which only happens with an error attached.
      final String loc = res.location;
      final bool confirmed = loc.contains('checkemail=confirm') ||
          (res.statusCode == 200 && body.contains('checkemail=confirm'));

      if (confirmed) {
        return const AuthResult(
          success: true,
          message:
              'If an account exists for this email, a password reset link has been sent.',
        );
      }

      return AuthResult.failureResult(
        'Could not send the reset link right now. Please try again later.',
      );
    } on TimeoutException {
      return const AuthResult(
          success: false,
          message:
              'Connection timed out. Please check your internet connection.');
    } on SocketException {
      return const AuthResult(
          success: false,
          message: 'Network error. Unable to reach KolkataFish server.');
    } catch (_) {
      return const AuthResult(
          success: false, message: 'Something went wrong. Please try again.');
    }
  }

  /// Set a new password using the reset key from the email link.
  ///
  /// Replays WordPress core's `wp-login.php?action=rp` flow exactly as a
  /// browser would:
  ///
  /// 1. GET `action=rp&key=K&login=L`. Core does **not** validate the key
  ///    here; it just sets the `wp-resetpass-{COOKIEHASH}` cookie to
  ///    `login:key` and 302s to `action=rp`.
  /// 2. GET `action=rp` carrying that cookie. Core now calls
  ///    `check_password_reset_key()`. A bad key yields a **302 with an empty
  ///    body** to `action=lostpassword&error=invalidkey` (or `expiredkey`),
  ///    so the redirect target — not the body — is what must be inspected.
  ///    A good key renders the form.
  /// 3. POST `action=resetpass` with `pass1`, `pass2`, `rp_key`, `pw_weak`
  ///    and the same cookie. Core requires `hash_equals($rp_key, $_POST['rp_key'])`,
  ///    where `$rp_key` is the key parsed back out of the cookie.
  ///    Success renders a page containing "Your password has been reset."
  ///    and exits (no redirect).
  Future<AuthResult> resetPassword({
    required String key,
    required String login,
    required String newPassword,
  }) async {
    final cleanKey = key.trim();
    final cleanLogin = login.trim();

    if (cleanKey.isEmpty || cleanLogin.isEmpty) {
      return AuthResult.failureResult('Reset key and email are required.');
    }
    if (newPassword.length < 8) {
      return AuthResult.failureResult(
          'Password must be at least 8 characters.');
    }

    final cookies = <String, String>{};

    try {
      // Step 1: open the reset link. Core sets the wp-resetpass cookie and
      // redirects to action=rp. (The key is not validated on this request.)
      final step1 = await _getWithCookies(
        Uri.parse('$wpLoginUrl?action=rp')
            .replace(queryParameters: {'key': cleanKey, 'login': cleanLogin}),
        cookies,
      ).timeout(const Duration(seconds: 30));
      _absorbCookies(cookies, step1);

      // Step 2: load the reset form. Core validates the key here. On failure
      // it 302s away with an EMPTY body, so the Location header is the only
      // signal.
      final String step1Loc = step1.location;
      final Uri formUri = step1Loc.isEmpty
          ? Uri.parse('$wpLoginUrl?action=rp')
          : Uri.parse(step1Loc.startsWith('http')
              ? step1Loc
              : 'https://kolkatafish.com$step1Loc');
      final step2 = await _getWithCookies(formUri, cookies)
          .timeout(const Duration(seconds: 30));
      _absorbCookies(cookies, step2);

      final String step2Loc = step2.location;
      if (step2.statusCode == 302 &&
          (step2Loc.contains('invalidkey') ||
              step2Loc.contains('expiredkey'))) {
        return AuthResult.failureResult(
          'This reset link is invalid or has expired. Please request a new one.',
          code: step2Loc.contains('expiredkey') ? 'expired_key' : 'invalid_key',
        );
      }
      // Also cover a 200 that still surfaces the error in the page.
      if (step2.body.contains('invalidkey') ||
          step2.body.contains('expiredkey')) {
        return AuthResult.failureResult(
          'This reset link is invalid or has expired. Please request a new one.',
          code:
              step2.body.contains('expiredkey') ? 'expired_key' : 'invalid_key',
        );
      }
      final String? formError = _extractWpError(step2.body);
      if (formError != null) {
        return AuthResult.failureResult(formError);
      }
      if (step2.body.isEmpty || !step2.body.contains('name="pass1"')) {
        return AuthResult.failureResult(
          'This reset link is invalid or has expired. Please request a new one.',
          code: 'invalid_key',
        );
      }

      // The form's rp_key is the same key from the email (core compares it to
      // the value parsed out of the cookie), so use it if present, else the
      // key we were given.
      final String rpKey = RegExp(r'name="rp_key"\s+value="([^"]*)"')
              .firstMatch(step2.body)
              ?.group(1) ??
          cleanKey;

      // Step 3: submit the new password.
      final step3 = await _postForm(
        '$wpLoginUrl?action=resetpass',
        {
          'pass1': newPassword,
          'pass2': newPassword,
          'rp_key': rpKey,
          'pw_weak': 'on',
          'wp-submit': 'Save Password',
        },
        cookies: cookies,
      ).timeout(const Duration(seconds: 30));
      _absorbCookies(cookies, step3);

      final String resultBody = step3.body;
      if (resultBody.contains('Your password has been reset')) {
        return const AuthResult(
            success: true, message: 'Your password has been updated.');
      }

      final String? resultError = _extractWpError(resultBody);
      if (resultError != null) {
        return AuthResult.failureResult(resultError);
      }

      // A redirect back to the login screen also signals success in some
      // configurations.
      if (step3.statusCode == 302 && step3.location.contains('login')) {
        return const AuthResult(
            success: true, message: 'Your password has been updated.');
      }

      return AuthResult.failureResult(
        'Could not update the password. Please try again or request a new link.',
      );
    } on TimeoutException {
      return const AuthResult(
          success: false,
          message:
              'Connection timed out. Please check your internet connection.');
    } on SocketException {
      return const AuthResult(
          success: false,
          message: 'Network error. Unable to reach KolkataFish server.');
    } catch (_) {
      return const AuthResult(
          success: false, message: 'Something went wrong. Please try again.');
    }
  }

  /// Pull the human-readable message out of a wp-login.php error div.
  static String? _extractWpError(String html) {
    final match = RegExp(
      r'<div id="login_error"[^>]*>(.*?)</div>',
      dotAll: true,
    ).firstMatch(html);
    if (match == null) return null;
    final raw = match
        .group(1)!
        .replaceAll(RegExp(r'<br\s*/?>'), ' ')
        .replaceAll(RegExp(r'</?p[^>]*>'), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), '');
    final text = raw
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#8217;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return text.isEmpty ? null : text;
  }

  /// GET [url], carrying [cookies], without following redirects automatically.
  ///
  /// Uses dart:io so individual `Set-Cookie` headers are available (the http
  /// package folds them into one comma-joined string, which corrupts cookie
  /// values that contain commas, e.g. expiry dates).
  Future<_WpResponse> _getWithCookies(
      Uri uri, Map<String, String> cookies) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 25);
    try {
      final req = await client.getUrl(uri);
      req.followRedirects = false;
      req.headers
          .set(HttpHeaders.userAgentHeader, 'KolkataFish/1.0 (Flutter App)');
      req.headers
          .set(HttpHeaders.acceptHeader, 'text/html,application/xhtml+xml');
      if (cookies.isNotEmpty) {
        req.headers.set(HttpHeaders.cookieHeader, _cookieHeader(cookies));
      }
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      return _WpResponse(
        statusCode: res.statusCode,
        location: res.headers.value(HttpHeaders.locationHeader) ?? '',
        body: body,
        setCookies: [
          for (final c in res.cookies) '${c.name}=${c.value}',
        ],
      );
    } finally {
      client.close(force: true);
    }
  }

  /// POST form fields to [url], optionally carrying [cookies].
  Future<_WpResponse> _postForm(
    String url,
    Map<String, String> fields, {
    Map<String, String>? cookies,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 25);
    try {
      final req = await client.postUrl(Uri.parse(url));
      req.followRedirects = false;
      req.headers.contentType =
          ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8');
      req.headers
          .set(HttpHeaders.userAgentHeader, 'KolkataFish/1.0 (Flutter App)');
      req.headers
          .set(HttpHeaders.acceptHeader, 'text/html,application/xhtml+xml');
      if (cookies != null && cookies.isNotEmpty) {
        req.headers.set(HttpHeaders.cookieHeader, _cookieHeader(cookies));
      }
      req.write(Uri(queryParameters: fields).query);
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      return _WpResponse(
        statusCode: res.statusCode,
        location: res.headers.value(HttpHeaders.locationHeader) ?? '',
        body: body,
        setCookies: [
          for (final c in res.cookies) '${c.name}=${c.value}',
        ],
      );
    } finally {
      client.close(force: true);
    }
  }

  /// Merge `Set-Cookie` values from [res] into [cookies].
  ///
  /// WordPress deletes a cookie by re-sending it with a blank value and an
  /// expiry in the past; treat blank/`%20`/`deleted` values as removal.
  static void _absorbCookies(Map<String, String> cookies, _WpResponse res) {
    for (final String c in res.setCookies) {
      final int eq = c.indexOf('=');
      if (eq <= 0) continue;
      final String name = c.substring(0, eq).trim();
      final String value = c.substring(eq + 1).trim();
      if (name.isEmpty) continue;
      final bool blank = value.isEmpty ||
          value == 'deleted' ||
          value == '%20' ||
          value.replaceAll('%20', '').trim().isEmpty;
      if (blank) {
        cookies.remove(name);
      } else {
        cookies[name] = value;
      }
    }
  }

  static String _cookieHeader(Map<String, String> cookies) =>
      cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

  /// Legacy REST-backed forgot-password call (used only if the custom
  /// endpoint is ever deployed; kept for compatibility).
  Future<AuthResult> forgotPasswordRest({required String email}) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty || !isValidEmail(cleanEmail)) {
      return AuthResult.failureResult('Please enter a valid email address.');
    }

    try {
      final decoded = await _postJson(forgotPasswordUrl, {'email': cleanEmail});

      final bool isSuccess = decoded['success'] == true;
      final String msg = decoded['message']?.toString() ??
          (isSuccess
              ? 'If an account exists for this email, a password reset link has been sent.'
              : 'Could not send the reset link. Please try again.');

      return AuthResult(success: isSuccess, message: msg);
    } on _AuthServiceException catch (e) {
      return AuthResult.failureResult(e.message, code: e.code);
    }
  }

  /// Create a real WordPress + WooCommerce account.
  ///
  /// On success the response contains the created user, so the caller can
  /// sign in immediately with the same data as a normal login.
  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();
    final cleanPhone = phone.trim();

    if (cleanName.isEmpty) {
      return AuthResult.failureResult('Please enter your full name.');
    }
    if (!isValidEmail(cleanEmail)) {
      return AuthResult.failureResult('Please enter a valid email address.');
    }
    if (password.length < 8) {
      return AuthResult.failureResult(
          'Password must be at least 8 characters.');
    }

    try {
      final decoded = await _postJson(registerUrl, {
        'name': cleanName,
        'email': cleanEmail,
        'phone': cleanPhone,
        'password': password,
      });

      final bool isSuccess = decoded['success'] == true;
      final String msg = decoded['message']?.toString() ??
          (isSuccess
              ? 'Account created successfully.'
              : 'Could not create the account.');

      if (isSuccess) {
        final dynamic rawUser = decoded['user'];
        final Map<String, dynamic> userMap =
            rawUser is Map<String, dynamic> ? rawUser : decoded;

        final String displayName =
            (userMap['display_name'] ?? userMap['name'] ?? cleanName)
                .toString()
                .trim();

        final String userPhone =
            (userMap['phone'] ?? cleanPhone).toString().trim();

        final int? userId = userMap['id'] is int
            ? userMap['id']
            : int.tryParse('${userMap['id'] ?? ''}');

        return AuthResult.successResult(
          AuthUser(
            id: userId,
            name: displayName.isNotEmpty ? displayName : cleanName,
            email: cleanEmail,
            phone: userPhone,
          ),
          msg,
        );
      }

      return AuthResult.failureResult(msg, code: decoded['code']?.toString());
    } on _AuthServiceException catch (e) {
      return AuthResult.failureResult(e.message, code: e.code);
    }
  }

  /// Update the display name / phone on the WordPress account.
  Future<AuthResult> updateProfile({
    required String email,
    String? name,
    String? phone,
  }) async {
    final cleanEmail = email.trim();
    if (!isValidEmail(cleanEmail)) {
      return AuthResult.failureResult('Your account email is not valid.');
    }

    try {
      final decoded = await _postJson(updateProfileUrl, {
        'email': cleanEmail,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      });

      final bool isSuccess = decoded['success'] == true;
      final String msg = decoded['message']?.toString() ??
          (isSuccess ? 'Profile updated.' : 'Could not update the profile.');

      return AuthResult(success: isSuccess, message: msg);
    } on _AuthServiceException catch (e) {
      return AuthResult.failureResult(e.message, code: e.code);
    }
  }

  /// POST [url] with a JSON body and decode the JSON response.
  Future<Map<String, dynamic>> _postJson(
    String url,
    Map<String, dynamic> body,
  ) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'KolkataFish/1.0 (Flutter App)',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw const _AuthServiceException(
          'Connection timed out. Please check your internet connection.');
    } on SocketException {
      throw const _AuthServiceException(
          'Network error. Unable to reach KolkataFish server.');
    }

    if (response.statusCode >= 300 && response.statusCode < 400) {
      final loc = response.headers['location'] ?? '';
      if (loc.contains('password-detection') || loc.contains('action=')) {
        throw const _AuthServiceException(
            'Security verification required on your account. Please update the WordPress login snippet.');
      }
      throw const _AuthServiceException(
          'Unexpected redirect from server. Please try again.');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const _AuthServiceException(
          'Unexpected server response. Please try again.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const _AuthServiceException(
          'Unexpected server response. Please try again.');
    }

    // Route not registered yet on the WordPress site (WordPress returns 404 with code 'rest_no_route').
    if (decoded['code']?.toString() == 'rest_no_route' ||
        (response.statusCode == 404 && decoded['message'] == null)) {
      throw const _AuthServiceException(
          'This service is temporarily unavailable on the server. Please try again later or contact support.',
          code: 'rest_no_route');
    }

    return decoded;
  }

  /// Basic email shape check (full validation happens server-side).
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$').hasMatch(email.trim());
  }

  /// Extracts a human-friendly name from an email address (e.g. john.doe@... -> John Doe).
  static String nameFromEmail(String email) {
    final local =
        email.trim().split('@').first.replaceAll(RegExp(r'[._-]+'), ' ').trim();
    if (local.isEmpty) return 'Customer';
    return local
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  void dispose() {
    _client.close();
  }
}
