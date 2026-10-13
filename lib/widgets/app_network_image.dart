import 'package:flutter/material.dart';

/// Reliable, performant network image widget with graceful loading and fallback error handling.
class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? placeholderColor;
  final IconData fallbackIcon;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderColor,
    this.fallbackIcon = Icons.set_meal,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = placeholderColor ?? const Color(0xFFF0F2F5);

    Widget placeholderWidget({bool isLoading = false}) {
      return Container(
        width: width,
        height: height,
        color: bgColor,
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor.withValues(alpha: 0.6),
                  ),
                ),
              )
            : Icon(
                fallbackIcon,
                size: (height != null && height! < 60) ? 24 : 40,
                color: Colors.black26,
              ),
      );
    }

    final trimmedUrl = imageUrl.trim();
    if (trimmedUrl.isEmpty) {
      final child = placeholderWidget();
      return borderRadius != null
          ? ClipRRect(borderRadius: borderRadius!, child: child)
          : child;
    }

    final imageWidget = Image.network(
      trimmedUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholderWidget(isLoading: true);
      },
      errorBuilder: (context, error, stackTrace) {
        return placeholderWidget();
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
