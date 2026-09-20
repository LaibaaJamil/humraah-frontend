import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';
import 'package:intl/intl.dart';

class VolunteerRequestsScreen extends StatefulWidget {
  const VolunteerRequestsScreen({super.key});
  @override
  State<VolunteerRequestsScreen> createState() =>
      _VolunteerRequestsScreenState();
}

class _VolunteerRequestsScreenState extends State<VolunteerRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _incoming = [];
  List<Map<String, dynamic>> _myRequests = [];
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
      final isNgo = user?.isNgoAdmin == true || user?.isNgoStaff == true;
      if (isNgo) {
        final results = await Future.wait([
          ApiService.instance.get(ApiConstants.volunteerForNgo),
          ApiService.instance.get(ApiConstants.volunteerMine),
        ]);
        final incomingRaw = (results[0]['data'] as List?) ?? [];
        final mineRaw = (results[1]['data'] as List?) ?? [];
        final incoming = <Map<String, dynamic>>[];
        for (final e in incomingRaw) {
          if (e is Map<String, dynamic>) incoming.add(e);
        }
        final mine = <Map<String, dynamic>>[];
        for (final e in mineRaw) {
          if (e is Map<String, dynamic>) mine.add(e);
        }
        setState(() {
          _incoming = incoming;
          _myRequests = mine;
        });
      } else {
        final res = await ApiService.instance.get(ApiConstants.volunteerMine);
        final mineRaw = (res['data'] as List?) ?? [];
        final mine = <Map<String, dynamic>>[];
        for (final e in mineRaw) {
          if (e is Map<String, dynamic>) mine.add(e);
        }
        setState(() => _myRequests = mine);
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load requests: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _respond(String id, String status) async {
    final ctrl = TextEditingController(
        text: status == 'accepted'
            ? 'Welcome! We\'ll be in touch with your first assignment.'
            : '');
    final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: Text(status == 'accepted'
                  ? 'Accept Volunteer'
                  : 'Decline Request'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(status == 'accepted'
                    ? 'Send a welcome message:'
                    : 'Reason (optional):'),
                const SizedBox(height: 10),
                TextField(
                    controller: ctrl,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Message...')),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: status == 'accepted'
                          ? AppColors.success
                          : AppColors.danger,
                      foregroundColor: Colors.white),
                  child: Text(status == 'accepted' ? 'Accept' : 'Decline'),
                ),
              ],
            ));
    if (ok != true || !mounted) return;
    try {
      await ApiService.instance.put('${ApiConstants.volunteers}/$id/respond',
          body: {'status': status, 'response': ctrl.text.trim()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'accepted'
              ? '✅ Volunteer accepted!'
              : 'Request declined'),
          backgroundColor:
              status == 'accepted' ? AppColors.success : AppColors.warning,
        ));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isNgo = user?.isNgoAdmin == true || user?.isNgoStaff == true;
    final pendingCount =
        _incoming.where((r) => r['status'] == 'pending').length;

    return Scaffold(
      body: Column(children: [
        Container(
          color: AppColors.surface,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
              child: Row(children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/dashboard')),
                const Expanded(
                    child: Text('Volunteer Requests',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800))),
                if (pendingCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('$pendingCount pending',
                        style: const TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
              ]),
            ),
            if (isNgo)
              TabBar(
                controller: _tabs,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: [
                  Tab(text: 'Incoming ($pendingCount new)'),
                  const Tab(text: 'My Applications'),
                ],
              )
            else
              const SizedBox(height: 12),
          ]),
        ),
        Expanded(
          child: _loading
              ? const LoadingIndicator()
              : isNgo
                  ? TabBarView(controller: _tabs, children: [
                      _IncomingList(requests: _incoming, onRespond: _respond),
                      _MyList(requests: _myRequests),
                    ])
                  : _MyList(requests: _myRequests),
        ),
      ]),
    );
  }
}

class _IncomingList extends StatelessWidget {
  final List<Map<String, dynamic>> requests;
  final Function(String, String) onRespond;
  const _IncomingList({required this.requests, required this.onRespond});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const EmptyState(
        icon: Icons.handshake_outlined,
        title: 'No volunteer requests yet',
        message:
            'When citizens apply to volunteer with your NGO, they appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = requests[i];
        final isPending = r['status'] == 'pending';
        return _VolCard(
          request: r,
          actions: isPending
              ? Row(children: [
                  Expanded(
                      child: ElevatedButton.icon(
                    onPressed: () => onRespond(r['_id'].toString(), 'accepted'),
                    icon: const Icon(Icons.check_circle_outline, size: 15),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white),
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: OutlinedButton.icon(
                    onPressed: () => onRespond(r['_id'].toString(), 'declined'),
                    icon: const Icon(Icons.cancel_outlined,
                        size: 15, color: AppColors.danger),
                    label: const Text('Decline',
                        style: TextStyle(color: AppColors.danger)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger)),
                  )),
                ])
              : null,
        );
      },
    );
  }
}

class _MyList extends StatelessWidget {
  final List<Map<String, dynamic>> requests;
  const _MyList({required this.requests});
  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return EmptyState(
        icon: Icons.handshake_outlined,
        title: 'No applications yet',
        message: 'Browse NGOs and apply to volunteer with them.',
        action: TextButton.icon(
          onPressed: () => context.go('/volunteer'),
          icon: const Icon(Icons.search),
          label: const Text('Find NGOs'),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _VolCard(request: requests[i], actions: null),
    );
  }
}

class _VolCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final Widget? actions;
  const _VolCard({required this.request, required this.actions});

  Color _sc(String s) => s == 'accepted'
      ? AppColors.success
      : s == 'declined'
          ? AppColors.danger
          : AppColors.warning;

  @override
  Widget build(BuildContext context) {
    try {
      return _buildCard(context);
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.danger),
        ),
        child: Text('Could not display this request ($e)',
            style: const TextStyle(color: AppColors.danger, fontSize: 12)),
      );
    }
  }

  Widget _buildCard(BuildContext context) {
    final r = request;
    final user = r['user'] is Map<String, dynamic>
        ? r['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    final ngo = r['ngo'] is Map<String, dynamic>
        ? r['ngo'] as Map<String, dynamic>
        : <String, dynamic>{};
    final status = (r['status'] ?? 'pending').toString();
    final skillsRaw = r['skills'];
    final skills = skillsRaw is List
        ? skillsRaw
            .map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList()
        : <String>[];
    final createdAt = r['createdAt'] != null
        ? DateTime.tryParse(r['createdAt'].toString())
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: status == 'pending'
                ? AppColors.warning.withValues(alpha: 0.4)
                : AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                  (user['name'] ?? ngo['name'] ?? '?').toString().isNotEmpty
                      ? (user['name'] ?? ngo['name'] ?? '?')
                          .toString()[0]
                          .toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text((user['name'] ?? ngo['name'] ?? 'Unknown').toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text((user['email'] ?? ngo['name'] ?? '').toString(),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: _sc(status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6)),
            child: Text(status.toUpperCase(),
                style: TextStyle(
                    color: _sc(status),
                    fontWeight: FontWeight.w700,
                    fontSize: 10)),
          ),
        ]),
        if ((r['message'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(r['message'].toString(),
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4))),
        ],
        if (skills.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
              spacing: 6,
              runSpacing: 4,
              children: skills
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(s,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11)),
                      ))
                  .toList()),
        ],
        Row(children: [
          if ((r['availability'] ?? '').toString().isNotEmpty) ...[
            const Icon(Icons.schedule_outlined,
                size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(r['availability'].toString(),
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            const SizedBox(width: 10),
          ],
          if (createdAt != null) ...[
            const Icon(Icons.calendar_today_outlined,
                size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(DateFormat('MMM d').format(createdAt),
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ]),
        if ((r['response'] ?? '').toString().isNotEmpty &&
            status != 'pending') ...[
          const SizedBox(height: 8),
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: _sc(status).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(
                    status == 'accepted'
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    size: 14,
                    color: _sc(status)),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(r['response'].toString(),
                        style: TextStyle(color: _sc(status), fontSize: 12.5))),
              ])),
        ],
        if (actions != null) ...[const SizedBox(height: 12), actions!],
      ]),
    );
  }
}
