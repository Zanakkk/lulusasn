// lib/core/widgets/error_message.dart

import 'package:flutter/material.dart';
import 'brutalist_button.dart';

/// Brutalist-style error message display.
///
/// Variants:
/// - Inline (compact)
/// - Card (with border)
/// - Full screen
/// - With retry button
class ErrorMessage extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const ErrorMessage({
    super.key,
    required this.message,
    this.icon = Icons.error_outline,
    this.backgroundColor = const Color(0xFFFFE5E5),
    this.borderColor = Colors.red,
    this.textColor = Colors.red,
    this.onRetry,
    this.retryButtonText = 'COBA LAGI',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            BrutalistButton.small(
              text: retryButtonText!,
              onPressed: onRetry,
              backgroundColor: borderColor,
              foregroundColor: Colors.white,
            ),
          ],
        ],
      ),
    );
  }

  /// Inline error (compact, no retry button)
  factory ErrorMessage.inline({
    required String message,
    Color backgroundColor = const Color(0xFFFFE5E5),
    Color borderColor = Colors.red,
  }) {
    return ErrorMessage(
      message: message,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
    );
  }

  /// Card error (with shadow)
  static Widget card({required String message, VoidCallback? onRetry}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        border: Border.all(color: Colors.red, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(6, 6), blurRadius: 0),
        ],
      ),
      child: ErrorMessage(message: message, onRetry: onRetry),
    );
  }

  /// Full screen error
  static Widget fullScreen({
    required String title,
    required String message,
    VoidCallback? onRetry,
    String retryButtonText = 'COBA LAGI',
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(8, 8),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                BrutalistButton.primary(
                  text: retryButtonText,
                  onPressed: onRetry,
                  width: double.infinity,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Warning message (yellow)
  factory ErrorMessage.warning({
    required String message,
    VoidCallback? onRetry,
  }) {
    return ErrorMessage(
      message: message,
      icon: Icons.warning_amber_outlined,
      backgroundColor: const Color(0xFFFFF8E1),
      borderColor: const Color(0xFFFFD700),
      textColor: const Color(0xFFF57F17),
      onRetry: onRetry,
    );
  }

  /// Info message (blue)
  factory ErrorMessage.info({required String message, VoidCallback? onRetry}) {
    return ErrorMessage(
      message: message,
      icon: Icons.info_outline,
      backgroundColor: const Color(0xFFE3F2FD),
      borderColor: const Color(0xFF2196F3),
      textColor: const Color(0xFF1976D2),
      onRetry: onRetry,
    );
  }

  /// Success message (green)
  factory ErrorMessage.success({required String message}) {
    return ErrorMessage(
      message: message,
      icon: Icons.check_circle_outline,
      backgroundColor: const Color(0xFFE8F5E9),
      borderColor: const Color(0xFF4CAF50),
      textColor: const Color(0xFF2E7D32),
    );
  }
}
