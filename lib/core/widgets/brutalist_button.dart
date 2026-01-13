// lib/core/widgets/brutalist_button.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// Neobrutalism-style button with thick border and hard shadow.
///
/// Variants:
/// - Primary (filled)
/// - Secondary (outlined)
/// - Icon button
/// - Loading state support
class BrutalistButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final Color shadowColor;
  final double borderWidth;
  final Offset shadowOffset;
  final EdgeInsetsGeometry padding;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;

  const BrutalistButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = Colors.black,
    this.foregroundColor = Colors.white,
    this.borderColor = Colors.black,
    this.shadowColor = Colors.black,
    this.borderWidth = 3,
    this.shadowOffset = const Offset(4, 4),
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? Colors.grey[300] : backgroundColor,
          foregroundColor: isDisabled ? Colors.grey[600] : foregroundColor,
          elevation: 0,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(
              color: isDisabled ? Colors.grey[400]! : borderColor,
              width: borderWidth,
            ),
          ),
          shadowColor: shadowColor,
        ).copyWith(
          overlayColor: WidgetStateProperty.all(
            foregroundColor.withOpacity(0.1),
          ),
        ),
        child: isLoading
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
          ),
        )
            : icon != null
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon!,
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        )
            : Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  /// Primary button (filled, default)
  factory BrutalistButton.primary({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    double? width,
  }) {
    return BrutalistButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      width: width,
    );
  }

  /// Secondary button (outlined)
  factory BrutalistButton.secondary({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    double? width,
  }) {
    return BrutalistButton(
      text: text,
      onPressed: onPressed,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      isLoading: isLoading,
      icon: icon,
      width: width,
    );
  }

  /// Danger button (red)
  factory BrutalistButton.danger({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    double? width,
  }) {
    return BrutalistButton(
      text: text,
      onPressed: onPressed,
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      borderColor: Colors.red,
      isLoading: isLoading,
      icon: icon,
      width: width,
    );
  }

  /// Success button (green)
  factory BrutalistButton.success({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    double? width,
  }) {
    return BrutalistButton(
      text: text,
      onPressed: onPressed,
      backgroundColor: const Color(0xFF00FF00),
      foregroundColor: Colors.black,
      borderColor: Colors.black,
      isLoading: isLoading,
      icon: icon,
      width: width,
    );
  }

  /// Warning button (yellow)
  factory BrutalistButton.warning({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? icon,
    double? width,
  }) {
    return BrutalistButton(
      text: text,
      onPressed: onPressed,
      backgroundColor: const Color(0xFFFFD700),
      foregroundColor: Colors.black,
      borderColor: Colors.black,
      isLoading: isLoading,
      icon: icon,
      width: width,
    );
  }

  /// Small button (compact)
  factory BrutalistButton.small({
    required String text,
    required VoidCallback? onPressed,
    Color backgroundColor = Colors.black,
    Color foregroundColor = Colors.white,
    bool isLoading = false,
    Widget? icon,
  }) {
    return BrutalistButton(
      text: text,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 44,
      isLoading: isLoading,
      icon: icon,
    );
  }
}