import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/cards/stat_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/section_header.dart';
import '../../core/services/socket_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _impact;
  Map<String, dynamic>? _adminStats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    SocketService.listenNotifications((data) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data['message']?.toString() ?? 'New notification'),
        backgroundColor: AppColors.primary,
      ));
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ApiService.instance;
      final isAdmin =
          context.read<AuthProvider>().user?.isSuperAdmin ?? false;
      final results = await Future.wait([
        api.get(ApiConstants.nationalImpact),
        if (isAdmin) api.get(ApiConstants.adminDashboard),
      ]);
      _impact = results[0]['data'] as Map<String, dynamic>;
      if (isAdmin && results.length > 1) {
        _adminStats = results[1]['data'] as Map<String, dynamic>;
      }
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    if (_loading) return const LoadingIndicator(label: 'Loading dashboard...');

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _WelcomeBanner(user: user),
          const SizedBox(height: 20),
          if (_error != null) _ErrorBanner(error: _error!),

          // ── SUPER ADMIN ──────────────────────────────────────────────
          if (user.isSuperAdmin) ..._superAdminContent(user),

          // ── NGO ADMIN ────────────────────────────────────────────────
          if (user.isNgoAdmin) ..._ngoAdminContent(user),

          // ── NGO STAFF ────────────────────────────────────────────────
          if (user.isNgoStaff) ..._ngoStaffContent(user),

          // ── DONOR ────────────────────────────────────────────────────
          if (user.isDonor) ..._donorContent(user),

          // ── CITIZEN / PUBLIC USER ────────────────────────────────────
          if (user.isPublicUser) ..._citizenContent(user),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ─────────────────── SUPER ADMIN ───────────────────
  List<Widget> _superAdminContent(user) {
    final c = (_adminStats?['counts'] as Map<String, dynamic>?) ?? {};
    final totals = (_impact?['totals'] as Map<String, dynamic>?) ?? {};
    final fmt = NumberFormat('#,###');
    return [
      const SectionHeader(
          title: 'Platform Overview',
          subtitle: 'Live system-wide statistics'),
      const SizedBox(height: 14),
      _grid([
        StatCard(
            icon: Icons.person_outline,
            color: AppColors.primary,
            label: 'Total Users',
            value: '${c['totalUsers'] ?? 0}',
            subtitle: 'Registered accounts',
            onTap: () => context.go('/admin')),
        StatCard(
            icon: Icons.apartment_outlined,
            color: AppColors.accent,
            label: 'Total NGOs',
            value: '${c['totalNGOs'] ?? 0}',
            subtitle: '${c['verifiedNGOs'] ?? 0} verified',
            onTap: () => context.go('/ngos')),
        StatCard(
            icon: Icons.hourglass_top_outlined,
            color: AppColors.warning,
            label: 'Pending NGOs',
            value: '${c['pendingNGOs'] ?? 0}',
            subtitle: 'Need review',
            onTap: () => context.go('/admin/pending')),
        StatCard(
            icon: Icons.flag_outlined,
            color: AppColors.danger,
            label: 'Active Flags',
            value: '${c['activeFlags'] ?? 0}',
            subtitle: 'Need response',
            onTap: () => context.go('/map')),
        StatCard(
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.secondary,
            label: 'Open Tenders',
            value: '${c['openTenders'] ?? 0}',
            subtitle: 'Funding available',
            onTap: () => context.go('/tenders')),
        StatCard(
            icon: Icons.bar_chart_outlined,
            color: AppColors.success,
            label: 'Beneficiaries',
            value: fmt.format(totals['beneficiariesReached'] ?? 0),
            subtitle: 'Reached nationally',
            onTap: () => context.go('/reports')),
        StatCard(
            icon: Icons.menu_book_outlined,
            color: AppColors.primary,
            label: 'Resources',
            value: '${c['totalResources'] ?? 0}',
            subtitle: 'In shared library',
            onTap: () => context.go('/resources')),
        StatCard(
            icon: Icons.assignment_outlined,
            color: AppColors.accent,
            label: 'Applications',
            value: '${c['totalApplications'] ?? 0}',
            subtitle: 'Tender applications',
            onTap: () => context.go('/tenders')),
      ]),
      const SizedBox(height: 20),
      if ((_adminStats?['flagsByCategory'] as List?)?.isNotEmpty == true)
        _FlagsPieChart(data: _adminStats!['flagsByCategory'] as List),
      const SizedBox(height: 20),
      const SectionHeader(
          title: 'Admin Actions', subtitle: 'Quick moderation tasks'),
      const SizedBox(height: 12),
      _actionGrid([
        _Action(Icons.fact_check_outlined, 'Verify NGOs',
            '/admin/pending', AppColors.warning),
        _Action(Icons.map_outlined, 'Review Map Flags', '/map',
            AppColors.danger),
        _Action(Icons.people_alt_outlined, 'Manage Users', '/admin',
            AppColors.primary),
        _Action(Icons.menu_book_outlined, 'Resources Library',
            '/resources', AppColors.success),
      ]),
    ];
  }

  // ─────────────────── NGO ADMIN ───────────────────
  List<Widget> _ngoAdminContent(user) {
    final totals = (_impact?['totals'] as Map<String, dynamic>?) ?? {};
    final fmt = NumberFormat('#,###');
    return [
      const SectionHeader(
          title: 'NGO Overview',
          subtitle: 'Your organisation\'s performance at a glance'),
      const SizedBox(height: 14),
      _grid([
        StatCard(
            icon: Icons.people_alt_outlined,
            color: AppColors.success,
            label: 'Beneficiaries',
            value: fmt.format(totals['beneficiariesReached'] ?? 0),
            subtitle: 'Reached this period',
            onTap: () => context.go('/reports')),
        StatCard(
            icon: Icons.event_outlined,
            color: AppColors.accent,
            label: 'Events',
            value: fmt.format(totals['eventsConducted'] ?? 0),
            subtitle: 'Conducted',
            onTap: () => context.go('/reports')),
        StatCard(
            icon: Icons.payments_outlined,
            color: AppColors.secondary,
            label: 'Funds Utilized',
            value: 'PKR ${fmt.format(totals['fundsUtilized'] ?? 0)}',
            subtitle: 'Reported by NGOs',
            onTap: () => context.go('/reports')),
        StatCard(
            icon: Icons.verified_outlined,
            color: AppColors.primary,
            label: 'Verified NGOs',
            value: '${_impact?['verifiedNGOs'] ?? 0}',
            subtitle: 'On platform',
            onTap: () => context.go('/ngos')),
      ]),
      const SizedBox(height: 20),
      const SectionHeader(
          title: 'Management Actions',
          subtitle: 'Lead your organisation'),
      const SizedBox(height: 12),
      _actionGrid([
        _Action(Icons.apartment_outlined, 'My NGO Profile', '/my-ngo',
            AppColors.primary),
        _Action(Icons.bar_chart_outlined, 'Submit Report', '/reports/new',
            AppColors.success),
        _Action(Icons.add_location_alt_outlined, 'Add Map Pin',
            '/map/new', AppColors.danger),
        _Action(Icons.upload_file_outlined, 'Upload Resource',
            '/resources/upload', AppColors.accent),
        _Action(Icons.handshake_outlined, 'Volunteer Requests',
            '/volunteer', AppColors.secondary),
        _Action(Icons.account_balance_wallet_outlined, 'Browse Tenders',
            '/tenders', AppColors.warning),
        _Action(Icons.swap_horiz_outlined, 'Referrals', '/referrals',
            AppColors.primary),
        _Action(Icons.map_outlined, 'GIS Map', '/map', AppColors.accent),
      ]),
    ];
  }

  // ─────────────────── NGO STAFF ───────────────────
  List<Widget> _ngoStaffContent(user) {
    final totals = (_impact?['totals'] as Map<String, dynamic>?) ?? {};
    final fmt = NumberFormat('#,###');
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0EA5E9), Color(0xFF075985)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(children: [
          Icon(Icons.groups_rounded, color: Colors.white54, size: 48),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Field Operations',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                SizedBox(height: 4),
                Text(
                    'Drop pins, upload resources, refer cases and respond to flags.',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5)),
              ],
            ),
          ),
        ]),
      ),
      const SizedBox(height: 20),
      const SectionHeader(title: 'National Impact', subtitle: ''),
      const SizedBox(height: 12),
      _grid([
        StatCard(
            icon: Icons.people_alt_outlined,
            color: AppColors.success,
            label: 'Beneficiaries',
            value: fmt.format(totals['beneficiariesReached'] ?? 0),
            onTap: () => context.go('/reports')),
        StatCard(
            icon: Icons.verified_outlined,
            color: AppColors.primary,
            label: 'Verified NGOs',
            value: '${_impact?['verifiedNGOs'] ?? 0}',
            onTap: () => context.go('/ngos')),
      ]),
      const SizedBox(height: 20),
      const SectionHeader(title: 'Field Tasks', subtitle: 'Your daily actions'),
      const SizedBox(height: 12),
      _actionGrid([
        _Action(Icons.add_location_alt_outlined, 'Drop Pin / Flag',
            '/map/new', AppColors.danger),
        _Action(Icons.map_outlined, 'View GIS Map', '/map',
            AppColors.primary),
        _Action(Icons.upload_file_outlined, 'Upload Resource',
            '/resources/upload', AppColors.accent),
        _Action(Icons.bar_chart_outlined, 'Submit Report', '/reports/new',
            AppColors.success),
        _Action(Icons.swap_horiz_outlined, 'Referrals', '/referrals',
            AppColors.secondary),
        _Action(Icons.apartment_outlined, 'My NGO', '/my-ngo',
            AppColors.primary),
      ]),
    ];
  }

  // ─────────────────── DONOR ───────────────────
  List<Widget> _donorContent(user) {
    final totals = (_impact?['totals'] as Map<String, dynamic>?) ?? {};
    final fmt = NumberFormat('#,###');
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.secondary, Color(0xFFC2410C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(children: [
          Icon(Icons.volunteer_activism_rounded,
              color: Colors.white54, size: 52),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Donor Portal',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                SizedBox(height: 4),
                Text(
                    'Fund impactful NGOs. Discover verified organizations and post tenders.',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5)),
              ],
            ),
          ),
        ]),
      ),
      const SizedBox(height: 20),
      const SectionHeader(
          title: 'Platform Impact',
          subtitle: 'What your funding enables'),
      const SizedBox(height: 12),
      _grid([
        StatCard(
            icon: Icons.verified_outlined,
            color: AppColors.primary,
            label: 'Verified NGOs',
            value: '${_impact?['verifiedNGOs'] ?? 0}',
            subtitle: 'Available to fund',
            onTap: () => context.go('/ngos')),
        StatCard(
            icon: Icons.people_alt_outlined,
            color: AppColors.success,
            label: 'Beneficiaries',
            value: fmt.format(totals['beneficiariesReached'] ?? 0),
            subtitle: 'Reached',
            onTap: () => context.go('/reports')),
        StatCard(
            icon: Icons.payments_outlined,
            color: AppColors.secondary,
            label: 'Funds Utilized',
            value: 'PKR ${fmt.format(totals['fundsUtilized'] ?? 0)}',
            subtitle: 'By NGOs',
            onTap: () => context.go('/reports')),
        StatCard(
            icon: Icons.event_outlined,
            color: AppColors.accent,
            label: 'Events',
            value: fmt.format(totals['eventsConducted'] ?? 0),
            onTap: () => context.go('/reports')),
      ]),
      const SizedBox(height: 20),
      const SectionHeader(
          title: 'Donor Actions', subtitle: 'Manage your funding'),
      const SizedBox(height: 12),
      _actionGrid([
        _Action(Icons.apartment_outlined, 'Browse NGOs', '/ngos',
            AppColors.primary),
        _Action(Icons.account_balance_wallet_outlined, 'Tenders', '/tenders',
            AppColors.secondary),
        if (user.isLargeOrg)
          _Action(Icons.post_add_outlined, 'Post New Tender',
              '/tenders/new', AppColors.warning),
        _Action(Icons.map_outlined, 'GIS Map', '/map', AppColors.accent),
        _Action(Icons.menu_book_outlined, 'Resources', '/resources',
            AppColors.success),
      ]),
      if (!user.isLargeOrg) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warningLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, color: AppColors.warning, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Only large verified donor organizations (UNICEF, WFP, etc.) can post tenders. Contact admin to upgrade your account.',
                style: TextStyle(color: AppColors.warning, fontSize: 12.5),
              ),
            ),
          ]),
        ),
      ],
    ];
  }

  // ─────────────────── CITIZEN ───────────────────
  List<Widget> _citizenContent(user) {
    return [
      // Trust score badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: user.trustScore >= 70
                  ? AppColors.successLight
                  : user.trustScore >= 40
                      ? AppColors.warningLight
                      : AppColors.dangerLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_outlined,
                color: user.trustScore >= 70
                    ? AppColors.success
                    : user.trustScore >= 40
                        ? AppColors.warning
                        : AppColors.danger,
                size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Citizen Trust Score',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(
                    'Score: ${user.trustScore}/100 — ${user.trustScore >= 70 ? 'Trusted Reporter' : user.trustScore >= 40 ? 'Building Trust' : 'New Citizen'}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text('${user.trustScore}',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: user.trustScore >= 70
                      ? AppColors.success
                      : user.trustScore >= 40
                          ? AppColors.warning
                          : AppColors.danger)),
        ]),
      ),
      const SizedBox(height: 20),
      const SectionHeader(
          title: 'What can you do?',
          subtitle: 'Help your community'),
      const SizedBox(height: 12),
      _CitizenActionGrid(),
      const SizedBox(height: 20),
      const SectionHeader(
          title: 'National Impact',
          subtitle: 'What verified NGOs have achieved'),
      const SizedBox(height: 12),
      _impactGrid(),
    ];
  }

  Widget _impactGrid() {
    final totals = (_impact?['totals'] as Map<String, dynamic>?) ?? {};
    final fmt = NumberFormat('#,###');
    return _grid([
      StatCard(
          icon: Icons.verified_outlined,
          color: AppColors.primary,
          label: 'Verified NGOs',
          value: '${_impact?['verifiedNGOs'] ?? 0}',
          subtitle: 'On platform',
          onTap: () => context.go('/ngos')),
      StatCard(
          icon: Icons.people_alt_outlined,
          color: AppColors.success,
          label: 'Beneficiaries',
          value: fmt.format(totals['beneficiariesReached'] ?? 0),
          onTap: () => context.go('/reports')),
      StatCard(
          icon: Icons.event_outlined,
          color: AppColors.accent,
          label: 'Events',
          value: fmt.format(totals['eventsConducted'] ?? 0),
          onTap: () => context.go('/reports')),
      StatCard(
          icon: Icons.payments_outlined,
          color: AppColors.secondary,
          label: 'Funds Utilized',
          value: 'PKR ${fmt.format(totals['fundsUtilized'] ?? 0)}',
          onTap: () => context.go('/reports')),
    ]);
  }

  Widget _grid(List<Widget> cards) => LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth >= 1100
              ? 4
              : c.maxWidth >= 700
                  ? 3
                  : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 160),
            itemBuilder: (_, i) => cards[i],
          );
        },
      );

  Widget _actionGrid(List<_Action> actions) => LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth >= 1100
              ? 4
              : c.maxWidth >= 700
                  ? 3
                  : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 76),
            itemBuilder: (_, i) {
              final a = actions[i];
              return InkWell(
                onTap: () => context.go(a.path),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: a.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(a.icon, color: a.color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(a.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13))),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textMuted, size: 18),
                  ]),
                ),
              );
            },
          );
        },
      );
}

class _Action {
  final IconData icon;
  final String label;
  final String path;
  final Color color;
  _Action(this.icon, this.label, this.path, this.color);
}

class _WelcomeBanner extends StatelessWidget {
  final dynamic user;
  const _WelcomeBanner({required this.user});

  @override
  Widget build(BuildContext context) {
    final Map<String, ({List<Color> g, IconData icon, String tagline})> themes =
        {
      'super_admin': (
        g: const [Color(0xFF1E293B), Color(0xFF0F172A)],
        icon: Icons.shield_moon_rounded,
        tagline: 'Platform oversight — moderate, verify, and review impact.'
      ),
      'donor': (
        g: const [AppColors.secondary, Color(0xFFC2410C)],
        icon: Icons.volunteer_activism_rounded,
        tagline: 'Discover verified NGOs and fund projects that matter.'
      ),
      'ngo_admin': (
        g: const [AppColors.primary, AppColors.primaryDark],
        icon: Icons.apartment_rounded,
        tagline: 'Lead your organisation — reports, resources, tenders.'
      ),
      'ngo_staff': (
        g: const [Color(0xFF0EA5E9), Color(0xFF075985)],
        icon: Icons.groups_rounded,
        tagline: 'Field operations — drop pins, upload resources, refer cases.'
      ),
      'public_user': (
        g: const [AppColors.accent, Color(0xFF5B21B6)],
        icon: Icons.person_pin_circle_rounded,
        tagline: 'See something? Report it or volunteer with an NGO near you.'
      ),
    };
    final t = themes[user.role] ??
        (
          g: const [AppColors.primary, AppColors.primaryDark],
          icon: Icons.diversity_3_rounded,
          tagline: 'Welcome to Hum-Raah.'
        );
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: t.g,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back 👋',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13)),
              const SizedBox(height: 4),
              Text(user.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(user.roleLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
              Text(t.tagline,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5,
                      height: 1.4)),
            ],
          ),
        ),
        Icon(t.icon, color: Colors.white24, size: 76),
      ]),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  const _ErrorBanner({required this.error});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child:
                Text(error, style: const TextStyle(color: AppColors.danger))),
      ]),
    );
  }
}

class _FlagsPieChart extends StatelessWidget {
  final List data;
  const _FlagsPieChart({required this.data});
  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.primary, AppColors.secondary, AppColors.accent,
      AppColors.success, AppColors.warning, AppColors.danger,
    ];
    final sections = <PieChartSectionData>[];
    for (var i = 0; i < data.length; i++) {
      final m = data[i] as Map<String, dynamic>;
      sections.add(PieChartSectionData(
        value: (m['count'] as num).toDouble(),
        color: colors[i % colors.length],
        title: '${(m['count'] as num).toInt()}',
        radius: 58,
        titleStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
      ));
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Flags by Category',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        SizedBox(
          height: 200,
          child: Row(children: [
            Expanded(
                child: PieChart(PieChartData(
                    sections: sections,
                    centerSpaceRadius: 32,
                    sectionsSpace: 2))),
            Expanded(
              child: ListView.builder(
                itemCount: data.length,
                itemBuilder: (_, i) {
                  final m = data[i] as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: colors[i % colors.length],
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text('${m['_id'] ?? 'Other'}',
                              style: const TextStyle(fontSize: 12))),
                      Text('${m['count']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12)),
                    ]),
                  );
                },
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _CitizenActionGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tiles = [
      _CTile(Icons.report_problem_outlined, 'Report an Issue',
          'Flag a local case needing NGO help', AppColors.danger, '/report-issue'),
      _CTile(Icons.handshake_outlined, 'Volunteer with NGO',
          'Offer your time to a verified NGO', AppColors.accent, '/volunteer'),
      _CTile(Icons.map_outlined, 'Explore GIS Map',
          'See active projects and flags near you', AppColors.primary, '/map'),
      _CTile(Icons.menu_book_outlined, 'Browse Resources',
          'Guides and educational materials', AppColors.success, '/resources'),
    ];
    return Column(
      children: tiles
          .map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.go(t.path),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border)),
                      child: Row(children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                              color: t.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(t.icon, color: t.color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(t.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              const SizedBox(height: 3),
                              Text(t.subtitle,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.5)),
                            ])),
                        const Icon(Icons.chevron_right,
                            color: AppColors.textMuted),
                      ]),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _CTile {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String path;
  _CTile(this.icon, this.title, this.subtitle, this.color, this.path);
}
