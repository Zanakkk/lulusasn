// lib/features/home/widgets/energy_display.dart

// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lulusasn/features/home/models/energy_model.dart';

/// Modern Minimalist Energy Display
///
/// Design principles:
/// - Clean, spacious layout
/// - Subtle shadows (elevation)
/// - Rounded corners (16px)
/// - Minimal borders
/// - Smooth animations
class EnergyDisplay extends StatefulWidget {
  final EnergyModel energy;
  final bool isPremium;
  final VoidCallback? onTap;

  const EnergyDisplay({
    super.key,
    required this.energy,
    this.isPremium = false,
    this.onTap,
  });

  @override
  State<EnergyDisplay> createState() => _EnergyDisplayState();
}

class _EnergyDisplayState extends State<EnergyDisplay> {
  Timer? _timer;
  int _currentEnergy = 0;
  int _minutesUntilNext = 0;
  int _secondsUntilNext = 0;

  @override
  void initState() {
    super.initState();
    _updateEnergy();
    _startTimer();
  }

  @override
  void didUpdateWidget(EnergyDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.energy != widget.energy) {
      _updateEnergy();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateEnergy();
        });
      }
    });
  }

  void _updateEnergy() {
    _currentEnergy = widget.energy.calculateCurrentEnergy();

    if (_currentEnergy < widget.energy.max) {
      final minutesUntilNext = widget.energy.minutesUntilNext();
      final now = DateTime.now();
      final lastRegen = widget.energy.lastRegen;
      final totalSeconds = minutesUntilNext * 60;
      final elapsedSeconds =
          now.difference(lastRegen).inSeconds % (widget.energy.regenRate * 60);
      final remainingSeconds =
          totalSeconds - (elapsedSeconds % (widget.energy.regenRate * 60));

      _minutesUntilNext = remainingSeconds ~/ 60;
      _secondsUntilNext = remainingSeconds % 60;
    } else {
      _minutesUntilNext = 0;
      _secondsUntilNext = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPremium) {
      return _buildPremiumEnergy();
    }
    return _buildFreeEnergy();
  }

  // ============================================================================
  // PREMIUM ENERGY (Unlimited)
  // ============================================================================

  Widget _buildPremiumEnergy() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8E1), // Light gold
              Color(0xFFFFECB3), // Gold
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF59E0B).withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon with gradient background
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF59E0B), // Orange-400
                    Color(0xFFD97706), // Orange-600
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Unlimited',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Energy tanpa batas',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // FREE ENERGY (With Timer)
  // ============================================================================

  Widget _buildFreeEnergy() {
    final isFull = _currentEnergy >= widget.energy.max;
    final percentage = _currentEnergy / widget.energy.max;

    // Modern color palette
    final Color primaryColor;
    final Color backgroundColor;

    if (percentage >= 0.7) {
      primaryColor = const Color(0xFF10B981); // Green-500
      backgroundColor = const Color(0xFFECFDF5); // Green-50
    } else if (percentage >= 0.3) {
      primaryColor = const Color(0xFFF59E0B); // Orange-500
      backgroundColor = const Color(0xFFFFF7ED); // Orange-50
    } else {
      primaryColor = const Color(0xFFEF4444); // Red-500
      backgroundColor = const Color(0xFFFEF2F2); // Red-50
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Energy count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Energy',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_currentEnergy/${widget.energy.max}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          letterSpacing: -1,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                // Timer badge
                if (!isFull) _buildModernTimer(primaryColor),
              ],
            ),

            const SizedBox(height: 20),

            // Hearts visual with animation
            _buildModernHeartsVisual(primaryColor, backgroundColor),

            if (!isFull) ...[
              const SizedBox(height: 20),
              _buildModernProgressBar(primaryColor, backgroundColor),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // MODERN HEARTS VISUAL
  // ============================================================================

  Widget _buildModernHeartsVisual(Color primaryColor, Color backgroundColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.energy.max, (index) {
        final isFilled = index < _currentEnergy;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: Icon(
              Icons.favorite_rounded,
              color: isFilled ? primaryColor : Colors.grey.shade200,
              size: 32,
            ),
          ),
        );
      }),
    );
  }

  // ============================================================================
  // MODERN TIMER
  // ============================================================================

  Widget _buildModernTimer(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            '${_minutesUntilNext.toString().padLeft(2, '0')}:${_secondsUntilNext.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MODERN PROGRESS BAR
  // ============================================================================

  Widget _buildModernProgressBar(Color primaryColor, Color backgroundColor) {
    final progress = widget.energy.regenProgress();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Regenerasi energy',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 13,
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar with smooth animation
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 8,
            decoration: BoxDecoration(color: Colors.grey.shade100),
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Extension for AnimatedFractionallySizedBox
class AnimatedFractionallySizedBox extends StatelessWidget {
  final Duration duration;
  final Curve curve;
  final Alignment alignment;
  final double widthFactor;
  final Widget child;

  const AnimatedFractionallySizedBox({
    super.key,
    required this.duration,
    required this.curve,
    required this.alignment,
    required this.widthFactor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: curve,
      tween: Tween<double>(begin: 0, end: widthFactor),
      builder: (context, value, child) {
        return FractionallySizedBox(
          alignment: alignment,
          widthFactor: value,
          child: child,
        );
      },
      child: child,
    );
  }
}
