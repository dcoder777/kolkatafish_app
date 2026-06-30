import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ToastType { success, error, info, warning }

void showAppToast(
  BuildContext context,
  String message, {
  ToastType type = ToastType.info,
  Duration duration = const Duration(seconds: 2),
}) {
  final (icon, color) = switch (type) {
    ToastType.success => (Icons.check_circle_outline, const Color(0xFF4CAF50)),
    ToastType.error => (Icons.error_outline, const Color(0xFFE53935)),
    ToastType.warning => (Icons.warning_amber_outlined, const Color(0xFFFF9800)),
    ToastType.info => (Icons.info_outline, const Color(0xFFF55D2C)),
  };

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      duration: duration,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      dismissDirection: DismissDirection.horizontal,
    ),
  );
}

void showSuccessToast(BuildContext context, String message) =>
    showAppToast(context, message, type: ToastType.success);

void showErrorToast(BuildContext context, String message) =>
    showAppToast(context, message, type: ToastType.error, duration: const Duration(seconds: 3));

void showWarningToast(BuildContext context, String message) =>
    showAppToast(context, message, type: ToastType.warning);

void showInfoToast(BuildContext context, String message) =>
    showAppToast(context, message, type: ToastType.info);
