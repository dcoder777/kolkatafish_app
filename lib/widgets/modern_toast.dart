import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ToastStyle { success, error, info, warning }

class ModernToast {
  static OverlayEntry? _currentEntry;
  static _ToastOverlayState? _currentState;

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    ToastStyle style = ToastStyle.info,
    Widget? leading,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration = const Duration(seconds: 2),
    OverlayState? overlay,
    bool persistent = false,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;
    _currentState = null;

    OverlayState? targetOverlay = overlay ?? Overlay.maybeOf(context);
    if (targetOverlay == null) {
      if (context is StatefulElement && context.state is NavigatorState) {
        targetOverlay = (context.state as NavigatorState).overlay;
      } else {
        targetOverlay = context.findAncestorStateOfType<NavigatorState>()?.overlay;
      }
    }

    if (targetOverlay == null) {
      debugPrint('[ModernToast] No overlay found to display toast: $message');
      return;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        key: GlobalKey<_ToastOverlayState>(),
        message: message,
        title: title,
        style: style,
        leading: leading,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: persistent ? null : duration,
        onDismiss: () {
          entry.remove();
          if (_currentEntry == entry) {
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    targetOverlay.insert(entry);
  }

  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final String? title;
  final ToastStyle style;
  final Widget? leading;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration? duration;
  final VoidCallback onDismiss;

  const _ToastOverlay({
    super.key,
    required this.message,
    this.title,
    required this.style,
    this.leading,
    this.actionLabel,
    this.onAction,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _controller.forward();
    if (widget.duration != null) {
      Future.delayed(widget.duration!, _dismiss);
    }
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (icon, accentColor, glowColor) = switch (widget.style) {
      ToastStyle.success => (
          Icons.wifi_rounded,
          const Color(0xFF2E7D32),
          const Color(0xFF4CAF50),
        ),
      ToastStyle.error => (
          Icons.wifi_off_rounded,
          const Color(0xFFD32F2F),
          const Color(0xFFEF5350),
        ),
      ToastStyle.warning => (
          Icons.warning_amber_rounded,
          const Color(0xFFE65100),
          const Color(0xFFFFA726),
        ),
      ToastStyle.info => (
          Icons.info_outline_rounded,
          const Color(0xFF1976D2),
          const Color(0xFF42A5F5),
        ),
    };

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: widget.duration != null ? _dismiss : null,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2428).withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (widget.leading != null) ...[
                          widget.leading!,
                          const SizedBox(width: 12),
                        ] else
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: glowColor.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(icon, color: Colors.white, size: 20),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.title != null)
                                Row(
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color: glowColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: glowColor.withValues(alpha: 0.7),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        widget.title!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 2),
                              Text(
                                widget.message,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withValues(alpha: 0.88),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.actionLabel != null) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              _dismiss();
                              widget.onAction?.call();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFF55D2C),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: Colors.white.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              widget.actionLabel!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (widget.duration == null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: glowColor.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'OFFLINE',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: glowColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
