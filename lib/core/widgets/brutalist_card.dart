// lib/core/widgets/brutalist_card.dart

import 'package:flutter/material.dart';

/// Neobrutalism-style card with thick border and hard shadow.
///
/// Features:
/// - Customizable border width, color, shadow
/// - Responsive padding
/// - Optional background color
/// - Clickable variant support
class BrutalistCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Offset shadowOffset;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const BrutalistCard({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.black,
    this.shadowColor = Colors.black,
    this.borderWidth = 3,
    this.padding,
    this.margin,
    this.shadowOffset = const Offset(6, 6),
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: shadowOffset,
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }

  /// Small variant (compact padding)
  factory BrutalistCard.small({
    required Widget child,
    Color backgroundColor = Colors.white,
    Color borderColor = Colors.black,
    VoidCallback? onTap,
  }) {
    return BrutalistCard(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: child,
    );
  }

  /// Large variant (spacious padding)
  factory BrutalistCard.large({
    required Widget child,
    Color backgroundColor = Colors.white,
    Color borderColor = Colors.black,
    VoidCallback? onTap,
  }) {
    return BrutalistCard(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      padding: const EdgeInsets.all(24),
      shadowOffset: const Offset(8, 8),
      onTap: onTap,
      child: child,
    );
  }

  /// Colored variant (with custom background)
  factory BrutalistCard.colored({
    required Widget child,
    required Color color,
    Color borderColor = Colors.black,
    VoidCallback? onTap,
  }) {
    return BrutalistCard(
      backgroundColor: color,
      borderColor: borderColor,
      onTap: onTap,
      child: child,
    );
  }

  /// Flat variant (no shadow)
  factory BrutalistCard.flat({
    required Widget child,
    Color backgroundColor = Colors.white,
    Color borderColor = Colors.black,
    VoidCallback? onTap,
  }) {
    return BrutalistCard(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      shadowOffset: Offset.zero,
      onTap: onTap,
      child: child,
    );
  }
}