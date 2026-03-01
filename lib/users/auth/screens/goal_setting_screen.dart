// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/storage_service.dart';
import '../service/user_service.dart';
// ─────────────────────────────────────────────────────────────────────────────
// GOAL SETTING SCREEN  (onboarding — first launch)
// ─────────────────────────────────────────────────────────────────────────────

class _Goal {
  final String key; // name.toLowerCase() — identifier
  final String name; // 'LPDP', 'CPNS', dll
  final String description;
  final List<String> categories;
  final int order;

  const _Goal({
    required this.key,
    required this.name,
    required this.description,
    required this.categories,
    required this.order,
  });

  factory _Goal.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final name = d['name'] as String? ?? '';
    return _Goal(
      key: name.toLowerCase(),
      name: name,
      description: d['description'] as String? ?? '',
      categories: List<String>.from(d['categories'] ?? []),
      order: d['order'] as int? ?? 99,
    );
  }

  // badge hanya untuk CPNS
  String? get badge => key == 'cpns' ? 'Paling Populer' : null;

  IconData get icon => switch (key) {
    'cpns' => LineIcons.userTie,
    'lpdp' => LineIcons.graduationCap,
    'bumn' => LineIcons.building,
    'pcpm' => LineIcons.university,
    _ => LineIcons.bullseye,
  };
}

class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedGoal;
  bool _isLoading = false;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // Tambahkan field ini di dalam _GoalSettingScreenState:
  List<_Goal> _goals = [];
  bool _goalsLoading = true;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    FirebaseFirestore.instance
        .collection('exam_types')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .get()
        .then((snap) {
          if (mounted) {
            setState(() {
              _goals = snap.docs.map(_Goal.fromDoc).toList();
              _goalsLoading = false;
            });
          }
        });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (_selectedGoal == null) {
      context.showError('Pilih tujuan kamu terlebih dahulu');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseService.instance.currentUser;
      if (user == null) throw Exception('User not found');
      await UserService.instance.createNewUser(
        userId: user.uid,
        email: user.email!,
        displayName: user.displayName,
        photoURL: user.photoURL,
        goal: _selectedGoal,
      );
      await StorageService.instance.setFirstLaunchCompleted();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.main,
        (route) => false,
      );
      context.showSuccess('Selamat datang di LulusASN! 🎉');
    } catch (e) {
      if (!mounted) return;
      context.showError('Gagal menyimpan data: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Row(
          children: [
            // ── Left panel (desktop only) ───────────────────────────
            if (!isMobile) _LeftPanel(size: size),

            // ── Main content ────────────────────────────────────────
            Expanded(
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
                        vertical: AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Step indicator ──────────────────────
                          _StepIndicator(current: 1, total: 2),
                          AppSpacing.vlg,

                          // ── Header ──────────────────────────────
                          Text('Apa tujuan\nkamu?', style: AppText.display),
                          AppSpacing.vsm,
                          Text(
                            'Pilih jalur ujian yang ingin kamu persiapkan. '
                            'Kami akan menyesuaikan materi latihan untukmu.',
                            style: AppText.bodyLg.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          AppSpacing.vxl,

                          // ── Goal cards ──────────────────────────
                          if (_goalsLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.xl,
                                ),
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else
                            ..._goals.asMap().entries.map((e) {
                              final idx = e.key;
                              final goal = e.value;
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: Duration(
                                  milliseconds: 300 + idx * 80,
                                ),
                                curve: Curves.easeOut,
                                builder: (ctx, v, child) => Transform.translate(
                                  offset: Offset(0, 20 * (1 - v)),
                                  child: Opacity(opacity: v, child: child),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: _GoalCard(
                                    goal: goal,
                                    isSelected:
                                        _selectedGoal ==
                                        goal.key, // ← pakai .key
                                    onTap: () => setState(
                                      () => _selectedGoal = goal.key,
                                    ), // ← pakai .key
                                  ),
                                ),
                              );
                            }),

                          AppSpacing.vxl,

                          // ── CTA button ──────────────────────────
                          _ContinueButton(
                            isLoading: _isLoading,
                            isEnabled: _selectedGoal != null,
                            onPressed: _onContinue,
                          ),

                          AppSpacing.vsm,
                          Center(
                            child: Text(
                              'Kamu bisa mengubah ini kapan saja di Pengaturan',
                              style: AppText.caption,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEFT PANEL  (desktop only — branding / illustration)
// ─────────────────────────────────────────────────────────────────────────────

class _LeftPanel extends StatelessWidget {
  final Size size;
  const _LeftPanel({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width * 0.38,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: AppGradient.navy),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: AppGradient.gold,
              borderRadius: AppRadius.bSm,
            ),
            child: Text(
              'LulusASN',
              style: AppText.h2.copyWith(color: AppColors.primary),
            ),
          ),
          const Spacer(),

          // Headline
          Text(
            'Wujudkan\nKarirmu\nBersama Kami.',
            style: AppText.display.copyWith(
              color: AppColors.white,
              height: 1.2,
              fontSize: 36,
            ),
          ),
          AppSpacing.vmd,
          Text(
            'Lebih dari 50.000 peserta telah berhasil lulus '
            'ujian seleksi dengan bantuan LulusASN.',
            style: AppText.body.copyWith(
              color: AppColors.white.withOpacity(0.7),
            ),
          ),
          AppSpacing.vxl,

          // Stat chips
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              _StatChip(value: '50K+', label: 'Peserta'),
              _StatChip(value: '10K+', label: 'Soal'),
              _StatChip(value: '98%', label: 'Puas'),
            ],
          ),
          AppSpacing.vxl,
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.08),
        borderRadius: AppRadius.bMd,
        border: Border.all(color: AppColors.white.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(value, style: AppText.h3.copyWith(color: AppColors.gold)),
          Text(
            label,
            style: AppText.caption.copyWith(
              color: AppColors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP INDICATOR
// ─────────────────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(total, (i) {
          final active = i < current;
          final isCurrent = i == current - 1;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary
                      : active
                      ? AppColors.gold
                      : AppColors.border,
                  borderRadius: AppRadius.bFull,
                ),
              ),
            ),
          );
        }),
        AppSpacing.hsm,
        Text(
          '$current / $total',
          style: AppText.label.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GOAL CARD
// ─────────────────────────────────────────────────────────────────────────────

class _GoalCard extends StatefulWidget {
  final _Goal goal;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goal,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;
    final hovered = _hovered || selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.04)
                : AppColors.surface,
            borderRadius: AppRadius.bLg,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: hovered ? AppShadow.md : AppShadow.sm,
          ),
          child: Row(
            children: [
              // Icon box
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: selected ? AppGradient.navy : null,
                  color: selected ? null : AppColors.surfaceAlt,
                  borderRadius: AppRadius.bMd,
                ),
                child: Icon(
                  widget.goal.icon,
                  size: 24,
                  color: selected ? AppColors.white : AppColors.textSecondary,
                ),
              ),

              AppSpacing.hmd,

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.goal.name,
                          style: AppText.h3.copyWith(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (widget.goal.badge != null) ...[
                          AppSpacing.hsm,
                          _Badge(label: widget.goal.badge!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(widget.goal.description, style: AppText.bodySm),
                  ],
                ),
              ),

              // Radio indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 14, color: AppColors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        gradient: AppGradient.gold,
        borderRadius: AppRadius.bFull,
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTINUE BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _ContinueButton extends StatefulWidget {
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _ContinueButton({
    required this.isLoading,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: widget.isEnabled ? AppGradient.navy : null,
          color: widget.isEnabled ? null : AppColors.border,
          borderRadius: AppRadius.bMd,
          boxShadow: widget.isEnabled && _hovered ? AppShadow.lg : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.bMd,
            onTap: (widget.isLoading || !widget.isEnabled)
                ? null
                : widget.onPressed,
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Lanjutkan', style: AppText.btnLg),
                        AppSpacing.hsm,
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
