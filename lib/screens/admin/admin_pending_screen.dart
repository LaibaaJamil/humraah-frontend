import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/ngo.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/status_badge.dart';

class AdminPendingScreen extends StatefulWidget {
  const AdminPendingScreen({super.key});
  @override
  State<AdminPendingScreen> createState() => _AdminPendingScreenState();
}

class _AdminPendingScreenState extends State<AdminPendingScreen>
    with SingleTickerProviderStateMixin {
  List<NGO> _pendingNGOs = [];
  List<Map<String, dynamic>> _pendingPins = [];
  bool _loading = true;
  late TabController _tabs;
  late bool _isSuperAdmin;
  late bool _isNgoAdmin;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _isSuperAdmin = user?.isSuperAdmin == true;
    _isNgoAdmin = user?.isNgoAdmin == true;
    // Super admin: 2 tabs (NGOs + Pending Reports) | NGO Admin / NGO Staff: 1 tab (Pending Reports)
    final tabCount = _isSuperAdmin ? 2 : 1;
    _tabs = TabController(length: tabCount, vsync: this);
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
      final api = ApiService.instance;
      final futures = <Future>[
        api.get(ApiConstants.mapPinsPending),
        if (_isSuperAdmin) api.get(ApiConstants.adminPending),
      ];
      final results = await Future.wait(futures);
      setState(() {
        _pendingPins = ((results[0]['data'] as List?) ?? []).map((e) => e as Map<String, dynamic>).toList();
        if (_isSuperAdmin && results.length > 1) {
          _pendingNGOs = ((results[1]['data'] as List?) ?? []).map((e) => NGO.fromJson(e as Map<String, dynamic>)).toList();
        }
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  // ── NGO Actions (super admin only) ──────────────────────────────
  Future<void> _verifyNGO(String id) async {
    try {
      await ApiService.instance.put('${ApiConstants.ngos}/$id/verify', body: {'status': 'verified'});
      _snack('NGO verified ✅', AppColors.success);
      _load();
    } catch (e) { _snack(e.toString(), AppColors.danger); }
  }

  Future<void> _rejectNGO(String id) async {
    final reason = await _askText('Rejection Reason');
    if (reason == null) return;
    try {
      await ApiService.instance.put('${ApiConstants.ngos}/$id/verify', body: {'status': 'rejected', 'rejectionReason': reason});
      _snack('NGO rejected', AppColors.warning);
      _load();
    } catch (e) { _snack(e.toString(), AppColors.danger); }
  }

  // ── Pending Pin Actions (ngo_admin + super_admin only — staff is view-only) ─
  Future<void> _verifyPin(String id) async {
    try {
      await ApiService.instance.patch('${ApiConstants.mapPins}/$id/verify');
      _snack('Report verified ✅', AppColors.success);
      _load();
    } catch (e) { _snack(e.toString(), AppColors.danger); }
  }

  Future<void> _rejectPin(String id) async {
    try {
      await ApiService.instance.patch('${ApiConstants.mapPins}/$id/reject');
      _snack('Report rejected', AppColors.warning);
      _load();
    } catch (e) { _snack(e.toString(), AppColors.danger); }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<String?> _askText(String title) => showDialog<String>(
    context: context,
    builder: (_) {
      final c = TextEditingController();
      return AlertDialog(
        title: Text(title),
        content: TextField(controller: c, maxLines: 3, decoration: const InputDecoration(hintText: 'Enter here...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    // canAct = can verify/reject (ngo_admin or super_admin only, NOT ngo_staff)
    final canAct = _isSuperAdmin || _isNgoAdmin;

    return Scaffold(
      body: Column(children: [
        Container(
          color: AppColors.surface,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/dashboard')),
                const Expanded(child: Text('Pending Verifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
                IconButton(onPressed: _load, icon: const Icon(Icons.refresh_outlined)),
              ]),
            ),
            if (!canAct)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(children: [
                  Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
                  SizedBox(width: 6),
                  Text('You can view pending items. Only NGO Admin can verify/reject.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ]),
              ),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              indicatorColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              tabs: [
                if (_isSuperAdmin)
                  Tab(icon: const Icon(Icons.apartment_outlined, size: 16), text: 'NGOs (${_pendingNGOs.length})'),
                Tab(icon: const Icon(Icons.flag_outlined, size: 16), text: 'Pending Reports (${_pendingPins.length})'),
              ],
            ),
          ]),
        ),
        Expanded(
          child: _loading
              ? const LoadingIndicator()
              : TabBarView(
                  controller: _tabs,
                  children: [
                    if (_isSuperAdmin)
                      _NGOTab(ngos: _pendingNGOs, canAct: _isSuperAdmin, onVerify: _verifyNGO, onReject: _rejectNGO),
                    _PinsTab(pins: _pendingPins, canAct: canAct, onVerify: _verifyPin, onReject: _rejectPin),
                  ],
                ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════
//  NGO TAB
// ══════════════════════════════════════════════
class _NGOTab extends StatelessWidget {
  final List<NGO> ngos;
  final bool canAct;
  final Function(String) onVerify;
  final Function(String) onReject;
  const _NGOTab({required this.ngos, required this.canAct, required this.onVerify, required this.onReject});

  @override
  Widget build(BuildContext context) {
    if (ngos.isEmpty) return const EmptyState(icon: Icons.apartment_outlined, title: 'No pending NGOs', message: 'All NGO applications have been reviewed.');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: ngos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final n = ngos[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(n.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
              StatusBadge.verification(n.verificationStatus),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 14, runSpacing: 4, children: [
              _info(Icons.location_city_outlined, n.city),
              _info(Icons.category_outlined, n.sectors.take(2).join(', ')),
              if (n.ownerName != null) _info(Icons.person_outline, n.ownerName!),
            ]),
            if (canAct) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: ElevatedButton.icon(
                  onPressed: () => onVerify(n.id),
                  icon: const Icon(Icons.check, size: 15), label: const Text('Verify'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                )),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => onReject(n.id),
                  icon: const Icon(Icons.close, size: 15, color: AppColors.danger),
                  label: const Text('Reject', style: TextStyle(color: AppColors.danger)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
                ),
              ]),
            ],
          ]),
        );
      },
    );
  }

  Widget _info(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: AppColors.textMuted), const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
    ]);
  }
}

// ══════════════════════════════════════════════
//  PENDING PINS / REPORTS TAB
//  (single unified pipeline: citizen-raised flags
//   AND any NGO-staff pins awaiting review)
// ══════════════════════════════════════════════
class _PinsTab extends StatelessWidget {
  final List<Map<String, dynamic>> pins;
  final bool canAct;
  final Function(String) onVerify;
  final Function(String) onReject;
  const _PinsTab({required this.pins, required this.canAct, required this.onVerify, required this.onReject});

  @override
  Widget build(BuildContext context) {
    if (pins.isEmpty) return const EmptyState(icon: Icons.flag_outlined, title: 'No pending reports', message: 'All reports have been reviewed.');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pins.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final p = pins[i];
        final pid = (p['_id'] ?? '').toString();
        final type = (p['type'] ?? 'flag').toString();
        final title = (p['title'] ?? 'Untitled').toString();
        final desc = (p['description'] ?? '').toString();
        final city = (p['city'] ?? '').toString();
        final urgency = (p['urgencyLevel'] ?? 'medium').toString();
        final category = (p['flagCategory'] ?? 'other').toString();
        final createdBy = p['createdBy'] is Map ? p['createdBy'] as Map : <String, dynamic>{};
        final trust = (createdBy['trustScore'] as num?)?.toInt() ?? 50;
        final isFlag = type == 'flag';
        final images = (p['images'] as List?) ?? [];

        Color uc;
        switch (urgency) {
          case 'critical': uc = AppColors.danger; break;
          case 'high': uc = AppColors.secondary; break;
          case 'medium': uc = AppColors.warning; break;
          default: uc = AppColors.textMuted;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: uc.withValues(alpha: 0.3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _chip(isFlag ? urgency.toUpperCase() : type.toUpperCase(), uc),
              const SizedBox(width: 8),
              if (isFlag) _chip(category, AppColors.primary),
              const Spacer(),
              Row(children: [
                Icon(Icons.shield_outlined, size: 13, color: trust >= 70 ? AppColors.success : trust >= 40 ? AppColors.warning : AppColors.danger),
                const SizedBox(width: 3),
                Text('Trust: $trust', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: trust >= 70 ? AppColors.success : trust >= 40 ? AppColors.warning : AppColors.danger)),
              ]),
            ]),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted), const SizedBox(width: 4),
              Text(city.isNotEmpty ? city : 'Location not set', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(width: 14),
              const Icon(Icons.person_outline, size: 13, color: AppColors.textMuted), const SizedBox(width: 4),
              Text((createdBy['name'] ?? 'Unknown').toString(), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ]),
            if (images.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.photo_outlined, size: 13, color: AppColors.primary), const SizedBox(width: 4),
                Text('${images.length} image(s) attached', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ],
            if (canAct) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: ElevatedButton.icon(
                  onPressed: () => onVerify(pid),
                  icon: const Icon(Icons.check_circle_outline, size: 15), label: const Text('Verify'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                )),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => onReject(pid),
                  icon: const Icon(Icons.cancel_outlined, size: 15, color: AppColors.danger),
                  label: const Text('Reject', style: TextStyle(color: AppColors.danger)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
                )),
              ]),
            ] else ...[
              const SizedBox(height: 8),
              const Text('View only — NGO Admin can verify/reject', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ]),
        );
      },
    );
  }

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 10)),
  );
}
