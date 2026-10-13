import 'package:flutter/material.dart';
import '../models/sea_product.dart';
import '../widgets/modern_toast.dart';

export '../widgets/modern_toast.dart' show ToastStyle;

void showAppToast(
  BuildContext context,
  String message, {
  String? title,
  ToastStyle style = ToastStyle.info,
  Duration duration = const Duration(seconds: 2),
}) {
  ModernToast.show(
    context,
    message: message,
    title: title,
    style: style,
    duration: duration,
  );
}

void showSuccessToast(BuildContext context, String message) =>
    showAppToast(context, message, style: ToastStyle.success);

void showErrorToast(BuildContext context, String message) =>
    showAppToast(context, message, style: ToastStyle.error, duration: const Duration(seconds: 3));

void showWarningToast(BuildContext context, String message) =>
    showAppToast(context, message, style: ToastStyle.warning);

void showInfoToast(BuildContext context, String message) =>
    showAppToast(context, message, style: ToastStyle.info);

void showCartToast(
  BuildContext context,
  SeaProduct product, {
  required bool added,
  VoidCallback? onViewCart,
}) {
  ModernToast.show(
    context,
    title: product.name,
    message: added ? 'Added to cart' : 'Removed from cart',
    style: added ? ToastStyle.success : ToastStyle.info,
    duration: const Duration(seconds: 3),
    actionLabel: onViewCart != null ? 'View Cart' : null,
    onAction: onViewCart,
    leading: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: product.imageUrl.isNotEmpty
          ? Image.network(
              product.imageUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallbackIcon(added),
            )
          : _fallbackIcon(added),
    ),
  );
}

Widget _fallbackIcon(bool added) {
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: (added ? const Color(0xFF4CAF50) : const Color(0xFF757575)).withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(
      added ? Icons.check_rounded : Icons.remove_shopping_cart_outlined,
      color: added ? const Color(0xFF4CAF50) : const Color(0xFF757575),
      size: 20,
    ),
  );
}
