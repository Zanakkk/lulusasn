// lib/core/widgets/loading_indicator.dart

import 'package:flutter/material.dart';

/// Brutalist-style loading indicators.
///
/// Variants:
/// - Circular (default)
/// - Linear
/// - Overlay (full screen)
class LoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color color;
  final String? message;

  const LoadingIndicator({
    super.key,
    this.size = 40,
    this.strokeWidth = 3,
    this.color = Colors.black,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Small loading indicator
  factory LoadingIndicator.small({
    Color color = Colors.black,
  }) {
    return LoadingIndicator(
      size: 24,
      strokeWidth: 2,
      color: color,
    );
  }

  /// Large loading indicator
  factory LoadingIndicator.large({
    Color color = Colors.black,
    String? message,
  }) {
    return LoadingIndicator(
      size: 64,
      strokeWidth: 4,
      color: color,
      message: message,
    );
  }

  /// Linear loading indicator
  static Widget linear({
    Color color = Colors.black,
  }) {
    return LinearProgressIndicator(
      backgroundColor: Colors.grey[300],
      valueColor: AlwaysStoppedAnimation<Color>(color),
      minHeight: 4,
    );
  }

  /// Full screen overlay loading
  static Widget overlay({
    Color backgroundColor = Colors.black54,
    Color indicatorColor = Colors.white,
    String? message,
  }) {
    return Container(
      color: backgroundColor,
      child: LoadingIndicator(
        color: indicatorColor,
        message: message,
      ),
    );
  }

  /// Card-style loading with border
  static Widget card({
    String? message = 'Memuat...',
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(6, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: LoadingIndicator(
        message: message,
      ),
    );
  }
}