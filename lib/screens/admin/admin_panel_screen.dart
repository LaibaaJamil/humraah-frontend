import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/cards/stat_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/section_header.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.instance.get(ApiConstants.adminDashboard);
      setState(() {
        _data = res['data'] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingIndicator(label: 'Loading admin panel...');
    if (_data == null) return const Center(child: Text('Failed to load'));

    final c = _data!['counts'] as Map<String, dynamic>;
    final ngosByProvince = (_data!['ngosByProvince'] as List?) ?? [];
    final ngoBySector = (_data!['ngoBySector'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Admin Control Panel',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Master analytics and platform moderation',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Platform Counts',
            trailing: TextButton.icon(
              onPressed: () => context.go('/admin/pending'),
              icon: const Icon(Icons.fact_check_outlined, size: 16),
              label: const Text('Verify NGOs'),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, c2) {
            final cols =
                c2.maxWidth >= 1100 ? 4 : c2.maxWidth >= 700 ? 3 : 2;
            final cards = <Widget>[
              StatCard(
                icon: Icons.person_outline,
                color: AppColors.primary,
                label: 'Total Users',
                value: '${c['totalUsers']}',
              ),
              StatCard(
                icon: Icons.apartment_outlined,
                color: AppColors.accent,
                label: 'NGOs',
                value: '${c['totalNGOs']}',
                subtitle: '${c['verifiedNGOs']} verified',
                onTap: () => context.go('/ngos'),
              ),
              StatCard(
                icon: Icons.hourglass_top_outlined,
                color: AppColors.warning,
                label: 'Pending NGOs',
                value: '${c['pendingNGOs']}',
                subtitle: 'Need review',
                onTap: () => context.go('/admin/pending'),
              ),
              StatCard(
                icon: Icons.menu_book_outlined,
                color: AppColors.success,
                label: 'Resources',
                value: '${c['totalResources']}',
                onTap: () => context.go('/resources'),
              ),
              StatCard(
                icon: Icons.flag_outlined,
                color: AppColors.danger,
                label: 'Active Flags',
                value: '${c['activeFlags']}',
                subtitle: 'of ${c['totalFlags']} total',
                onTap: () => context.go('/map'),
              ),
              StatCard(
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.secondary,
                label: 'Open Tenders',
                value: '${c['openTenders']}',
                subtitle: '${c['totalTenders']} total',
                onTap: () => context.go('/tenders'),
              ),
              StatCard(
                icon: Icons.assignment_outlined,
                color: AppColors.accent,
                label: 'Applications',
                value: '${c['totalApplications']}',
                onTap: () => context.go('/tenders'),
              ),
              StatCard(
                icon: Icons.bar_chart_outlined,
                color: AppColors.primary,
                label: 'Reports',
                value: '${c['totalReports']}',
                onTap: () => context.go('/reports'),
              ),
            ];
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 160,
              ),
              itemBuilder: (_, i) => cards[i],
            );
          }),
          const SizedBox(height: 24),
          if (ngosByProvince.isNotEmpty)
            _NGOsByProvinceChart(rows: ngosByProvince),
          if (ngoBySector.isNotEmpty) ...[
            const SizedBox(height: 18),
            _SectorChart(rows: ngoBySector),
          ],
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Manage Donor Organizations',
            subtitle: 'Mark large organizations (UNICEF, WFP etc.) who can post tenders',
            trailing: TextButton.icon(
              onPressed: () => context.go('/admin/donors'),
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('Manage'),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              const Row(children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Only "Large Org" donors can post tenders. Regular donors can only browse and view NGOs.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                )),
              ]),
              const SizedBox(height: 14),
              InkWell(
                onTap: () => context.go('/admin/donors'),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.secondary, Color(0xFFC2410C)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(children: [
                    Icon(Icons.volunteer_activism_rounded, color: Colors.white54, size: 32),
                    SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Manage Donor Organizations',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      SizedBox(height: 3),
                      Text('Set isLargeOrg flag for UNICEF, WFP, UN agencies etc.',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ])),
                    Icon(Icons.chevron_right, color: Colors.white54),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _NGOsByProvinceChart extends StatelessWidget {
  final List rows;
  const _NGOsByProvinceChart({required this.rows});

  @override
  Widget build(BuildContext context) {
    final maxV = rows.fold<num>(
        0,
        (m, r) =>
            ((r as Map)['count'] as num) > m ? (r['count'] as num) : m);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verified NGOs by Province',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...rows.map((r) {
            final m = r as Map<String, dynamic>;
            final count = (m['count'] as num).toDouble();
            final pct = maxV > 0 ? count / maxV.toDouble() : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      m['_id']?.toString() ?? 'Unknown',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: AppColors.surfaceAlt,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${count.toInt()}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SectorChart extends StatelessWidget {
  final List rows;
  const _SectorChart({required this.rows});

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
      AppColors.danger,
    ];
    final bars = <BarChartGroupData>[];
    for (var i = 0; i < rows.length; i++) {
      final m = rows[i] as Map<String, dynamic>;
      bars.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: (m['count'] as num).toDouble(),
            color: colors[i % colors.length],
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ));
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Sectors',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                barGroups: bars,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= rows.length) {
                          return const SizedBox.shrink();
                        }
                        final m = rows[i] as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Transform.rotate(
                            angle: -0.3,
                            child: Text(
                              (m['_id']?.toString() ?? '').replaceAll('_', ' '),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
