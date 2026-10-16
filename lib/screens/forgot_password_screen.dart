import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../utils/toast_helper.dart';

/// 3-Step in-app OTP password reset flow:
/// 1. Enter email -> calls POST /kolkatafish/v1/send-otp
/// 2. Enter 6-digit OTP -> calls POST /kolkatafish/v1/verify-otp
/// 3. Enter new password -> calls POST /kolkatafish/v1/reset-password
class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const Color _brandColor = Color(0xFFF55D2C);
  static const int _cooldownSeconds = 60;

  int _currentStep = 1; // 1: Email, 2: OTP, 3: New Password

  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _otpCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  final AuthService _auth = AuthService();

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  int _resendCooldown = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.trim().isNotEmpty) {
      _emailCtrl.text = widget.initialEmail!.trim();
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _auth.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendCooldown = _cooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Step 1: Send OTP
  // ---------------------------------------------------------------------------
  Future<void> _handleSendOtp({bool isResend = false}) async {
    final email = _emailCtrl.text.trim();
    if (!AuthService.isValidEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await _auth.sendResetOtp(email: email);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      _startCooldown();
      setState(() {
        _currentStep = 2;
        _errorMessage = null;
      });
      showSuccessToast(
        context,
        isResend ? 'New OTP sent to your email.' : '6-digit OTP sent to your email.',
      );
    } else {
      setState(() => _errorMessage = result.message);
      showErrorToast(context, result.message);
    }
  }

  // ---------------------------------------------------------------------------
  // Step 2: Verify OTP
  // ---------------------------------------------------------------------------
  Future<void> _handleVerifyOtp() async {
    final email = _emailCtrl.text.trim();
    final otp = _otpCtrl.text.trim();

    if (otp.length < 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit OTP.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await _auth.verifyResetOtp(email: email, otp: otp);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      setState(() {
        _currentStep = 3;
        _errorMessage = null;
      });
      showSuccessToast(context, 'OTP verified! Set your new password.');
    } else {
      setState(() => _errorMessage = result.message);
      showErrorToast(context, result.message);
    }
  }

  // ---------------------------------------------------------------------------
  // Step 3: Update Password
  // ---------------------------------------------------------------------------
  Future<void> _handleUpdatePassword() async {
    final email = _emailCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (pass.isEmpty) {
      setState(() => _errorMessage = 'Please enter a new password.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    if (pass != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await _auth.resetPasswordWithOtp(
      email: email,
      otp: otp,
      newPassword: pass,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      // Pop back to login screen with success
      Navigator.pop(context, true);
      showSuccessToast(
        context,
        'Password updated successfully! Please log in with your new password.',
      );
    } else {
      setState(() => _errorMessage = result.message);
      showErrorToast(context, result.message);
    }
  }

  static String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts[0].isEmpty) return email;
    final name = parts[0];
    final visible = name.length <= 2 ? name[0] : name.substring(0, 2);
    return '$visible****@${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Reset Password',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStepIndicator(),
              const SizedBox(height: 24),
              if (_currentStep == 1) _buildEmailStep(),
              if (_currentStep == 2) _buildOtpStep(),
              if (_currentStep == 3) _buildNewPasswordStep(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step Indicator Widget
  // ---------------------------------------------------------------------------
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepCircle(stepNum: 1, label: 'Email'),
        _stepConnector(isDone: _currentStep > 1),
        _stepCircle(stepNum: 2, label: 'OTP'),
        _stepConnector(isDone: _currentStep > 2),
        _stepCircle(stepNum: 3, label: 'Password'),
      ],
    );
  }

  Widget _stepCircle({required int stepNum, required String label}) {
    final bool isDone = _currentStep > stepNum;
    final bool isActive = _currentStep == stepNum;

    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? Colors.green.shade600
                : (isActive ? _brandColor : Colors.grey.shade200),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text(
                    '$stepNum',
                    style: GoogleFonts.poppins(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? _brandColor : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _stepConnector({required bool isDone}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16, left: 6, right: 6),
        color: isDone ? Colors.green.shade500 : Colors.grey.shade300,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1 View: Email
  // ---------------------------------------------------------------------------
  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _brandColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset_rounded, size: 48, color: _brandColor),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Forgot Password?',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your registered KolkataFish email. We will send a 6-digit OTP to verify your account.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailCtrl,
          enabled: !_loading,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleSendOtp(),
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'e.g. name@example.com',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _buildErrorBanner(_errorMessage!),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : () => _handleSendOtp(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Send OTP',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text(
            'Back to Login',
            style: GoogleFonts.poppins(color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2 View: OTP
  // ---------------------------------------------------------------------------
  Widget _buildOtpStep() {
    final email = _emailCtrl.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _brandColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_outlined, size: 48, color: _brandColor),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Enter 6-Digit OTP',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Code sent to ${_maskEmail(email)}',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _loading
                  ? null
                  : () => setState(() {
                        _currentStep = 1;
                        _errorMessage = null;
                      }),
              child: Text(
                'Change',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _brandColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _otpCtrl,
          enabled: !_loading,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 10,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '• • • • • •',
            hintStyle: GoogleFonts.poppins(letterSpacing: 6, color: Colors.grey.shade400),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) {
            if (val.length == 6) _handleVerifyOtp();
          },
        ),
        const SizedBox(height: 12),
        Center(
          child: _resendCooldown > 0
              ? Text(
                  'Resend code in $_resendCooldown s',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                )
              : TextButton.icon(
                  onPressed: _loading ? null : () => _handleSendOtp(isResend: true),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(
                    'Resend OTP',
                    style: GoogleFonts.poppins(
                      color: _brandColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _buildErrorBanner(_errorMessage!),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : () => _handleVerifyOtp(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Verify OTP',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3 View: New Password
  // ---------------------------------------------------------------------------
  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_user_outlined, size: 48, color: Colors.green.shade600),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Create New Password',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Your OTP is verified! Choose a strong password of at least 6 characters.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _passCtrl,
          enabled: !_loading,
          obscureText: _obscurePass,
          decoration: InputDecoration(
            labelText: 'New Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _confirmPassCtrl,
          enabled: !_loading,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _buildErrorBanner(_errorMessage!),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : () => _handleUpdatePassword(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Update Password',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(color: Colors.red.shade800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
