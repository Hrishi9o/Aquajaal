import 'package:flutter/material.dart';

/// A quick utility widget that scales text down on narrow screens
/// to avoid overflow while keeping the original style.
class ResponsiveText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;

  const ResponsiveText(
    this.data, {
    Key? key,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Scale down on very small devices (e.g., <350dp)
    double scale = 1.0;
    if (width < 350) {
      scale = 0.85;
    } else if (width < 400) {
      scale = 0.9;
    }
    final baseStyle = style ?? const TextStyle();
    final effectiveStyle = baseStyle.copyWith(fontSize: (baseStyle.fontSize ?? 14) * scale);
    return Text(
      data,
      style: effectiveStyle,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
