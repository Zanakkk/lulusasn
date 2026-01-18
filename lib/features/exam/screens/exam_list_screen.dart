// lib/features/exam/screens/exam_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/core/services/firebase_service.dart';
import 'package:lulusasn/core/widgets/loading_indicator.dart';
import 'package:lulusasn/core/widgets/error_message.dart';
import 'package:lulusasn/core/widgets/empty_state.dart';
import 'package:lulusasn/app/routes.dart';
import 'dart:math' as math;

/// Modern Learning Path Screen - Duolingo Inspired
///
/// Features:
/// - Natural snake path dengan smooth transitions
/// - Circular progress arc (70% coverage)
/// - 3D button effect dengan depth
/// - Smooth connecting lines dengan gradient
/// - Compact category filter
/// - Haptic feedback
class ExamListScreen extends StatefulWidget {
  const ExamListScreen({super.key});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  String _selectedCategory = 'TWK';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Compact Header
          SliverToBoxAdapter(
            child: _CompactHeader(
              category: _selectedCategory,
              onCategoryChanged: (category) {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategory = category);
              },
            ),
          ),

          // Snake Learning Path
          SliverToBoxAdapter(child: _SnakePath(category: _selectedCategory)),
        ],
      ),
    );
  }
}

// ==============================================================================
// COMPACT HEADER - Category filter + Title
// ==============================================================================

class _CompactHeader extends StatelessWidget {
  final String category;
  final ValueChanged<String> onCategoryChanged;

  const _CompactHeader({
    required this.category,
    required this.onCategoryChanged,
  });

  String _getCategoryFullName(String category) {
    switch (category.toUpperCase()) {
      case 'TWK':
        return 'Tes Wawasan Kebangsaan';
      case 'TIU':
        return 'Tes Intelijensia Umum';
      case 'TKP':
        return 'Tes Karakteristik Pribadi';
      default:
        return 'Jalur Belajar';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'TWK':
        return AppColors.twk;
      case 'TIU':
        return AppColors.tiu;
      case 'TKP':
        return AppColors.tkp;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'id': 'TWK', 'icon': Icons.balance_rounded},
      {'id': 'TIU', 'icon': Icons.psychology_rounded},
      {'id': 'TKP', 'icon': Icons.favorite_rounded},
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        MediaQuery.of(context).padding.top + AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Pills
          Row(
            children: categories.map((cat) {
              final isSelected = category == cat['id'];
              return Padding(
                padding: EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onCategoryChanged(cat['id'] as String),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 16 : 12,
                      vertical: isSelected ? 12 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getCategoryColor(cat['id'] as String)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? _getCategoryColor(cat['id'] as String)
                            : AppColors.border,
                        width: isSelected ? 2 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _getCategoryColor(
                                  cat['id'] as String,
                                ).withOpacity(0.3),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat['icon'] as IconData,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          size: isSelected ? 20 : 18,
                        ),
                        if (isSelected) ...[
                          SizedBox(width: 6),
                          Text(
                            cat['id'] as String,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: AppSpacing.md),

          // Category Title
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: Text(
              _getCategoryFullName(category),
              key: ValueKey(category),
              style: AppTextStyles.headingLarge.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: _getCategoryColor(category),
              ),
            ),
          ),

          SizedBox(height: 4),

          Text(
            'Jalur Pembelajaran',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// SNAKE PATH
// ==============================================================================

class _SnakePath extends StatefulWidget {
  final String category;

  const _SnakePath({required this.category});

  @override
  State<_SnakePath> createState() => _SnakePathState();
}

class _SnakePathState extends State<_SnakePath> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseService.instance.auth.currentUser?.uid;
    if (userId == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text('Silakan login terlebih dahulu'),
        ),
      );
    }

    final packagesQuery = FirebaseService.instance.firestore
        .collection('exam_packages')
        .where('category', isEqualTo: widget.category)
        .where('isActive', isEqualTo: true)
        .orderBy('order', descending: false);

    return StreamBuilder<QuerySnapshot>(
      stream: packagesQuery.snapshots(),
      builder: (context, packagesSnapshot) {
        if (packagesSnapshot.hasError) {
          return ErrorMessage(
            message: 'Gagal memuat paket latihan',
            onRetry: () => setState(() {}),
          );
        }

        if (packagesSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: LoadingIndicator(),
            ),
          );
        }

        final packages = packagesSnapshot.data?.docs ?? [];

        if (packages.isEmpty) {
          return EmptyState.noData(
            message: 'Belum ada paket untuk ${widget.category}',
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.instance.firestore
              .collection('users')
              .doc(userId)
              .collection('exams')
              .where('category', isEqualTo: widget.category)
              .snapshots(),
          builder: (context, examsSnapshot) {
            final Map<String, double> bestScores = {};

            if (examsSnapshot.hasData && examsSnapshot.data != null) {
              for (var doc in examsSnapshot.data!.docs) {
                try {
                  final data = doc.data() as Map<String, dynamic>;
                  final results = data['results'] as Map<String, dynamic>?;
                  final accuracy = results?['accuracy'] as num?;
                  final packageId = data['packageId'] as String?;

                  if (packageId != null && accuracy != null) {
                    final score = accuracy.toDouble();
                    if (!bestScores.containsKey(packageId) ||
                        score > bestScores[packageId]!) {
                      bestScores[packageId] = score;
                    }
                  }
                } catch (e) {
                  print('Error parsing exam doc: $e');
                }
              }
            }

            return _SnakePathBuilder(
              packages: packages,
              bestScores: bestScores,
              category: widget.category,
            );
          },
        );
      },
    );
  }
}

// ==============================================================================
// SNAKE PATH BUILDER - Natural Wave Pattern
// ==============================================================================

// ======================= REVISI FINAL =======================
// FIX:
// 1. Node terlalu ke kanan  → wave dihitung relatif ke CENTER, bukan container penuh
// 2. Garis antar node jelek → path dihitung di koordinat lokal (0..width) + curve simetris
// ===========================================================

// ==============================================================================
// SNAKE PATH BUILDER (FIXED CENTERED WAVE)
// ==============================================================================

// ==============================================================================
// SNAKE PATH BUILDER - Natural Wave Pattern
// ==============================================================================

class _SnakePathBuilder extends StatelessWidget {
  final List<QueryDocumentSnapshot> packages;
  final Map<String, double> bestScores;
  final String category;

  const _SnakePathBuilder({
    required this.packages,
    required this.bestScores,
    required this.category,
  });
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final nodeSize = 76.0;
    final verticalSpacing = 80.0;
    final horizontalPadding = 24.0;

    final containerWidth = screenWidth - (horizontalPadding * 2);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: List.generate(packages.length, (index) {
          final packageDoc = packages[index];
          final bestScore = bestScores[packageDoc.id];

          // Pola zigzag: kiri-tengah-kanan-tengah-kiri
          // 0 -> kiri, 1 -> tengah, 2 -> kanan, 3 -> tengah, 4 -> kiri, dst
          final step = index % 4;
          double xPosition;

          if (step == 0) {
            xPosition = -containerWidth * 0.3; // Kiri
          } else if (step == 1) {
            xPosition = 0; // Tengah
          } else if (step == 2) {
            xPosition = containerWidth * 0.3; // Kanan
          } else {
            xPosition = 0; // Tengah lagi
          }

          // Calculate next position for connecting line
          double? nextXPosition;
          if (index < packages.length - 1) {
            final nextStep = (index + 1) % 4;
            if (nextStep == 0) {
              nextXPosition = -containerWidth * 0.3;
            } else if (nextStep == 1) {
              nextXPosition = 0;
            } else if (nextStep == 2) {
              nextXPosition = containerWidth * 0.3;
            } else {
              nextXPosition = 0;
            }
          }

          return Column(
            children: [
              // Node - Center it properly
              Align(
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: Offset(xPosition, 0),
                  child: _EnhancedNode(
                    packageDoc: packageDoc,
                    index: index,
                    bestScore: bestScore,
                    category: category,
                    nodeSize: nodeSize,
                  ),
                ),
              ),

              // Smooth connecting line
              if (nextXPosition != null)
                _SmoothConnectingLine(
                  startX: containerWidth / 2 + horizontalPadding + xPosition,
                  endX: containerWidth / 2 + horizontalPadding + nextXPosition,
                  height: verticalSpacing,
                  color: _getCategoryColor(category),
                  containerWidth: screenWidth,
                ),
            ],
          );
        }),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'TWK':
        return AppColors.twk;
      case 'TIU':
        return AppColors.tiu;
      case 'TKP':
        return AppColors.tkp;
      default:
        return AppColors.primary;
    }
  }
}

// ==============================================================================
// SMOOTH CONNECTING LINE - Gradient & Smooth Curve
// ==============================================================================

class _SmoothConnectingLine extends StatelessWidget {
  final double startX;
  final double endX;
  final double height;
  final Color color;
  final double containerWidth;

  const _SmoothConnectingLine({
    required this.startX,
    required this.endX,
    required this.height,
    required this.color,
    required this.containerWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: containerWidth,
      height: height,
      child: CustomPaint(
        painter: _SmoothLinePainter(startX: startX, endX: endX, color: color),
      ),
    );
  }
}

class _SmoothLinePainter extends CustomPainter {
  final double startX;
  final double endX;
  final Color color;

  _SmoothLinePainter({
    required this.startX,
    required this.endX,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient paint for smooth color transition
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.25), color.withOpacity(0.15)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(startX, 0);

    // Smooth cubic bezier curve
    final controlPoint1 = Offset(startX, size.height * 0.25);
    final controlPoint2 = Offset(endX, size.height * 0.75);
    final endPoint = Offset(endX, size.height);

    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      endPoint.dx,
      endPoint.dy,
    );

    canvas.drawPath(path, paint);

    // Subtle dots for visual interest
    final dotPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    for (double i = 0.2; i <= 0.8; i += 0.3) {
      final t = i;
      final x = _cubicBezier(
        t,
        startX,
        controlPoint1.dx,
        controlPoint2.dx,
        endX,
      );
      final y = _cubicBezier(
        t,
        0,
        controlPoint1.dy,
        controlPoint2.dy,
        size.height,
      );

      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }
  }

  double _cubicBezier(double t, double p0, double p1, double p2, double p3) {
    final oneMinusT = 1 - t;
    return math.pow(oneMinusT, 3) * p0 +
        3 * math.pow(oneMinusT, 2) * t * p1 +
        3 * oneMinusT * math.pow(t, 2) * p2 +
        math.pow(t, 3) * p3;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==============================================================================
// ENHANCED NODE - 3D Effect + Circular Progress Arc
// ==============================================================================

class _EnhancedNode extends StatefulWidget {
  final QueryDocumentSnapshot packageDoc;
  final int index;
  final double? bestScore;
  final String category;
  final double nodeSize;

  const _EnhancedNode({
    required this.packageDoc,
    required this.index,
    this.bestScore,
    required this.category,
    required this.nodeSize,
  });

  @override
  State<_EnhancedNode> createState() => _EnhancedNodeState();
}

class _EnhancedNodeState extends State<_EnhancedNode>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _categoryColor {
    switch (widget.category.toUpperCase()) {
      case 'TWK':
        return AppColors.twk;
      case 'TIU':
        return AppColors.tiu;
      case 'TKP':
        return AppColors.tkp;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.packageDoc.data() as Map<String, dynamic>;
    final questionCount = data['questionCount'] as int? ?? 10;
    final energyCost = data['energyCost'] as int? ?? 1;
    final isPremium = data['isPremium'] as bool? ?? false;

    final scorePercentage = widget.bestScore != null
        ? (widget.bestScore! * 100).toInt()
        : 0;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
        HapticFeedback.mediumImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        _navigateToExam(context, data);
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              children: [
                // 3D Node with Circular Arc Progress
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Circular progress arc (70% of circle)
                    CustomPaint(
                      size: Size(widget.nodeSize + 16, widget.nodeSize + 16),
                      painter: _CircularArcPainter(
                        progress: widget.bestScore ?? 0.0,
                        color: _categoryColor,
                        strokeWidth: 5,
                      ),
                    ),

                    // 3D Shadow layer
                    if (!_isPressed)
                      Positioned(
                        top: 6,
                        child: Container(
                          width: widget.nodeSize,
                          height: widget.nodeSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.black.withOpacity(0.15),
                                Colors.black.withOpacity(0.05),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Main node
                    Container(
                      width: widget.nodeSize,
                      height: widget.nodeSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Colors.grey.shade50],
                        ),
                        boxShadow: _isPressed
                            ? [
                                BoxShadow(
                                  color: _categoryColor.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: _categoryColor.withOpacity(0.3),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                  offset: Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Level number
                            Text(
                              '${widget.index + 1}',
                              style: TextStyle(
                                fontSize: widget.nodeSize * 0.4,
                                fontWeight: FontWeight.bold,
                                color: _categoryColor,
                                height: 1,
                                shadows: [
                                  Shadow(
                                    color: _categoryColor.withOpacity(0.2),
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),

                            // Premium badge
                            if (isPremium)
                              Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.workspace_premium,
                                  size: widget.nodeSize * 0.18,
                                  color: Colors.amber.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Score percentage badge
                    if (widget.bestScore != null)
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _categoryColor,
                                _categoryColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _categoryColor.withOpacity(0.4),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 2),
                              Text(
                                '$scorePercentage%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 12),

                // Metadata chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _InfoChip(
                      icon: Icons.quiz_rounded,
                      label: '$questionCount',
                      color: _categoryColor,
                      tooltip: '$questionCount soal',
                    ),
                    SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.favorite,
                      label: '$energyCost',
                      color: AppColors.error,
                      tooltip: 'Butuh $energyCost energi',
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigateToExam(BuildContext context, Map<String, dynamic> data) {
    Navigator.pushNamed(
      context,
      AppRoutes.examPre,
      arguments: {
        'packageId': widget.packageDoc.id,
        'category': widget.category,
        'questionCount': data['questionCount'] ?? 10,
        'energyCost': data['energyCost'] ?? 1,
        'isPremium': data['isPremium'] ?? false,
        'title': data['title'] ?? 'Paket Latihan',
      },
    );
  }
}

// ==============================================================================
// CIRCULAR ARC PAINTER - 70% Progress Ring
// ==============================================================================

class _CircularArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircularArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background arc (70% of circle, gray)
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const arcAngle = 2 * math.pi * 0.7; // 70% of circle
    const startAngle = -math.pi / 2 - (arcAngle / 2); // Center the arc at top

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      arcAngle,
      false,
      backgroundPaint,
    );

    // Progress arc (colored)
    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = SweepGradient(
          colors: [color, color.withOpacity(0.6)],
          startAngle: startAngle,
          endAngle: startAngle + (arcAngle * progress),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        arcAngle * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==============================================================================
// INFO CHIP - Compact metadata display
// ==============================================================================

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String tooltip;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
