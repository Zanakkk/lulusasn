// lib/features/admin/pages/dashboard_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../app/theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MOCK DATA  — ganti dengan Firestore stream nanti
// ══════════════════════════════════════════════════════════════════════════════
class _Mock {
  // KPI
  static const totalUsers = 3_847;
  static const newUsersToday = 47;
  static const totalTryouts = 128;
  static const activeTryouts = 94;
  static const pendingVerif = 23;
  static const totalSessions = 15_620;
  static const sessionsToday = 312;
  static const revenueMonth = 18_750_000;
  static const revenueGrowth = 12.4;

  // Registrasi 7 hari terakhir
  static const registrationWeek = [
    _Point('Sen', 12), _Point('Sel', 19), _Point('Rab', 8),
    _Point('Kam', 27), _Point('Jum', 34), _Point('Sab', 41),
    _Point('Min', 29),
  ];

  // Sesi tryout 7 hari
  static const sessionsWeek = [
    _Point('Sen', 210), _Point('Sel', 290), _Point('Rab', 180),
    _Point('Kam', 340), _Point('Jum', 420), _Point('Sab', 510),
    _Point('Min', 312),
  ];

  // Distribusi goal
  static const goalDist = [
    _Slice('CPNS',  38, Color(0xFF3B82F6)),
    _Slice('LPDP',  22, Color(0xFFD4AF37)),
    _Slice('BUMN',  25, Color(0xFF10B981)),
    _Slice('PCPM',  15, Color(0xFFEF4444)),
  ];

  // Tryout terpopuler
  static const popularTO = [
    _TryoutRow('TO CPNS SKD Paket A', 'CPNS', 892, 4.8, true),
    _TryoutRow('Simulasi LPDP Essay', 'LPDP', 641, 4.6, true),
    _TryoutRow('BUMN Basic Ability', 'BUMN', 578, 4.7, true),
    _TryoutRow('PCPM BI Batch 3',    'PCPM', 430, 4.5, true),
    _TryoutRow('TO CPNS TKP Focus',  'CPNS', 387, 4.4, false),
  ];

  // Recent verifikasi
  static const recentVerif = [
    _VerifRow('Budi Santoso',   'TO CPNS SKD Paket A', '2 mnt lalu',  'pending'),
    _VerifRow('Sari Dewi',      'Simulasi LPDP Essay', '15 mnt lalu', 'pending'),
    _VerifRow('Rizky Pratama',  'BUMN Basic Ability',  '1 jam lalu',  'approved'),
    _VerifRow('Ani Rahayu',     'PCPM BI Batch 3',     '2 jam lalu',  'rejected'),
    _VerifRow('Dani Kusuma',    'TO CPNS TKP Focus',   '3 jam lalu',  'approved'),
  ];

  // Passing rate per subtes CPNS (sample)
  static const passRate = [
    _Point('TWK', 62), _Point('TIU', 48), _Point('TKP', 71),
  ];
}

class _Point { final String l; final num v; const _Point(this.l, this.v); }
class _Slice { final String l; final double pct; final Color c; const _Slice(this.l, this.pct, this.c); }
class _TryoutRow { final String title, cat; final int sessions; final double rating; final bool active; const _TryoutRow(this.title, this.cat, this.sessions, this.rating, this.active); }
class _VerifRow { final String user, tryout, time, status; const _VerifRow(this.user, this.tryout, this.time, this.status); }

final _rp = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0, locale: 'id');
final _num = NumberFormat.decimalPattern('id');

// ══════════════════════════════════════════════════════════════════════════════
// ENTRY POINT
// ══════════════════════════════════════════════════════════════════════════════
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _period = 'Minggu Ini';
  final _periods = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Tahun Ini'];

  @override
  Widget build(BuildContext context) {
    final isMobile  = AppResponsive.isMobile(context);
    final isTablet  = AppResponsive.isTablet(context);
    final pad       = isMobile ? 16.0 : isTablet ? 20.0 : 28.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(isMobile),
            SizedBox(height: isMobile ? 16 : 24),

            // ── KPI Row ────────────────────────────────────────────────────
            _buildKpiRow(isMobile, isTablet),
            SizedBox(height: isMobile ? 16 : 24),

            // ── Charts Row ─────────────────────────────────────────────────
            isMobile
                ? Column(children: [
              _buildRegistrationChart(),
              const SizedBox(height: 16),
              _buildSessionChart(),
            ])
                : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _buildRegistrationChart()),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildSessionChart()),
            ]),

            SizedBox(height: isMobile ? 16 : 24),

            // ── Middle Row: Goal Dist + Passing Rate ───────────────────────
            isMobile
                ? Column(children: [
              _buildGoalDistribution(),
              const SizedBox(height: 16),
              _buildPassingRate(),
            ])
                : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _buildGoalDistribution()),
              const SizedBox(width: 16),
              Expanded(child: _buildPassingRate()),
            ]),

            SizedBox(height: isMobile ? 16 : 24),

            // ── Bottom Row: Popular TO + Verif Queue ───────────────────────
            isMobile
                ? Column(children: [
              _buildPopularTryouts(),
              const SizedBox(height: 16),
              _buildVerifQueue(),
            ])
                : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _buildPopularTryouts()),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildVerifQueue()),
            ]),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Page Header ────────────────────────────────────────────────────────────
  Widget _buildPageHeader(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard', style: AppText.h1),
              const SizedBox(height: 2),
              Text(
                'Ringkasan performa platform hari ini',
                style: AppText.bodySm,
              ),
            ],
          ),
        ),
        if (!isMobile) ...[
          // Period selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.bMd,
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _period,
                isDense: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                style: AppText.label.copyWith(color: AppColors.textPrimary),
                items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _period = v!),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Refresh
          _IconBtn(icon: Icons.refresh_rounded, onTap: () => setState(() {})),
          const SizedBox(width: 8),
          // Export
          _PrimaryBtn(
            label: 'Export',
            icon: Icons.download_rounded,
            onTap: () {},
          ),
        ],
      ],
    );
  }

  // ── KPI Cards ──────────────────────────────────────────────────────────────
  Widget _buildKpiRow(bool isMobile, bool isTablet) {
    final kpis = [
      _KpiData(
        label: 'Total Pengguna',
        value: _num.format(_Mock.totalUsers),
        sub: '+${_Mock.newUsersToday} hari ini',
        icon: Icons.people_rounded,
        color: AppColors.info,
        trend: true,
      ),
      _KpiData(
        label: 'Sesi Tryout',
        value: _num.format(_Mock.sessionsToday),
        sub: 'Total ${_num.format(_Mock.totalSessions)}',
        icon: Icons.quiz_rounded,
        color: AppColors.success,
        trend: true,
      ),
      _KpiData(
        label: 'Pending Verifikasi',
        value: '${_Mock.pendingVerif}',
        sub: 'Menunggu review',
        icon: Icons.pending_actions_rounded,
        color: AppColors.warning,
        trend: false,
        urgent: true,
      ),
      _KpiData(
        label: 'Pendapatan Bulan Ini',
        value: _rp.format(_Mock.revenueMonth),
        sub: '+${_Mock.revenueGrowth}% vs bulan lalu',
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.gold,
        trend: true,
      ),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: kpis.map(_KpiCard.new).toList(),
      );
    }

    return Row(
      children: kpis.map((k) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: k == kpis.last ? 0 : 14),
          child: _KpiCard(k),
        ),
      )).toList(),
    );
  }

  // ── Registration Chart ─────────────────────────────────────────────────────
  Widget _buildRegistrationChart() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Registrasi Pengguna',
            subtitle: '7 hari terakhir',
            trailing: _TrendBadge(value: '+18%', up: true),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: _AreaChartWidget(
              data: _Mock.registrationWeek,
              color: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  // ── Session Chart ──────────────────────────────────────────────────────────
  Widget _buildSessionChart() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Sesi Tryout',
            subtitle: '7 hari terakhir',
            trailing: _TrendBadge(value: '+24%', up: true),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: _BarChartWidget(
              data: _Mock.sessionsWeek,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Goal Distribution ──────────────────────────────────────────────────────
  Widget _buildGoalDistribution() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(title: 'Distribusi Tujuan', subtitle: 'Semua pengguna aktif'),
          const SizedBox(height: 20),
          Row(
            children: [
              // Donut
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(130, 130),
                      painter: _DonutPainter(_Mock.goalDist),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${_Mock.totalUsers}', style: AppText.h2),
                        Text('users', style: AppText.caption),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Legend
              Expanded(
                child: Column(
                  children: _Mock.goalDist.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(color: s.c, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s.l, style: AppText.label)),
                      Text('${s.pct.toInt()}%',
                          style: AppText.label.copyWith(color: s.c)),
                    ]),
                  )).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Passing Rate ───────────────────────────────────────────────────────────
  Widget _buildPassingRate() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Passing Rate Subtes',
            subtitle: 'CPNS — rata-rata semua peserta',
          ),
          const SizedBox(height: 20),
          ..._Mock.passRate.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _PassBar(label: p.l, value: p.v.toDouble()),
          )),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: AppRadius.bMd,
              border: Border.all(color: AppColors.warning.withOpacity(0.25)),
            ),
            child: Row(children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 15, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'TIU memiliki passing rate terendah. Pertimbangkan menambah materi latihan TIU.',
                style: AppText.caption.copyWith(color: AppColors.textPrimary),
              )),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Popular Tryouts ────────────────────────────────────────────────────────
  Widget _buildPopularTryouts() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Tryout Terpopuler',
            subtitle: 'Berdasarkan jumlah sesi',
            trailing: TextButton(
              onPressed: () {},
              child: Text('Lihat Semua',
                  style: AppText.label.copyWith(color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 8),
          // Table header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(children: [
              Expanded(flex: 5, child: Text('Tryout', style: AppText.caption)),
              Expanded(flex: 2, child: Text('Kategori', style: AppText.caption)),
              Expanded(flex: 2, child: Text('Sesi', style: AppText.caption, textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text('Rating', style: AppText.caption, textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text('Status', style: AppText.caption, textAlign: TextAlign.center)),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),
          ..._Mock.popularTO.asMap().entries.map((e) => _TryoutRowWidget(
            rank: e.key + 1,
            row: e.value,
          )),
        ],
      ),
    );
  }

  // ── Verification Queue ─────────────────────────────────────────────────────
  Widget _buildVerifQueue() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Antrian Verifikasi',
            subtitle: '${_Mock.pendingVerif} menunggu',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: AppRadius.bFull,
              ),
              child: Text(
                '${_Mock.pendingVerif} pending',
                style: AppText.caption.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ..._Mock.recentVerif.map(_VerifRowWidget.new),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.open_in_new_rounded, size: 15),
              label: const Text('Lihat Semua Antrian'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border),
                minimumSize: const Size(0, 40),
                textStyle: AppText.label.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

// ── Card Shell ─────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.bLg,
      border: Border.all(color: AppColors.border),
      boxShadow: AppShadow.sm,
    ),
    child: child,
  );
}

// ── Card Header ────────────────────────────────────────────────────────────
class _CardHeader extends StatelessWidget {
  final String title, subtitle;
  final Widget? trailing;
  const _CardHeader({required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.h3),
          const SizedBox(height: 2),
          Text(subtitle, style: AppText.bodySm),
        ],
      )),
      if (trailing != null) trailing!,
    ],
  );
}

// ── KPI Data Model ─────────────────────────────────────────────────────────
class _KpiData {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  final bool trend, urgent;
  const _KpiData({
    required this.label, required this.value, required this.sub,
    required this.icon, required this.color,
    this.trend = false, this.urgent = false,
  });
}

// ── KPI Card ───────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final _KpiData d;
  const _KpiCard(this.d, {super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bLg,
        border: Border.all(
          color: d.urgent ? AppColors.warning.withOpacity(0.4) : AppColors.border,
        ),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: d.color.withOpacity(0.10),
                borderRadius: AppRadius.bSm,
              ),
              child: Icon(d.icon, size: isMobile ? 16 : 20, color: d.color),
            ),
            const Spacer(),
            if (d.urgent)
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.warning, shape: BoxShape.circle,
                ),
              ),
          ]),
          const SizedBox(height: 16),
          Text(d.value,
            style: (isMobile ? AppText.h3 : AppText.h2).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(d.label,
            style: AppText.caption.copyWith(fontSize: isMobile ? 10 : 11),
          ),
          const SizedBox(height: 4),
          Row(children: [
            if (d.trend)
              Icon(Icons.trending_up_rounded, size: 12, color: AppColors.success),
            const SizedBox(width: 3),
            Expanded(child: Text(
              d.sub,
              style: AppText.caption.copyWith(
                fontSize: 10,
                color: d.trend ? AppColors.success : AppColors.textHint,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
          ]),
        ],
      ),
    );
  }
}

// ── Trend Badge ────────────────────────────────────────────────────────────
class _TrendBadge extends StatelessWidget {
  final String value;
  final bool up;
  const _TrendBadge({required this.value, required this.up});

  @override
  Widget build(BuildContext context) {
    final c = up ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: AppRadius.bFull,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 11, color: c),
        const SizedBox(width: 3),
        Text(value, style: AppText.caption.copyWith(color: c, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ── Area Chart ─────────────────────────────────────────────────────────────
class _AreaChartWidget extends StatelessWidget {
  final List<_Point> data;
  final Color color;
  const _AreaChartWidget({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AreaPainter(data: data, color: color),
      child: const SizedBox.expand(),
    );
  }
}

class _AreaPainter extends CustomPainter {
  final List<_Point> data;
  final Color color;
  _AreaPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxV = data.map((p) => p.v).reduce((a, b) => a > b ? a : b).toDouble();
    final minV = 0.0;
    final range = maxV - minV == 0 ? 1.0 : maxV - minV;
    final pts = <Offset>[];

    for (var i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - ((data[i].v - minV) / range * (size.height * 0.85));
      pts.add(Offset(x, y));
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Area fill
    final path = Path()..moveTo(pts.first.dx, size.height);
    for (var i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
    }
    path..lineTo(pts.last.dx, size.height)..close();
    canvas.drawPath(path,
        Paint()..shader = LinearGradient(
          colors: [color.withOpacity(0.18), color.withOpacity(0.01)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    // Line
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
    }
    canvas.drawPath(linePath,
        Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    // Dots + labels
    final dotPaint = Paint()..color = AppColors.surface..strokeWidth = 2.5..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < pts.length; i++) {
      canvas.drawCircle(pts[i], 4, dotPaint);
      canvas.drawCircle(pts[i], 4, dotBorderPaint);
      // X label
      tp.text = TextSpan(
        text: data[i].l,
        style: const TextStyle(fontSize: 10, color: AppColors.textHint, fontWeight: FontWeight.w500),
      );
      tp.layout();
      tp.paint(canvas, Offset(pts[i].dx - tp.width / 2, size.height + 4));
    }
  }

  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Bar Chart ──────────────────────────────────────────────────────────────
class _BarChartWidget extends StatelessWidget {
  final List<_Point> data;
  final Color color;
  const _BarChartWidget({required this.data, required this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _BarPainter(data: data, color: color),
    child: const SizedBox.expand(),
  );
}

class _BarPainter extends CustomPainter {
  final List<_Point> data;
  final Color color;
  _BarPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxV = data.map((p) => p.v).reduce((a, b) => a > b ? a : b).toDouble();
    final barW = size.width / (data.length * 1.8);
    final gap = size.width / data.length;
    final gridPaint = Paint()..color = AppColors.border..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < data.length; i++) {
      final x = gap * i + gap / 2 - barW / 2;
      final h = (data[i].v / maxV) * size.height * 0.85;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, size.height - h, barW, h),
        topLeft: const Radius.circular(5), topRight: const Radius.circular(5),
      );
      canvas.drawRRect(rect,
          Paint()..shader = LinearGradient(
            colors: [color, color.withOpacity(0.5)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(x, size.height - h, barW, h)));
      tp.text = TextSpan(
        text: data[i].l,
        style: const TextStyle(fontSize: 10, color: AppColors.textHint, fontWeight: FontWeight.w500),
      );
      tp.layout();
      tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, size.height + 4));
    }
  }

  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Donut Painter ──────────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final List<_Slice> slices;
  _DonutPainter(this.slices);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 18..strokeCap = StrokeCap.round;
    const gap = 0.04;
    const startAngle = -1.5708;
    double angle = startAngle;
    final total = slices.fold(0.0, (s, e) => s + e.pct);
    for (final sl in slices) {
      final sweep = (sl.pct / total) * (2 * 3.14159) - gap;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r - 9), angle, sweep, false, p..color = sl.c);
      angle += sweep + gap;
    }
  }

  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Pass Bar ───────────────────────────────────────────────────────────────
class _PassBar extends StatelessWidget {
  final String label;
  final double value;
  const _PassBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value >= 70
        ? AppColors.success
        : value >= 55 ? AppColors.warning : AppColors.error;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label, style: AppText.label),
        const Spacer(),
        Text('${value.toInt()}%',
            style: AppText.label.copyWith(color: color)),
        const SizedBox(width: 6),
        Text('/ 70% passing',
            style: AppText.caption.copyWith(fontSize: 10)),
      ]),
      const SizedBox(height: 6),
      Stack(children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: AppRadius.bFull,
          ),
        ),
        FractionallySizedBox(
          widthFactor: value / 100,
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.bFull,
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4)],
            ),
          ),
        ),
        // Passing grade marker at 70%
        Positioned(
          left: null,
          right: null,
          child: FractionallySizedBox(
            widthFactor: 0.70,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(width: 2, height: 8, color: AppColors.textHint),
            ),
          ),
        ),
      ]),
    ]);
  }
}

// ── Tryout Row ─────────────────────────────────────────────────────────────
class _TryoutRowWidget extends StatelessWidget {
  final int rank;
  final _TryoutRow row;
  const _TryoutRowWidget({required this.rank, required this.row, super.key});

  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 1 ? AppColors.gold
        : rank == 2 ? AppColors.textSecondary
        : rank == 3 ? const Color(0xFFB08D57)
        : AppColors.textHint;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        Expanded(flex: 5, child: Row(children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.12),
              borderRadius: AppRadius.bSm,
            ),
            child: Center(child: Text('$rank',
              style: AppText.caption.copyWith(
                color: rankColor, fontWeight: FontWeight.w800, fontSize: 10,
              ),
            )),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(row.title,
            style: AppText.label.copyWith(color: AppColors.textPrimary),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          )),
        ])),
        Expanded(flex: 2, child: _CatChip(row.cat)),
        Expanded(flex: 2, child: Text(
          NumberFormat.compact(locale: 'id').format(row.sessions),
          style: AppText.label, textAlign: TextAlign.center,
        )),
        Expanded(flex: 2, child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_rounded, size: 12, color: AppColors.gold),
            const SizedBox(width: 3),
            Text('${row.rating}', style: AppText.label),
          ],
        )),
        Expanded(flex: 2, child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: (row.active ? AppColors.success : AppColors.error).withOpacity(0.10),
            borderRadius: AppRadius.bFull,
          ),
          child: Text(
            row.active ? 'Aktif' : 'Draft',
            style: AppText.caption.copyWith(
              color: row.active ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w700, fontSize: 10,
            ),
          ),
        ))),
      ]),
    );
  }
}

// ── Category Chip ──────────────────────────────────────────────────────────
class _CatChip extends StatelessWidget {
  final String cat;
  const _CatChip(this.cat);

  Color get _color => switch (cat) {
    'CPNS' => AppColors.info,
    'LPDP' => AppColors.gold,
    'BUMN' => AppColors.success,
    'PCPM' => AppColors.error,
    _      => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: _color.withOpacity(0.10),
      borderRadius: AppRadius.bFull,
    ),
    child: Text(cat,
      style: AppText.caption.copyWith(
        color: _color, fontWeight: FontWeight.w700, fontSize: 10,
      ),
    ),
  );
}

// ── Verif Row ──────────────────────────────────────────────────────────────
class _VerifRowWidget extends StatelessWidget {
  final _VerifRow row;
  const _VerifRowWidget(this.row, {super.key});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (row.status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      _          => AppColors.warning,
    };
    final statusLabel = switch (row.status) {
      'approved' => 'Disetujui',
      'rejected' => 'Ditolak',
      _          => 'Pending',
    };
    final statusIcon = switch (row.status) {
      'approved' => Icons.check_circle_rounded,
      'rejected' => Icons.cancel_rounded,
      _          => Icons.pending_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        // Avatar
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            gradient: AppGradient.navy,
            borderRadius: AppRadius.bSm,
          ),
          child: Center(child: Text(
            row.user[0],
            style: AppText.label.copyWith(color: AppColors.gold),
          )),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(row.user,
              style: AppText.label.copyWith(color: AppColors.textPrimary),
            ),
            Text(row.tryout,
              style: AppText.caption.copyWith(fontSize: 10),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.10),
              borderRadius: AppRadius.bFull,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(statusIcon, size: 10, color: statusColor),
              const SizedBox(width: 3),
              Text(statusLabel,
                style: AppText.caption.copyWith(
                  color: statusColor, fontWeight: FontWeight.w700, fontSize: 10,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 3),
          Text(row.time, style: AppText.caption.copyWith(fontSize: 10)),
        ]),
      ]),
    );
  }
}

// ── Icon Button ────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: AppRadius.bMd,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, size: 18, color: AppColors.textSecondary),
    ),
  );
}

// ── Primary Button ─────────────────────────────────────────────────────────
class _PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: AppRadius.bMd,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppGradient.navy,
        borderRadius: AppRadius.bMd,
        boxShadow: AppShadow.sm,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: AppColors.gold),
        const SizedBox(width: 6),
        Text(label, style: AppText.label.copyWith(color: AppColors.white)),
      ]),
    ),
  );
}