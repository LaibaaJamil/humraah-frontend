import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/ngo.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';

class DonorManagementScreen extends StatefulWidget {
  const DonorManagementScreen({super.key});
  @override
  State<DonorManagementScreen> createState() => _DonorManagementScreenState();
}

class _DonorManagementScreenState extends State<DonorManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _donors = [];
  List<NGO> _ngos = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
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
      final results = await Future.wait([
        ApiService.instance.get(ApiConstants.adminUsers),
        ApiService.instance.get('${ApiConstants.adminUsers}?role=donor'),
        ApiService.instance
            .get('${ApiConstants.ngos}?status=verified&limit=200'),
      ]);
      final allUsersRaw = (results[0]['data'] as List?) ?? [];
      final donorsRaw = (results[1]['data'] as List?) ?? [];
      final ngosRaw = (results[2]['data'] as List?) ?? [];

      final allUsers = <Map<String, dynamic>>[];
      for (final e in allUsersRaw) {
        if (e is Map<String, dynamic>) allUsers.add(e);
      }
      final donors = <Map<String, dynamic>>[];
      for (final e in donorsRaw) {
        if (e is Map<String, dynamic>) donors.add(e);
      }
      final ngos = <NGO>[];
      for (final e in ngosRaw) {
        try {
          if (e is Map<String, dynamic>) ngos.add(NGO.fromJson(e));
        } catch (_) {
          // Skip any single malformed NGO record instead of failing the whole list
        }
      }

      setState(() {
        _allUsers = allUsers
            .where((u) => !['donor', 'super_admin'].contains(u['role']))
            .toList();
        _donors = donors;
        _ngos = ngos;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _markDonor(String id, String name) async {
    final ok = await _confirm('Mark "$name" as Donor?',
        'They will gain access to donor features and tenders.');
    if (!ok) return;
    try {
      await ApiService.instance
          .put('${ApiConstants.adminMarkDonor}/$id/mark-donor');
      _snack('$name marked as Donor ✅', AppColors.success);
      _load();
    } catch (e) {
      _snack(e.toString(), AppColors.danger);
    }
  }

  Future<void> _toggleLargeOrg(
      String id, String name, bool isCurrentlyLarge) async {
    final newVal = !isCurrentlyLarge;
    final ok = await _confirm(
      newVal
          ? 'Mark "$name" as Large Organization?'
          : 'Remove Large Org status from "$name"?',
      newVal ? 'Large Org donors can post tenders on the platform.' : '',
    );
    if (!ok) return;
    try {
      await ApiService.instance.put(
        '${ApiConstants.adminUsers}/$id/toggle-large-org',
        body: {'isLargeOrg': newVal},
      );
      _snack(
          newVal ? '$name marked as Large Org ✅' : 'Large Org status removed',
          AppColors.success);
      _load();
    } catch (e) {
      _snack(e.toString(), AppColors.danger);
    }
  }

  Future<void> _removeDonor(String id, String name) async {
    final ok = await _confirm('Remove donor status from "$name"?', '');
    if (!ok) return;
    try {
      await ApiService.instance.put('${ApiConstants.adminUsers}/$id/role',
          body: {'role': 'public_user'});
      _snack('Donor status removed', AppColors.warning);
      _load();
    } catch (e) {
      _snack(e.toString(), AppColors.danger);
    }
  }

  Future<void> _assignNgo(String userId, String userName) async {
    NGO? selected;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Assign NGO to $userName'),
          content: SizedBox(
            width: double.maxFinite,
            child: DropdownButtonFormField<NGO>(
              decoration: const InputDecoration(labelText: 'Select NGO'),
              initialValue: selected,
              items: _ngos
                  .map((n) => DropdownMenuItem(value: n, child: Text(n.name)))
                  .toList(),
              onChanged: (v) => setS(() => selected = v),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selected == null ? null : () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    try {
      await ApiService.instance.put(
          '${ApiConstants.adminAssignNgo}/$userId/assign-ngo',
          body: {'ngoId': selected!.id});
      _snack('$userName assigned to ${selected!.name} ✅', AppColors.success);
      _load();
    } catch (e) {
      _snack(e.toString(), AppColors.danger);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  /// Wraps a list item builder so a single malformed record shows an inline
  /// error row instead of crashing/blanking the entire screen.
  Widget _safeBuilder(Widget Function() build) {
    try {
      return build();
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('Could not display this item ($e)',
            style: const TextStyle(color: AppColors.danger, fontSize: 12)),
      );
    }
  }

  Future<bool> _confirm(String title, String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: msg.isNotEmpty ? Text(msg) : null,
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _allUsers
        .where((u) =>
            _search.isEmpty ||
            (u['name'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_search.toLowerCase()) ||
            (u['email'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_search.toLowerCase()))
        .toList();

    final ngoUsers = filtered
        .where((u) => ['ngo_admin', 'ngo_staff'].contains(u['role']))
        .toList();
    final nonNgoUsers = filtered
        .where((u) => !['ngo_admin', 'ngo_staff'].contains(u['role']))
        .toList();

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
                  child: Row(children: [
                    IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.go('/admin')),
                    const Expanded(
                      child: Text('User Management',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_outlined)),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon:
                          const Icon(Icons.search, color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.primary,
                  indicatorColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted,
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.volunteer_activism_outlined,
                          size: 16),
                      text: 'Donors (${_donors.length})',
                    ),
                    Tab(
                      icon: const Icon(Icons.person_add_outlined, size: 16),
                      text: 'Mark Donors (${nonNgoUsers.length})',
                    ),
                    Tab(
                      icon: const Icon(Icons.apartment_outlined, size: 16),
                      text: 'Assign NGO (${ngoUsers.length})',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingIndicator()
                : TabBarView(
                    controller: _tabs,
                    children: [
                      // ── TAB 1: Current Donors ──────────────────
                      _donors.isEmpty
                          ? const EmptyState(
                              icon: Icons.volunteer_activism_outlined,
                              title: 'No donors yet',
                              message:
                                  'Mark users as donors from the next tab.')
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _donors.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) => _safeBuilder(() {
                                final u = _donors[i];
                                final name = (u['name'] ?? '').toString();
                                final email = (u['email'] ?? '').toString();
                                final uid = (u['_id'] ?? '').toString();
                                final isLarge = u['isLargeOrg'] == true;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.secondary
                                        .withValues(alpha: 0.15),
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  title: Row(children: [
                                    Text(name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 6),
                                    if (isLarge)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text('LARGE ORG',
                                            style: TextStyle(
                                                color: AppColors.accent,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700)),
                                      ),
                                  ]),
                                  subtitle: Text(email,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Toggle Large Org
                                      Tooltip(
                                        message: isLarge
                                            ? 'Remove Large Org status'
                                            : 'Mark as Large Org',
                                        child: GestureDetector(
                                          onTap: () => _toggleLargeOrg(
                                              uid, name, isLarge),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isLarge
                                                  ? AppColors.accent
                                                      .withValues(alpha: 0.15)
                                                  : AppColors.surfaceAlt,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: isLarge
                                                      ? AppColors.accent
                                                      : AppColors.border),
                                            ),
                                            child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.business_outlined,
                                                      size: 14,
                                                      color: isLarge
                                                          ? AppColors.accent
                                                          : AppColors
                                                              .textMuted),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                      isLarge
                                                          ? 'Large Org ✓'
                                                          : 'Large Org',
                                                      style: TextStyle(
                                                          color: isLarge
                                                              ? AppColors.accent
                                                              : AppColors
                                                                  .textMuted,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600)),
                                                ]),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        onPressed: () =>
                                            _removeDonor(uid, name),
                                        icon: const Icon(Icons.person_remove,
                                            color: AppColors.danger, size: 18),
                                        tooltip: 'Remove donor status',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 32, minHeight: 32),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),

                      // ── TAB 2: Mark as Donor ──────────────────
                      nonNgoUsers.isEmpty
                          ? const EmptyState(
                              icon: Icons.people_outlined,
                              title: 'No users found',
                              message: 'All eligible users are already donors.')
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: nonNgoUsers.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) => _safeBuilder(() {
                                final u = nonNgoUsers[i];
                                final name = (u['name'] ?? '').toString();
                                final email = (u['email'] ?? '').toString();
                                final role = (u['role'] ?? '').toString();
                                final uid = (u['_id'] ?? '').toString();
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primaryLight,
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  title: Text(name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text('$email  •  $role',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted)),
                                  trailing: ElevatedButton.icon(
                                    onPressed: () => _markDonor(uid, name),
                                    icon: const Icon(Icons.volunteer_activism,
                                        size: 14),
                                    label: const Text('Donor'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(fontSize: 12),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                    ),
                                  ),
                                );
                              }),
                            ),

                      // ── TAB 3: Assign NGO to Staff ────────────
                      ngoUsers.isEmpty
                          ? const EmptyState(
                              icon: Icons.apartment_outlined,
                              title: 'No NGO staff/admin users',
                              message:
                                  'NGO staff and admins who need NGO assignment appear here.')
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: ngoUsers.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) => _safeBuilder(() {
                                final u = ngoUsers[i];
                                final name = (u['name'] ?? '').toString();
                                final email = (u['email'] ?? '').toString();
                                final role = (u['role'] ?? '').toString();
                                final uid = (u['_id'] ?? '').toString();
                                final ngoData =
                                    u['ngo'] is Map ? u['ngo'] as Map : null;
                                final assignedNgo =
                                    (ngoData?['name'] ?? u['ngo'])
                                            ?.toString() ??
                                        '';
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: assignedNgo.isNotEmpty
                                        ? AppColors.successLight
                                        : AppColors.warningLight,
                                    child: Icon(
                                      assignedNgo.isNotEmpty
                                          ? Icons.check
                                          : Icons.warning_amber_outlined,
                                      color: assignedNgo.isNotEmpty
                                          ? AppColors.success
                                          : AppColors.warning,
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('$email  •  $role',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted)),
                                      if (assignedNgo.isNotEmpty)
                                        Text('NGO: $assignedNgo',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.success,
                                                fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  trailing: ElevatedButton.icon(
                                    onPressed: () => _assignNgo(uid, name),
                                    icon: const Icon(Icons.apartment_outlined,
                                        size: 14),
                                    label: Text(assignedNgo.isNotEmpty
                                        ? 'Reassign'
                                        : 'Assign NGO'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: assignedNgo.isNotEmpty
                                          ? AppColors.primary
                                          : AppColors.warning,
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(fontSize: 12),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                    ),
                                  ),
                                );
                              }),
                            ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
