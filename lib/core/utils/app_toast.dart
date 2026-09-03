import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum AppToastType {
  success,
  overrideRecorded,
  warning,
  error,
}

/// Non-intrusive, compact toast notification system pinned to the top-right corner.
/// Strictly fulfills UI requirements: max 300px wide, non-full-width, auto-dismiss, no bottom obstruction.
class AppToast {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Shows standard "✓ Added to cart" compact toast
  static void addedToCart(BuildContext context) {
    show(
      context,
      message: '✓ Added to cart',
      type: AppToastType.success,
      duration: const Duration(seconds: 2),
    );
  }

  /// Shows "✓ Added (override recorded)" compact toast
  static void addedOverride(BuildContext context) {
    show(
      context,
      message: '✓ Added (override recorded)',
      type: AppToastType.overrideRecorded,
      duration: const Duration(seconds: 2),
    );
  }

  /// Shows error notification with manual close button
  static void error(BuildContext context, String message) {
    show(
      context,
      message: message,
      type: AppToastType.error,
      duration: const Duration(seconds: 4),
    );
  }

  /// Shows warning notification with manual close button
  static void warning(BuildContext context, String message) {
    show(
      context,
      message: message,
      type: AppToastType.warning,
      duration: const Duration(seconds: 4),
    );
  }

  /// Shows success message
  static void success(BuildContext context, String message) {
    show(
      context,
      message: message,
      type: AppToastType.success,
      duration: const Duration(seconds: 2),
    );
  }

  /// Base method to show toast in top-right corner
  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.success,
    Duration duration = const Duration(seconds: 2),
  }) {
    // Dismiss any existing toast first
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context, rootOverlay: true);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        message: message,
        type: type,
        duration: duration,
        onClose: () {
          _dismissTimer?.cancel();
          entry.remove();
          if (_currentEntry == entry) {
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
      if (_currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
      }
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final AppToastType type;
  final Duration duration;
  final VoidCallback onClose;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onClose,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.15, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case AppToastType.success:
        return AppColors.accentDark; // Lime-green
      case AppToastType.overrideRecorded:
        return const Color(0xFF65A30D); // Deeper lime with warning tone
      case AppToastType.warning:
        return const Color(0xFFD97706); // Amber/Orange
      case AppToastType.error:
        return const Color(0xFFDC2626); // Red
    }
  }

  IconData get _iconData {
    switch (widget.type) {
      case AppToastType.success:
        return Icons.check_circle_rounded;
      case AppToastType.overrideRecorded:
        return Icons.warning_amber_rounded;
      case AppToastType.warning:
        return Icons.warning_rounded;
      case AppToastType.error:
        return Icons.error_outline_rounded;
    }
  }

  bool get _showCloseButton =>
      widget.type == AppToastType.warning || widget.type == AppToastType.error;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 300,
                minHeight: 46,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_iconData, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_showCloseButton) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: widget.onClose,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
