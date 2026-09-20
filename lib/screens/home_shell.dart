import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  final List<String>? roles;
  const _NavItem(this.icon, this.label, this.path, {this.roles});
}

class HomeShell extends StatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _items = [
    _NavItem(Icons.dashboard_outlined, 'Dashboard', '/dashboard'),
    _NavItem(Icons.apartment_outlined, 'NGO Directory', '/ngos'),
    _NavItem(Icons.menu_book_outlined, 'Resources', '/resources'),
    _NavItem(Icons.map_outlined, 'GIS Map', '/map'),
    _NavItem(Icons.report_problem_outlined, 'Report Issue', '/report-issue',
        roles: ['public_user']),
    _NavItem(Icons.handshake_outlined, 'Volunteer', '/volunteer',
        roles: ['public_user']),
    _NavItem(Icons.account_balance_wallet_outlined, 'Tenders', '/tenders',
        roles: ['super_admin', 'ngo_admin', 'ngo_staff', 'donor']),
    _NavItem(Icons.bar_chart_outlined, 'Reports', '/reports',
        roles: ['super_admin', 'ngo_admin', 'ngo_staff', 'donor']),
    _NavItem(Icons.swap_horiz_outlined, 'Referrals', '/referrals',
        roles: ['super_admin', 'ngo_admin', 'ngo_staff']),
    _NavItem(Icons.fact_check_outlined, 'Pending', '/admin/pending',
        roles: ['super_admin', 'ngo_admin', 'ngo_staff']),
    _NavItem(Icons.shield_outlined, 'Admin Panel', '/admin',
        roles: ['super_admin']),
  ];

  List<_NavItem> _allowed(String role) =>
      _items.where((i) => i.roles == null || i.roles!.contains(role)).toList();

  @override
  void initState() {
    super.initState();
    // Start polling for notifications after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().startPolling();
    });
  }

  late NotificationProvider _notificationProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notificationProvider = context.read<NotificationProvider>();
  }

  @override
  void dispose() {
    _notificationProvider.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 1024;
    final isMedium = width >= 720 && width < 1024;
    final user = auth.user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final items = _allowed(user.role);
    final loc = GoRouterState.of(context).matchedLocation;
    int currentIndex = items.indexWhere((i) => loc.startsWith(i.path));
    if (currentIndex < 0) currentIndex = 0;

    if (isWide || isMedium) {
      return Scaffold(
        body: Row(children: [
          _Sidebar(items: items, currentPath: loc, expanded: isWide),
          Expanded(
              child: Column(children: [
            _TopBar(user: user),
            Expanded(child: widget.child),
          ])),
        ]),
      );
    }

    final mobileItems = items.take(5).toList();
    int mobileIndex = mobileItems.indexWhere((i) => loc.startsWith(i.path));
    if (mobileIndex < 0) mobileIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.diversity_3_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Hum-Raah'),
        ]),
        actions: [
          _NotifBell(),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      drawer: items.length > 5
          ? Drawer(
              child: SafeArea(
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(user.name.isNotEmpty ? user.name[0] : '?',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(user.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          Text(user.roleLabel,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                        ])),
                  ]),
                ),
                const Divider(),
                Expanded(
                    child: ListView(
                        children: items
                            .map((i) => ListTile(
                                  leading: Icon(i.icon),
                                  title: Text(i.label),
                                  selected: loc.startsWith(i.path),
                                  selectedColor: AppColors.primary,
                                  onTap: () {
                                    Navigator.pop(context);
                                    context.go(i.path);
                                  },
                                ))
                            .toList())),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.danger),
                  title: const Text('Logout',
                      style: TextStyle(color: AppColors.danger)),
                  onTap: () async {
                    context.read<NotificationProvider>().reset();
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            )))
          : null,
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: mobileIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        items: mobileItems
            .map((i) => BottomNavigationBarItem(
                  icon: Icon(i.icon),
                  label: i.label,
                ))
            .toList(),
        onTap: (i) => context.go(mobileItems[i].path),
      ),
    );
  }
}

// ── Notification Bell with Badge ────────────────────────────
class _NotifBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.watch<NotificationProvider>().unreadCount;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => context.go('/notifications'),
          tooltip: 'Notifications',
        ),
        if (count > 0)
          Positioned(
            top: 8,
            right: 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(3),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Sidebar (desktop/tablet) ─────────────────────────────────
class _Sidebar extends StatelessWidget {
  final List<_NavItem> items;
  final String currentPath;
  final bool expanded;
  const _Sidebar(
      {required this.items, required this.currentPath, required this.expanded});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final notifCount = context.watch<NotificationProvider>().unreadCount;
    final width = expanded ? 240.0 : 80.0;

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
          child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment:
                expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.diversity_3_rounded,
                    color: Colors.white, size: 20),
              ),
              if (expanded) ...[
                const SizedBox(width: 10),
                const Text('Hum-Raah',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: items.map((item) {
              final selected = currentPath.startsWith(item.path);
              final isPending = item.path == '/admin/pending';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InkWell(
                  onTap: () => context.go(item.path),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryLight
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: expanded
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        Stack(children: [
                          Icon(item.icon,
                              size: 20,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary),
                          // Show badge on Pending nav item too
                          if (isPending && notifCount > 0)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle),
                              ),
                            ),
                        ]),
                        if (expanded) ...[
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(item.label,
                                  style: TextStyle(
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    fontSize: 14,
                                  ))),
                          if (isPending && notifCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('$notifCount',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1),
        // Notification bell in sidebar
        if (expanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: InkWell(
              onTap: () => context.go('/notifications'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  Stack(children: [
                    const Icon(Icons.notifications_outlined,
                        size: 20, color: AppColors.textSecondary),
                    if (notifCount > 0)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.danger, shape: BoxShape.circle),
                        ),
                      ),
                  ]),
                  const SizedBox(width: 12),
                  const Expanded(
                      child: Text('Notifications',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14))),
                  if (notifCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text('$notifCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                ]),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: InkWell(
            onTap: () => context.go('/profile'),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: expanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(user.name.isNotEmpty ? user.name[0] : '?',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                  ),
                  if (expanded) ...[
                    const SizedBox(width: 10),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(user.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                          Text(user.roleLabel,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                        ])),
                  ],
                ],
              ),
            ),
          ),
        ),
      ])),
    );
  }
}

// ── TopBar (desktop) ─────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final AppUser user;
  const _TopBar({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        Text('Hi, ${user.name.split(' ').first}',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(6)),
          child: Text(user.roleLabel,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11)),
        ),
        const Spacer(),
        _NotifBell(),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: () async {
            context.read<NotificationProvider>().reset();
            await context.read<AuthProvider>().logout();
            if (context.mounted) context.go('/login');
          },
        ),
      ]),
    );
  }
}
