// lib/features/admin/pages/dashboard_screen.dart
// ignore_for_file: deprecated_member_use, unused_local_variable, curly_braces_in_flow_control_structures

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../app/theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════

class _DashboardData {
  // Users
  final int totalUsers;
  final int newUsersToday;
  final Map<String, int> goalDist; // goal → count
  final List<_Point> registrationWeek; // last 7 days

  // Tryouts
  final int totalTryouts;
  final int activeTryouts;
  final List<_TryoutStat> popularTryouts;

  // Sessions (user_tryouts)
  final int totalSessions;
  final int sessionsToday;
  final List<_Point> sessionsWeek;
  final double completionRate; // completed / total sessions

  // Verification
  final int pendingVerif;
  final int approvedVerif;
  final int rejectedVerif;
  final List<_VerifItem> recentVerif;

  // Exam results
  final Map<String, double> avgScoreByCategory; // category → avg score %
  final Map<String, double> passRateByCategory; // category → pass rate %

  // Revenue (price × user_tryouts)
  final int revenueTotal;
  final int revenueMonth;

  const _DashboardData({
    required this.totalUsers,
    required this.newUsersToday,
    required this.goalDist,
    required this.registrationWeek,
    required this.totalTryouts,
    required this.activeTryouts,
    required this.popularTryouts,
    required this.totalSessions,
    required this.sessionsToday,
    required this.sessionsWeek,
    required this.completionRate,
    required this.pendingVerif,
    required this.approvedVerif,
    required this.rejectedVerif,
    required this.recentVerif,
    required this.avgScoreByCategory,
    required this.passRateByCategory,
    required this.revenueTotal,
    required this.revenueMonth,
  });

  static _DashboardData empty() => _DashboardData(
    totalUsers: 0,
    newUsersToday: 0,
    goalDist: {},
    registrationWeek: [],
    totalTryouts: 0,
    activeTryouts: 0,
    popularTryouts: [],
    totalSessions: 0,
    sessionsToday: 0,
    sessionsWeek: [],
    completionRate: 0,
    pendingVerif: 0,
    approvedVerif: 0,
    rejectedVerif: 0,
    recentVerif: [],
    avgScoreByCategory: {},
    passRateByCategory: {},
    revenueTotal: 0,
    revenueMonth: 0,
  );
}

class _Point {
  final String l;
  final num v;
  const _Point(this.l, this.v);
}

class _Slice {
  final String l;
  final double pct;
  final Color c;
  const _Slice(this.l, this.pct, this.c);
}

class _TryoutStat {
  final String id, title, cat;
  final int sessions;
  final bool active;
  const _TryoutStat(this.id, this.title, this.cat, this.sessions, this.active);
}

class _VerifItem {
  final String user, tryout, time, status, userId, tryoutId;
  const _VerifItem(
    this.user,
    this.tryout,
    this.time,
    this.status,
    this.userId,
    this.tryoutId,
  );
}

final _rp = NumberFormat.currency(
  symbol: 'Rp ',
  decimalDigits: 0,
  locale: 'id',
);
final _num = NumberFormat.decimalPattern('id');

// Goal color map
Color _goalColor(String goal) => switch (goal.toLowerCase()) {
  'cpns' => AppColors.info,
  'lpdp' => const Color(0xFFD4AF37),
  'bumn' => AppColors.success,
  'pcpm' => AppColors.error,
  'pppk' => const Color(0xFF8B5CF6),
  _ => AppColors.textSecondary,
};

// ══════════════════════════════════════════════════════════════════════════════
// FIRESTORE SERVICE
// ══════════════════════════════════════════════════════════════════════════════

class _DashboardService {
  static final _db = FirebaseFirestore.instance;

  static Future<_DashboardData> fetch() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);
    final week7 = now.subtract(const Duration(days: 6));
    final weekStart = DateTime(week7.year, week7.month, week7.day);

    // ── Parallel fetch ────────────────────────────────────────────────────
    final results = await Future.wait([
      _db.collection('users').get(), // 0
      _db.collection('tryouts').get(), // 1
      _db.collection('user_tryouts').get(), // 2
      _db.collection('exam_results').get(), // 3
    ]);

    final userDocs = results[0].docs;
    final tryoutDocs = results[1].docs;
    final utDocs = results[2].docs; // user_tryouts
    final resultDocs = results[3].docs; // exam_results

    // ── USERS ──────────────────────────────────────────────────────────────
    int newToday = 0;
    final goalCount = <String, int>{};
    final regByDay = <String, int>{}; // "dd/MM" → count

    // Seed last 7 days with 0
    for (var i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      regByDay[DateFormat('dd/MM').format(d)] = 0;
    }

    for (final doc in userDocs) {
      final data = doc.data();
      // skip admin accounts
      if (data['admin'] == true) continue;

      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        if (createdAt.isAfter(todayStart)) newToday++;
        if (createdAt.isAfter(weekStart)) {
          final key = DateFormat('dd/MM').format(createdAt);
          if (regByDay.containsKey(key)) regByDay[key] = regByDay[key]! + 1;
        }
      }

      final goal = (data['goal'] as String? ?? 'lainnya').toLowerCase();
      goalCount[goal] = (goalCount[goal] ?? 0) + 1;
    }

    final regWeek = regByDay.entries
        .map((e) => _Point(e.key, e.value))
        .toList();

    // ── TRYOUTS ────────────────────────────────────────────────────────────
    int activeTryouts = 0;
    final tryoutMap = <String, Map<String, dynamic>>{};
    for (final doc in tryoutDocs) {
      final data = doc.data();
      tryoutMap[doc.id] = {...data, '__id': doc.id};
      if (data['isActive'] == true) activeTryouts++;
    }

    // ── USER_TRYOUTS (sessions) ────────────────────────────────────────────
    int sessToday = 0;
    int pendingV = 0, approvedV = 0, rejectedV = 0;
    int freeApproved = 0; // user jalur gratis yang sudah diverifikasi
    final sessionByDay = <String, int>{};
    final sessionsByTO = <String, int>{};
    final recentVerifRaw = <Map<String, dynamic>>[];
    int revenueTotal = 0, revenueMonth = 0;

    // Seed last 7 days
    for (var i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      sessionByDay[DateFormat('dd/MM').format(d)] = 0;
    }

    for (final doc in utDocs) {
      final data = doc.data();
      final lastAttempt = (data['lastAttemptAt'] as Timestamp?)?.toDate();
      final submitted = (data['submittedAt'] as Timestamp?)?.toDate();

      // Session count
      if (lastAttempt != null) {
        if (lastAttempt.isAfter(todayStart)) sessToday++;
        if (lastAttempt.isAfter(weekStart)) {
          final key = DateFormat('dd/MM').format(lastAttempt);
          if (sessionByDay.containsKey(key)) {
            sessionByDay[key] = sessionByDay[key]! + 1;
          }
        }
      }

      // Track sessions per tryout
      final tid = data['tryoutId'] as String? ?? '';
      if (tid.isNotEmpty) sessionsByTO[tid] = (sessionsByTO[tid] ?? 0) + 1;

      // accessType: 'paid' | 'free'
      final accessType = data['accessType'] as String? ?? 'free';
      // paymentStatus: 'paid' | 'pending' — hanya untuk jalur paid
      final paymentStatus = data['paymentStatus'] as String? ?? '';
      // proofStatus: 'pending' | 'approved' | 'rejected' — hanya untuk jalur free
      final proofStatus = data['proofStatus'] as String? ?? '';

      // ── Verifikasi: hanya jalur free ─────────────────────────────────
      if (accessType == 'free' && proofStatus.isNotEmpty) {
        switch (proofStatus) {
          case 'pending':
            pendingV++;
            break;
          case 'approved':
            approvedV++;
            freeApproved++;
            break;
          case 'rejected':
            rejectedV++;
            break;
        }
        if (submitted != null &&
            submitted.isAfter(now.subtract(const Duration(days: 3)))) {
          recentVerifRaw.add({
            ...data,
            '__docId': doc.id,
            'submittedAt': submitted,
          });
        }
      }

      // ── Revenue: hanya jalur paid yang sudah terkonfirmasi ────────────
      if (accessType == 'paid' && paymentStatus == 'paid') {
        final tData = tryoutMap[tid];
        if (tData != null) {
          final price = (tData['price'] as num? ?? 0).toInt();
          if (price > 0) {
            revenueTotal += price;
            // Gunakan paidAt jika ada, fallback ke lastAttempt
            final paidAt =
                (data['paidAt'] as Timestamp?)?.toDate() ?? lastAttempt;
            if (paidAt != null && paidAt.isAfter(monthStart)) {
              revenueMonth += price;
            }
          }
        }
      }
    }

    final sessWeek = sessionByDay.entries
        .map((e) => _Point(e.key, e.value))
        .toList();

    // ── Popular tryouts ────────────────────────────────────────────────────
    final sorted = sessionsByTO.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final popularTryouts = sorted.take(5).map((e) {
      final td = tryoutMap[e.key];
      return _TryoutStat(
        e.key,
        td?['title'] as String? ?? '—',
        td?['examTypeName'] as String? ?? '—',
        e.value,
        td?['isActive'] as bool? ?? false,
      );
    }).toList();

    // ── Recent verif ───────────────────────────────────────────────────────
    recentVerifRaw.sort((a, b) {
      final ta = (a['submittedAt'] as DateTime);
      final tb = (b['submittedAt'] as DateTime);
      return tb.compareTo(ta);
    });

    // Fetch user display names for verif items (batch, max 10)
    final verifUserIds = recentVerifRaw
        .take(8)
        .map((e) => e['userId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final userNameMap = <String, String>{};
    if (verifUserIds.isNotEmpty) {
      // Firestore whereIn limit = 30
      final uSnap = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: verifUserIds)
          .get();
      for (final d in uSnap.docs) {
        userNameMap[d.id] = d.data()['displayName'] as String? ?? 'User';
      }
    }

    final recentVerif = recentVerifRaw.take(6).map((e) {
      final uid = e['userId'] as String? ?? '';
      final tid = e['tryoutId'] as String? ?? '';
      final dt = e['submittedAt'] as DateTime;
      final diff = now.difference(dt);
      String timeStr;
      if (diff.inMinutes < 60) {
        timeStr = '${diff.inMinutes} mnt lalu';
      } else if (diff.inHours < 24)
        timeStr = '${diff.inHours} jam lalu';
      else
        timeStr = '${diff.inDays} hari lalu';

      return _VerifItem(
        userNameMap[uid] ?? 'User',
        tryoutMap[tid]?['title'] as String? ?? '—',
        timeStr,
        e['proofStatus'] as String? ?? '',
        uid,
        tid,
      );
    }).toList();

    // ── EXAM RESULTS ───────────────────────────────────────────────────────
    final catScoreSum = <String, double>{};
    final catScoreCount = <String, int>{};
    final catPassCount = <String, int>{};
    const passingScore = 70.0; // threshold passing grade

    for (final doc in resultDocs) {
      final data = doc.data();
      final catScores = data['categoryScores'] as Map<String, dynamic>? ?? {};
      for (final entry in catScores.entries) {
        final cat = entry.key;
        final cMap = entry.value as Map<String, dynamic>? ?? {};
        final pct = (cMap['percentage'] as num? ?? 0).toDouble();
        catScoreSum[cat] = (catScoreSum[cat] ?? 0) + pct;
        catScoreCount[cat] = (catScoreCount[cat] ?? 0) + 1;
        if (pct >= passingScore) {
          catPassCount[cat] = (catPassCount[cat] ?? 0) + 1;
        }
      }
    }

    final avgScore = <String, double>{};
    final passRate = <String, double>{};
    for (final cat in catScoreSum.keys) {
      final cnt = catScoreCount[cat] ?? 1;
      avgScore[cat] = catScoreSum[cat]! / cnt;
      passRate[cat] = ((catPassCount[cat] ?? 0) / cnt) * 100;
    }

    // ── COMPLETION RATE ────────────────────────────────────────────────────
    int completedSessions = 0;
    for (final doc in utDocs) {
      final prog = doc.data()['subtestProgress'] as Map<String, dynamic>? ?? {};
      final anyCompleted = prog.values.any((v) {
        if (v is Map) return v['status'] == 'completed';
        return false;
      });
      if (anyCompleted) completedSessions++;
    }
    final completionRate = utDocs.isEmpty
        ? 0.0
        : completedSessions / utDocs.length * 100;

    return _DashboardData(
      totalUsers: userDocs.where((d) => d.data()['admin'] != true).length,
      newUsersToday: newToday,
      goalDist: goalCount,
      registrationWeek: regWeek,
      totalTryouts: tryoutDocs.length,
      activeTryouts: activeTryouts,
      popularTryouts: popularTryouts,
      totalSessions: utDocs.length,
      sessionsToday: sessToday,
      sessionsWeek: sessWeek,
      completionRate: completionRate,
      pendingVerif: pendingV,
      approvedVerif: approvedV,
      rejectedVerif: rejectedV,
      recentVerif: recentVerif,
      avgScoreByCategory: avgScore,
      passRateByCategory: passRate,
      revenueTotal: revenueTotal,
      revenueMonth: revenueMonth,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  _DashboardData _data = _DashboardData.empty();
  bool _loading = true;
  String? _error;
  DateTime _lastRefresh = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _DashboardService.fetch();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
        _lastRefresh = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);
    final isTablet = AppResponsive.isTablet(context);
    final pad = isMobile
        ? 16.0
        : isTablet
        ? 20.0
        : 28.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _error != null
            ? _ErrorView(error: _error!, onRetry: _load)
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(pad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isMobile),
                    SizedBox(height: isMobile ? 16 : 24),

                    // ── KPI Row ─────────────────────────────────────────────
                    _buildKpiRow(isMobile, isTablet),
                    SizedBox(height: isMobile ? 16 : 24),

                    // ── Insight Banner (actionable) ──────────────────────────
                    if (_data.pendingVerif > 0) ...[
                      _InsightBanner(
                        icon: Icons.pending_actions_rounded,
                        color: AppColors.warning,
                        message:
                            '${_data.pendingVerif} bukti pembayaran menunggu verifikasi. Segera review agar pengguna bisa mengakses tryout.',
                        action: 'Review Sekarang',
                        onAction: () {}, // Navigate to verif screen
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                    ],

                    // ── Charts Row ───────────────────────────────────────────
                    isMobile
                        ? Column(
                            children: [
                              _buildRegChart(),
                              const SizedBox(height: 16),
                              _buildSessionChart(),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: _buildRegChart()),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: _buildSessionChart()),
                            ],
                          ),
                    SizedBox(height: isMobile ? 16 : 24),

                    // ── Goal Dist + Pass Rate ────────────────────────────────
                    isMobile
                        ? Column(
                            children: [
                              _buildGoalDist(),
                              const SizedBox(height: 16),
                              _buildPassRate(),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildGoalDist()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildPassRate()),
                            ],
                          ),
                    SizedBox(height: isMobile ? 16 : 24),

                    // ── Popular TO + Verif Queue ─────────────────────────────
                    isMobile
                        ? Column(
                            children: [
                              _buildPopularTO(),
                              const SizedBox(height: 16),
                              _buildVerifQueue(),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: _buildPopularTO()),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: _buildVerifQueue()),
                            ],
                          ),

                    const SizedBox(height: 24),

                    // Last refresh
                    Center(
                      child: Text(
                        'Terakhir diperbarui: ${DateFormat('HH:mm:ss').format(_lastRefresh)}',
                        style: AppText.caption,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard Admin', style: AppText.h1),
              const SizedBox(height: 2),
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                style: AppText.bodySm,
              ),
            ],
          ),
        ),
        if (!isMobile) ...[
          _IconBtn(icon: Icons.refresh_rounded, onTap: _load),
          const SizedBox(width: 8),
          _PrimaryBtn(
            label: 'Refresh Data',
            icon: Icons.sync_rounded,
            onTap: _load,
          ),
        ],
      ],
    );
  }

  // ── KPI Cards ───────────────────────────────────────────────────────────────
  Widget _buildKpiRow(bool isMobile, bool isTablet) {
    final kpis = [
      _KpiData(
        label: 'Total Pengguna',
        value: _num.format(_data.totalUsers),
        sub: '+${_data.newUsersToday} registrasi hari ini',
        icon: Icons.people_rounded,
        color: AppColors.info,
        trend: _data.newUsersToday > 0,
      ),
      _KpiData(
        label: 'Sesi Tryout',
        value: _num.format(_data.sessionsToday),
        sub:
            'Total ${_num.format(_data.totalSessions)} · CR ${_data.completionRate.toStringAsFixed(0)}%',
        icon: Icons.quiz_rounded,
        color: AppColors.success,
        trend: _data.sessionsToday > 0,
      ),
      _KpiData(
        label: 'Pending Verifikasi',
        value: '${_data.pendingVerif}',
        sub:
            '${_data.approvedVerif} disetujui · ${_data.rejectedVerif} ditolak',
        icon: Icons.pending_actions_rounded,
        color: AppColors.warning,
        trend: false,
        urgent: _data.pendingVerif > 0,
      ),
      _KpiData(
        label: 'Pendapatan Bulan Ini',
        value: _rp.format(_data.revenueMonth),
        sub: 'Total ${_rp.format(_data.revenueTotal)}',
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.gold,
        trend: _data.revenueMonth > 0,
      ),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.45,
        children: kpis.map(_KpiCard.new).toList(),
      );
    }

    return Row(
      children: kpis
          .asMap()
          .entries
          .map(
            (e) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: e.key < kpis.length - 1 ? 14 : 0,
                ),
                child: _KpiCard(e.value),
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Registration Chart ──────────────────────────────────────────────────────
  Widget _buildRegChart() {
    final weekTotal = _data.registrationWeek.fold<num>(0, (s, p) => s + p.v);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Registrasi Pengguna',
            subtitle: '7 hari terakhir · $weekTotal pendaftar',
            trailing: _data.newUsersToday > 0
                ? _TrendBadge(
                    value: '+${_data.newUsersToday} hari ini',
                    up: true,
                  )
                : null,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: _AreaChartWidget(
              data: _data.registrationWeek,
              color: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  // ── Session Chart ───────────────────────────────────────────────────────────
  Widget _buildSessionChart() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Sesi Tryout',
            subtitle: '7 hari terakhir',
            trailing: _TrendBadge(
              value: 'CR ${_data.completionRate.toStringAsFixed(0)}%',
              up: _data.completionRate >= 50,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: _BarChartWidget(
              data: _data.sessionsWeek,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Goal Distribution ───────────────────────────────────────────────────────
  Widget _buildGoalDist() {
    if (_data.goalDist.isEmpty) return _EmptyCard(title: 'Distribusi Tujuan');

    final total = _data.goalDist.values.fold(0, (s, v) => s + v);
    final slices =
        _data.goalDist.entries
            .map(
              (e) => _Slice(
                e.key.toUpperCase(),
                e.value / total * 100,
                _goalColor(e.key),
              ),
            )
            .toList()
          ..sort((a, b) => b.pct.compareTo(a.pct));

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Distribusi Tujuan',
            subtitle: '$total pengguna aktif · ${slices.length} segmen',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(130, 130),
                      painter: _DonutPainter(slices),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$total', style: AppText.h2),
                        Text('users', style: AppText.caption),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: slices
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: s.c,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(s.l, style: AppText.label)),
                              Text(
                                '${s.pct.toInt()}%',
                                style: AppText.label.copyWith(color: s.c),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          // Business insight
          if (slices.isNotEmpty) ...[
            const SizedBox(height: 16),
            _InsightChip(
              text:
                  'Segmen terbesar: ${slices.first.l} (${slices.first.pct.toInt()}%). '
                  'Prioritaskan konten ${slices.first.l} untuk retensi.',
              color: slices.first.c,
            ),
          ],
        ],
      ),
    );
  }

  // ── Pass Rate ───────────────────────────────────────────────────────────────
  Widget _buildPassRate() {
    if (_data.passRateByCategory.isEmpty) {
      return _EmptyCard(title: 'Passing Rate per Kategori');
    }

    final sorted = _data.passRateByCategory.entries.toList()
      ..sort(
        (a, b) => a.value.compareTo(b.value),
      ); // lowest first = most critical

    final lowestCat = sorted.first;
    final avgPassRate =
        _data.passRateByCategory.values.fold(0.0, (s, v) => s + v) /
        _data.passRateByCategory.length;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Passing Rate per Kategori',
            subtitle: 'Avg ${avgPassRate.toStringAsFixed(0)}% · threshold 70%',
          ),
          const SizedBox(height: 20),
          ..._data.passRateByCategory.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _PassBar(label: e.key, value: e.value),
            ),
          ),
          const SizedBox(height: 4),
          _InsightChip(
            text:
                '${lowestCat.key} terendah (${lowestCat.value.toStringAsFixed(0)}%). '
                'Tambahkan bank soal & pembahasan ${lowestCat.key}.',
            color: AppColors.warning,
            icon: Icons.lightbulb_outline_rounded,
          ),
        ],
      ),
    );
  }

  // ── Popular Tryouts ─────────────────────────────────────────────────────────
  Widget _buildPopularTO() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Tryout Terpopuler',
            subtitle: 'Berdasarkan jumlah sesi aktif',
            trailing: TextButton(
              onPressed: () {},
              child: Text(
                'Lihat Semua',
                style: AppText.label.copyWith(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_data.popularTryouts.isEmpty)
            const _EmptyRow(message: 'Belum ada data sesi tryout')
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text('Tryout', style: AppText.caption),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Tipe', style: AppText.caption),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Sesi',
                      style: AppText.caption,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Status',
                      style: AppText.caption,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            ..._data.popularTryouts.asMap().entries.map(
              (e) => _TryoutRowWidget(rank: e.key + 1, row: e.value),
            ),
          ],
        ],
      ),
    );
  }

  // ── Verif Queue ─────────────────────────────────────────────────────────────
  Widget _buildVerifQueue() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Antrian Verifikasi',
            subtitle:
                '${_data.pendingVerif} pending · ${_data.approvedVerif} disetujui',
            trailing: _data.pendingVerif > 0
                ? _UrgentBadge(count: _data.pendingVerif)
                : null,
          ),
          const SizedBox(height: 8),
          if (_data.recentVerif.isEmpty)
            const _EmptyRow(message: 'Tidak ada verifikasi terbaru')
          else
            ..._data.recentVerif.map(_VerifRowWidget.new),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.open_in_new_rounded, size: 15),
              label: Text(
                _data.pendingVerif > 0
                    ? 'Review ${_data.pendingVerif} Antrian'
                    : 'Lihat Semua Antrian',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _data.pendingVerif > 0
                    ? AppColors.warning
                    : AppColors.primary,
                side: BorderSide(
                  color: _data.pendingVerif > 0
                      ? AppColors.warning
                      : AppColors.border,
                ),
                minimumSize: const Size(0, 40),
                textStyle: AppText.label,
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

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.bLg,
      border: Border.all(color: AppColors.border),
      boxShadow: AppShadow.sm,
    ),
    child: child,
  );
}

class _CardHeader extends StatelessWidget {
  final String title, subtitle;
  final Widget? trailing;
  const _CardHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.h3),
            const SizedBox(height: 2),
            Text(subtitle, style: AppText.bodySm),
          ],
        ),
      ),
      if (trailing != null) trailing!,
    ],
  );
}

class _EmptyCard extends StatelessWidget {
  final String title;
  const _EmptyCard({required this.title});
  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.h3),
        const SizedBox(height: 32),
        const Center(
          child: Column(
            children: [
              Icon(Icons.inbox_rounded, size: 36, color: AppColors.textHint),
              SizedBox(height: 8),
              Text(
                'Belum ada data',
                style: TextStyle(color: AppColors.textHint),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}

class _EmptyRow extends StatelessWidget {
  final String message;
  const _EmptyRow({required this.message});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(child: Text(message, style: AppText.bodySm)),
  );
}

class _InsightBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message, action;
  final VoidCallback onAction;
  const _InsightBanner({
    required this.icon,
    required this.color,
    required this.message,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: AppRadius.bMd,
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: AppText.bodySm.copyWith(color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: onAction,
          borderRadius: AppRadius.bMd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.bMd,
            ),
            child: Text(action, style: AppText.btnSm.copyWith(fontSize: 12)),
          ),
        ),
      ],
    ),
  );
}

class _InsightChip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  const _InsightChip({
    required this.text,
    required this.color,
    this.icon = Icons.lightbulb_outline_rounded,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: AppRadius.bMd,
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppText.caption.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    ),
  );
}

class _UrgentBadge extends StatelessWidget {
  final int count;
  const _UrgentBadge({required this.count});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.warning.withOpacity(0.12),
      borderRadius: AppRadius.bFull,
    ),
    child: Text(
      '$count pending',
      style: AppText.caption.copyWith(
        color: AppColors.warning,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

// ── KPI ────────────────────────────────────────────────────────────────────────
class _KpiData {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  final bool trend, urgent;
  const _KpiData({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    this.trend = false,
    this.urgent = false,
  });
}

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
          color: d.urgent
              ? AppColors.warning.withOpacity(0.5)
              : AppColors.border,
        ),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
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
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            d.value,
            style: (isMobile ? AppText.h3 : AppText.h2).copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            d.label,
            style: AppText.caption.copyWith(fontSize: isMobile ? 10 : 11),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (d.trend)
                Icon(
                  Icons.trending_up_rounded,
                  size: 12,
                  color: AppColors.success,
                ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  d.sub,
                  style: AppText.caption.copyWith(
                    fontSize: 10,
                    color: d.trend ? AppColors.success : AppColors.textHint,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Trend Badge ─────────────────────────────────────────────────────────────
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 11,
            color: c,
          ),
          const SizedBox(width: 3),
          Text(
            value,
            style: AppText.caption.copyWith(
              color: c,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Charts ──────────────────────────────────────────────────────────────────
class _AreaChartWidget extends StatelessWidget {
  final List<_Point> data;
  final Color color;
  const _AreaChartWidget({required this.data, required this.color});
  @override
  Widget build(BuildContext context) => data.isEmpty
      ? Center(child: Text('Belum ada data', style: AppText.bodySm))
      : CustomPaint(
          painter: _AreaPainter(data: data, color: color),
          child: const SizedBox.expand(),
        );
}

class _AreaPainter extends CustomPainter {
  final List<_Point> data;
  final Color color;
  _AreaPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final maxV = data
        .map((p) => p.v)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final range = maxV == 0 ? 1.0 : maxV;
    final pts = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - (data[i].v / range * size.height * 0.82);
      pts.add(Offset(x, y));
    }
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 4),
        Offset(size.width, size.height * i / 4),
        gridPaint,
      );
    }
    final path = Path()..moveTo(pts.first.dx, size.height);
    for (var i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      path.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        pts[i + 1].dx,
        pts[i + 1].dy,
      );
    }
    path
      ..lineTo(pts.last.dx, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [color.withOpacity(0.18), color.withOpacity(0.01)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      linePath.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        pts[i + 1].dx,
        pts[i + 1].dy,
      );
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < pts.length; i++) {
      canvas.drawCircle(
        pts[i],
        4,
        Paint()
          ..color = AppColors.surface
          ..strokeWidth = 2.5,
      );
      canvas.drawCircle(
        pts[i],
        4,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
      tp.text = TextSpan(
        text: data[i].l,
        style: const TextStyle(
          fontSize: 9,
          color: AppColors.textHint,
          fontWeight: FontWeight.w500,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(pts[i].dx - tp.width / 2, size.height + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _BarChartWidget extends StatelessWidget {
  final List<_Point> data;
  final Color color;
  const _BarChartWidget({required this.data, required this.color});
  @override
  Widget build(BuildContext context) => data.isEmpty
      ? Center(child: Text('Belum ada data', style: AppText.bodySm))
      : CustomPaint(
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
    final maxV = data
        .map((p) => p.v)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    if (maxV == 0) return;
    final barW = size.width / (data.length * 1.8);
    final gap = size.width / data.length;
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 4),
        Offset(size.width, size.height * i / 4),
        gridPaint,
      );
    }
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < data.length; i++) {
      final x = gap * i + gap / 2 - barW / 2;
      final h = (data[i].v / maxV) * size.height * 0.82;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, size.height - h, barW, h),
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(5),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [color, color.withOpacity(0.4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(x, size.height - h, barW, h)),
      );
      tp.text = TextSpan(
        text: data[i].l,
        style: const TextStyle(
          fontSize: 9,
          color: AppColors.textHint,
          fontWeight: FontWeight.w500,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, size.height + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _DonutPainter extends CustomPainter {
  final List<_Slice> slices;
  _DonutPainter(this.slices);
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    const gap = 0.04;
    const startAngle = -1.5708;
    double angle = startAngle;
    final total = slices.fold(0.0, (s, e) => s + e.pct);
    for (final sl in slices) {
      final sweep = (sl.pct / total) * (2 * 3.14159) - gap;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - 9),
        angle,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round
          ..color = sl.c,
      );
      angle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ── Pass Bar ─────────────────────────────────────────────────────────────────
class _PassBar extends StatelessWidget {
  final String label;
  final double value;
  const _PassBar({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final color = value >= 70
        ? AppColors.success
        : value >= 55
        ? AppColors.warning
        : AppColors.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppText.label),
            const Spacer(),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: AppText.label.copyWith(color: color),
            ),
            const SizedBox(width: 6),
            Text('/ 70%', style: AppText.caption.copyWith(fontSize: 10)),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: AppRadius.bFull,
              ),
            ),
            LayoutBuilder(
              builder: (_, c) => FractionallySizedBox(
                widthFactor: (value / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: AppRadius.bFull,
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.3), blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Tryout Row ────────────────────────────────────────────────────────────────
class _TryoutRowWidget extends StatelessWidget {
  final int rank;
  final _TryoutStat row;
  const _TryoutRowWidget({required this.rank, required this.row});
  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 1
        ? AppColors.gold
        : rank == 2
        ? AppColors.textSecondary
        : rank == 3
        ? const Color(0xFFB08D57)
        : AppColors.textHint;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: rankColor.withOpacity(0.12),
                    borderRadius: AppRadius.bSm,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: AppText.caption.copyWith(
                        color: rankColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    row.title,
                    style: AppText.label.copyWith(color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: _CatChip(row.cat)),
          Expanded(
            flex: 2,
            child: Text(
              _num.format(row.sessions),
              style: AppText.label,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (row.active ? AppColors.success : AppColors.error)
                      .withOpacity(0.10),
                  borderRadius: AppRadius.bFull,
                ),
                child: Text(
                  row.active ? 'Aktif' : 'Draft',
                  style: AppText.caption.copyWith(
                    color: row.active ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String cat;
  const _CatChip(this.cat);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: _goalColor(cat).withOpacity(0.10),
      borderRadius: AppRadius.bFull,
    ),
    child: Text(
      cat,
      style: AppText.caption.copyWith(
        color: _goalColor(cat),
        fontWeight: FontWeight.w700,
        fontSize: 10,
      ),
    ),
  );
}

// ── Verif Row ─────────────────────────────────────────────────────────────────
class _VerifRowWidget extends StatelessWidget {
  final _VerifItem row;
  const _VerifRowWidget(this.row, {super.key});
  @override
  Widget build(BuildContext context) {
    final statusColor = switch (row.status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.warning,
    };
    final statusLabel = switch (row.status) {
      'approved' => 'Disetujui',
      'rejected' => 'Ditolak',
      _ => 'Pending',
    };
    final statusIcon = switch (row.status) {
      'approved' => Icons.check_circle_rounded,
      'rejected' => Icons.cancel_rounded,
      _ => Icons.pending_rounded,
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppGradient.navy,
              borderRadius: AppRadius.bSm,
            ),
            child: Center(
              child: Text(
                row.user.isNotEmpty ? row.user[0].toUpperCase() : '?',
                style: AppText.label.copyWith(color: AppColors.gold),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.user,
                  style: AppText.label.copyWith(color: AppColors.textPrimary),
                ),
                Text(
                  row.tryout,
                  style: AppText.caption.copyWith(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: AppRadius.bFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 10, color: statusColor),
                    const SizedBox(width: 3),
                    Text(
                      statusLabel,
                      style: AppText.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(row.time, style: AppText.caption.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text('Gagal memuat data', style: AppText.h3),
          const SizedBox(height: 6),
          Text(error, style: AppText.bodySm, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    ),
  );
}

// ── Icon Button ───────────────────────────────────────────────────────────────
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

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(label, style: AppText.label.copyWith(color: AppColors.white)),
        ],
      ),
    ),
  );
}
