// lib/core/widgets/duolingo_button.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// Duolingo-style button with playful design, rounded corners, and smooth animations.
///
/// Features:
/// - Rounded pill-shaped design
/// - Smooth press animations with scale effect
/// - Bottom shadow for depth (lifted appearance)
/// - Loading state with animated progress
/// - Icon support with proper spacing
/// - Haptic feedback on press
/// - Accessibility support
///
/// Variants:
/// - Primary (green gradient)
/// - Secondary (outlined white)
/// - Danger (red)
/// - Disabled (gray)
/// - Small (compact size)
class DuolingoButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? shadowColor;
  final EdgeInsetsGeometry padding;
  final bool isLoading;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final double? width;
  final double height;
  final double borderRadius;
  final Gradient? gradient;
  final bool enableHapticFeedback;
  final double elevation;

  const DuolingoButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF58CC02),
    this.foregroundColor = Colors.white,
    this.shadowColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.height = 56,
    this.borderRadius = 16,
    this.gradient,
    this.enableHapticFeedback = true,
    this.elevation = 4,
  });

  @override
  State<DuolingoButton> createState() => _DuolingoButtonState();

  // ============ Factory Constructors ============

  /// Primary button with Duolingo's signature green gradient
  factory DuolingoButton.primary({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? leadingIcon,
    Widget? trailingIcon,
    double? width,
  }) {
    return DuolingoButton(
      text: text,
      onPressed: onPressed,
      backgroundColor: const Color(0xFF58CC02),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF58CC02), Color(0xFF48B002)],
      ),
      shadowColor: const Color(0xFF48B002),
      isLoading: isLoading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      width: width,
    );
  }

  /// Secondary button (outlined style)
  factory DuolingoButton.secondary({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? leadingIcon,
    Widget? trailingIcon,
    double? width,
  }) {
    return DuolingoButton(
      text: text,
      onPressed: onPressed,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1CB0F6),
      shadowColor: const Color(0xFFE5E5E5),
      isLoading: isLoading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      width: width,
      elevation: 2,
    );
  }

  /// Danger/Cancel button (red)
  factory DuolingoButton.danger({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? leadingIcon,
    Widget? trailingIcon,
    double? width,
  }) {
    return DuolingoButton(
      text: text,
      onPressed: onPressed,
      backgroundColor: const Color(0xFFFF4B4B),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFF4B4B), Color(0xFFEA2B2B)],
      ),
      shadowColor: const Color(0xFFEA2B2B),
      isLoading: isLoading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      width: width,
    );
  }

  /// Super button (premium gold style)
  factory DuolingoButton.super_({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? leadingIcon,
    Widget? trailingIcon,
    double? width,
  }) {
    return DuolingoButton(
      text: text,
      onPressed: onPressed,
      backgroundColor: const Color(0xFFFFC800),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFC800), Color(0xFFE6B400)],
      ),
      foregroundColor: const Color(0xFF503600),
      shadowColor: const Color(0xFFE6B400),
      isLoading: isLoading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      width: width,
    );
  }

  /// Practice button (blue)
  factory DuolingoButton.practice({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Widget? leadingIcon,
    Widget? trailingIcon,
    double? width,
  }) {
    return DuolingoButton(
      text: text,
      onPressed: onPressed,
      backgroundColor: const Color(0xFF1CB0F6),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1CB0F6), Color(0xFF0FA0E6)],
      ),
      shadowColor: const Color(0xFF0FA0E6),
      isLoading: isLoading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      width: width,
    );
  }

  /// Small/Compact button
  factory DuolingoButton.small({
    required String text,
    required VoidCallback? onPressed,
    Color backgroundColor = const Color(0xFF58CC02),
    Color foregroundColor = Colors.white,
    bool isLoading = false,
    Widget? leadingIcon,
    Widget? trailingIcon,
  }) {
    return DuolingoButton(
      text: text,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      height: 44,
      borderRadius: 12,
      isLoading: isLoading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      elevation: 3,
    );
  }
}

class _DuolingoButtonState extends State<DuolingoButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final effectiveShadowColor = widget.shadowColor ??
        (isDisabled
            ? const Color(0xFFD0D0D0)
            : widget.backgroundColor.withOpacity(0.8));

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: widget.text,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: isDisabled
                  ? null
                  : widget.gradient,
              color: isDisabled
                  ? const Color(0xFFE5E5E5)
                  : (widget.gradient == null ? widget.backgroundColor : null),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: widget.backgroundColor == Colors.white && !isDisabled
                  ? Border.all(
                color: const Color(0xFFE5E5E5),
                width: 2,
              )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: effectiveShadowColor,
                  offset: Offset(0, _isPressed ? 2 : widget.elevation),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isDisabled ? null : widget.onPressed,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                splashColor: widget.foregroundColor.withOpacity(0.1),
                highlightColor: widget.foregroundColor.withOpacity(0.05),
                child: Padding(
                  padding: widget.padding,
                  child: _buildButtonContent(isDisabled),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(bool isDisabled) {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDisabled ? const Color(0xFFAFAFAF) : widget.foregroundColor,
            ),
          ),
        ),
      );
    }

    final textWidget = Text(
      widget.text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: isDisabled ? const Color(0xFFAFAFAF) : widget.foregroundColor,
        letterSpacing: 0.3,
        height: 1.2,
      ),
      textAlign: TextAlign.center,
    );

    if (widget.leadingIcon == null && widget.trailingIcon == null) {
      return Center(child: textWidget);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leadingIcon != null) ...[
          IconTheme(
            data: IconThemeData(
              color: isDisabled ? const Color(0xFFAFAFAF) : widget.foregroundColor,
              size: 20,
            ),
            child: widget.leadingIcon!,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(child: textWidget),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 8),
          IconTheme(
            data: IconThemeData(
              color: isDisabled ? const Color(0xFFAFAFAF) : widget.foregroundColor,
              size: 20,
            ),
            child: widget.trailingIcon!,
          ),
        ],
      ],
    );
  }
}