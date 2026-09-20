import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/cards/stat_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/section_header.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, dynamic>? _analytics;
  List<Map<String, dynamic>> _myReports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    final isNgo = user?.isNgoAdmin == true || user?.isNgoStaff == true;
    _tabs = TabController(length: isNgo ? 2 : 1, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = context.read<AuthProvider>().user;
      final ngoId = user?.ngo?.id;
      final isNgo = user?.isNgoAdmin == true || user?.isNgoStaff == true;

      final futures = <Future>[
        ApiService.instance.get(ApiConstants.reportAnalytics,
            query: {if (ngoId != null && isNgo) 'ngo': ngoId}),
        if (isNgo) ApiService.instance.get(ApiConstants.myReports),
      ];
      final results = await Future.wait(futures);
      setState(() {
        _analytics = results[0]['data'] as Map<String, dynamic>;
        if (isNgo && results.length > 1) {
          _myReports = ((results[1]['data'] as List?) ?? [])
              .map((e) => e as Map<String, dynamic>)
              .toList();
        }
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final canSubmit = user != null && (user.isNgoAdmin || user.isNgoStaff) && user.hasNgo;
    final isNgo = user?.isNgoAdmin == true || user?.isNgoStaff == true;
    if (_loading) return const LoadingIndicator(label: 'Loading reports...');

    return Scaffold(
      floatingActionButton: canSubmit
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/reports/new'),
              icon: const Icon(Icons.add_chart_outlined),
              label: const Text('Submit Report'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Impact Reports',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        isNgo
                            ? 'Your NGO\'s submitted reports and analytics'
                            : 'National impact data from all NGOs',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                if (isNgo)
                  TabBar(
                    controller: _tabs,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    tabs: [
                      const Tab(text: 'Analytics'),
                      Tab(text: 'My Reports (${_myReports.length})'),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: isNgo
                  ? TabBarView(
                      controller: _tabs,
                      children: [
                        _AnalyticsTab(analytics: _analytics),
                        _MyReportsTab(reports: _myReports, onRefresh: _load),
                      ],
                    )
                  : _AnalyticsTab(analytics: _analytics),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Analytics Tab ───────────────────────────────────────────
class _AnalyticsTab extends StatelessWidget {
  final Map<String, dynamic>? analytics;
  const _AnalyticsTab({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final totals = (analytics?['totals'] as Map<String, dynamic>?) ?? {};
    final monthly = (analytics?['monthly'] as List?) ?? [];
    final sectorBreakdown = (analytics?['sectorBreakdown'] as List?) ?? [];
    final fmt = NumberFormat('#,###');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeader(title: 'Aggregated Totals'),
        const SizedBox(height: 14),
        _statsGrid(totals, fmt, context),
        const SizedBox(height: 24),
        if (monthly.isNotEmpty) ...[
          _MonthlyChart(monthly: monthly),
          const SizedBox(height: 20),
        ],
        if ((totals['women'] ?? 0) > 0 || (totals['men'] ?? 0) > 0)
          _DemographicChart(
            women: (totals['women'] ?? 0).toDouble(),
            men: (totals['men'] ?? 0).toDouble(),
            children: (totals['children'] ?? 0).toDouble(),
          ),
        if (sectorBreakdown.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectorBreakdown(rows: sectorBreakdown),
        ],
        if (monthly.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: EmptyState(
              icon: Icons.bar_chart_outlined,
              title: 'No reports yet',
              message: 'Once NGOs submit monthly data, charts appear here.',
            ),
          ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _statsGrid(Map totals, NumberFormat fmt, BuildContext ctx) {
    final cards = [
      StatCard(icon: Icons.people_alt_outlined, color: AppColors.primary,
          label: 'Beneficiaries', value: fmt.format(totals['beneficiariesReached'] ?? 0)),
      StatCard(icon: Icons.event_outlined, color: AppColors.accent,
          label: 'Events', value: fmt.format(totals['eventsConducted'] ?? 0)),
      StatCard(icon: Icons.volunteer_activism_outlined, color: AppColors.success,
          label: 'Volunteers', value: fmt.format(totals['volunteersEngaged'] ?? 0)),
      StatCard(icon: Icons.payments_outlined, color: AppColors.secondary,
          label: 'Funds Used', value: 'PKR ${fmt.format(totals['fundsUtilized'] ?? 0)}'),
    ];
    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth >= 900 ? 4 : c.maxWidth >= 600 ? 3 : 2;
      return GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols, crossAxisSpacing: 14, mainAxisSpacing: 14, mainAxisExtent: 140),
        itemBuilder: (_, i) => cards[i],
      );
    });
  }
}

// ── My Reports Tab ──────────────────────────────────────────
class _MyReportsTab extends StatelessWidget {
  final List<Map<String, dynamic>> reports;
  final VoidCallback onRefresh;
  const _MyReportsTab({required this.reports, required this.onRefresh});

  String _monthName(int m) => const ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const EmptyState(
        icon: Icons.assignment_outlined,
        title: 'No reports submitted yet',
        message: 'Tap "Submit Report" to add your first monthly impact report.',
      );
    }
    final fmt = NumberFormat('#,###');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final r = reports[i];
        final period = r['period'] is Map<String, dynamic> ? r['period'] as Map<String, dynamic> : <String, dynamic>{};
        final metrics = r['metrics'] is Map<String, dynamic> ? r['metrics'] as Map<String, dynamic> : <String, dynamic>{};
        final breakdown = r['breakdown'] is Map<String, dynamic> ? r['breakdown'] as Map<String, dynamic> : <String, dynamic>{};
        final month = (period['month'] as num?)?.toInt() ?? 1;
        final year = (period['year'] as num?)?.toInt() ?? 2024;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                child: Text('${_monthName(month)} $year',
                    style: const TextStyle(color: AppColors.primary,
                        fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.successLight, borderRadius: BorderRadius.circular(8)),
                child: Text((r['sector'] ?? 'general').toString().toUpperCase(),
                    style: const TextStyle(color: AppColors.success,
                        fontWeight: FontWeight.w700, fontSize: 10)),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _metric(Icons.people_alt_outlined, AppColors.primary,
                  fmt.format(metrics['beneficiariesReached'] ?? 0), 'Beneficiaries'),
              const SizedBox(width: 12),
              _metric(Icons.event_outlined, AppColors.accent,
                  '${metrics['eventsConducted'] ?? 0}', 'Events'),
              const SizedBox(width: 12),
              _metric(Icons.volunteer_activism_outlined, AppColors.success,
                  '${metrics['volunteersEngaged'] ?? 0}', 'Volunteers'),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.payments_outlined, size: 14, color: AppColors.secondary),
                const SizedBox(width: 6),
                Text('PKR ${fmt.format(metrics['fundsUtilized'] ?? 0)} utilized',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                const Spacer(),
                Text('W:${breakdown['women'] ?? 0} M:${breakdown['men'] ?? 0} C:${breakdown['children'] ?? 0}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ]),
            ),
            if ((r['summary'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(r['summary'].toString(),
                  style: const TextStyle(color: AppColors.textSecondary,
                      fontSize: 12.5, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ]),
        );
      },
    );
  }

  Widget _metric(IconData icon, Color color, String val, String label) {
    return Column(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(height: 3),
      Text(val, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
    ]);
  }
}

// ── Charts (same as before, kept intact) ───────────────────
class _MonthlyChart extends StatelessWidget {
  final List monthly;
  const _MonthlyChart({required this.monthly});
  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < monthly.length; i++) {
      final m = monthly[i] as Map<String, dynamic>;
      spots.add(FlSpot(i.toDouble(), ((m['beneficiariesReached'] ?? 0) as num).toDouble()));
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Beneficiaries Reached (Monthly)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        SizedBox(height: 220, child: LineChart(LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(), topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
              getTitlesWidget: (val, _) {
                final i = val.toInt();
                if (i < 0 || i >= monthly.length) return const SizedBox.shrink();
                final p = (monthly[i] as Map)['_id'] as Map<String, dynamic>;
                return Padding(padding: const EdgeInsets.only(top: 6),
                    child: Text('${p['month']}/${(p['year'] as int) % 100}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted)));
              })),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40,
              getTitlesWidget: (val, _) => Text(val.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)))),
          ),
          lineBarsData: [LineChartBarData(
            isCurved: true, color: AppColors.primary, barWidth: 3, spots: spots,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.1)),
          )],
        ))),
      ]),
    );
  }
}

class _DemographicChart extends StatelessWidget {
  final double women, men, children;
  const _DemographicChart({required this.women, required this.men, required this.children});
  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final total = women + men + children;
    if (total == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Demographic Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        SizedBox(height: 200, child: Row(children: [
          Expanded(child: PieChart(PieChartData(
            sections: [
              PieChartSectionData(value: women, color: AppColors.accent,
                  title: '${((women/total)*100).toStringAsFixed(0)}%', radius: 60,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
              PieChartSectionData(value: men, color: AppColors.primary,
                  title: '${((men/total)*100).toStringAsFixed(0)}%', radius: 60,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
              PieChartSectionData(value: children, color: AppColors.secondary,
                  title: '${((children/total)*100).toStringAsFixed(0)}%', radius: 60,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
            ],
            centerSpaceRadius: 30, sectionsSpace: 2,
          ))),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legend(AppColors.accent, 'Women', fmt.format(women)),
              const SizedBox(height: 8),
              _legend(AppColors.primary, 'Men', fmt.format(men)),
              const SizedBox(height: 8),
              _legend(AppColors.secondary, 'Children', fmt.format(children)),
            ])),
        ])),
      ]),
    );
  }
  Widget _legend(Color color, String label, String value) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontSize: 12)),
    const SizedBox(width: 8),
    Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
  ]);
}

class _SectorBreakdown extends StatelessWidget {
  final List rows;
  const _SectorBreakdown({required this.rows});
  @override
  Widget build(BuildContext context) {
    final maxB = rows.fold<num>(0, (max, r) =>
        ((r as Map)['beneficiaries'] as num) > max ? (r['beneficiaries'] as num) : max);
    final fmt = NumberFormat('#,###');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Sector Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        ...rows.map((r) {
          final m = r as Map<String, dynamic>;
          final b = (m['beneficiaries'] as num).toDouble();
          return Padding(padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text((m['_id'] ?? 'general').toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                Text(fmt.format(b), style: const TextStyle(fontWeight: FontWeight.w700,
                    color: AppColors.primary, fontSize: 13)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: maxB > 0 ? b / maxB.toDouble() : 0,
                  backgroundColor: AppColors.surfaceAlt,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  minHeight: 6,
                )),
            ]));
        }),
      ]),
    );
  }
}
