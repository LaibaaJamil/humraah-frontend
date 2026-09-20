import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/ngo.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/status_badge.dart';

class NGODetailScreen extends StatefulWidget {
  final String id;
  const NGODetailScreen({super.key, required this.id});

  @override
  State<NGODetailScreen> createState() => _NGODetailScreenState();
}

class _NGODetailScreenState extends State<NGODetailScreen> {
  NGO? _ngo;
  Map<String, dynamic>? _analytics;
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _projects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ApiService.instance;
      final user = context.read<AuthProvider>().user;
      final res = await api.get('${ApiConstants.ngos}/${widget.id}');
      final ngo = NGO.fromJson(res['data'] as Map<String, dynamic>);
      Map<String, dynamic>? analytics;
      List<Map<String, dynamic>> reports = [];
      List<Map<String, dynamic>> projects = [];
      try {
        final a = await api.get(
          ApiConstants.reportAnalytics,
          query: {'ngo': widget.id},
        );
        analytics = a['data'] as Map<String, dynamic>?;
      } catch (_) {}
      try {
        final r = await api.get(
          ApiConstants.reports,
          query: {'ngo': widget.id},
        );
        reports = ((r['data'] as List?) ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();
      } catch (_) {}
      // Donor orgs load project history to evaluate before awarding tenders
      if (user?.isDonor == true) {
        try {
          final p = await api.get('${ApiConstants.ngos}/${widget.id}/projects');
          final pdata = p['data'] as Map<String, dynamic>?;
          projects = ((pdata?['projects'] as List?) ?? [])
              .map((e) => e as Map<String, dynamic>)
              .toList();
        } catch (_) {}
      }
      setState(() {
        _ngo = ngo;
        _analytics = analytics;
        _reports = reports;
        _projects = projects;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _verify(String status) async {
    final reason = status == 'rejected'
        ? await _askReason()
        : null;
    try {
      await ApiService.instance.put(
        '${ApiConstants.ngos}/${widget.id}/verify',
        body: {'status': status, 'rejectionReason': reason ?? ''},
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NGO ${status == 'verified' ? 'verified' : 'rejected'}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<String?> _askReason() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rejection reason'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Reason'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingIndicator();
    if (_ngo == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              const Text('NGO not found'),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/ngos'),
                child: const Text('Back to directory'),
              ),
            ],
          ),
        ),
      );
    }

    final n = _ngo!;
    final user = context.watch<AuthProvider>().user;
    final canVerify = user?.isSuperAdmin == true && n.isPending;
    final isDonorViewing = user?.isDonor == true;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/ngos'),
            ),
            const Spacer(),
            StatusBadge.verification(n.verificationStatus),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reg# ${n.registrationNumber}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (n.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  n.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
              if (n.sectors.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: n.sectors
                      .map(
                        (s) => Chip(
                          label: Text(s.replaceAll('_', ' ')),
                          backgroundColor: AppColors.primaryLight,
                          labelStyle: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const Divider(height: 32),
              _row(Icons.mail_outline, 'Email', n.email),
              if (n.phone != null && n.phone!.isNotEmpty)
                _row(Icons.phone_outlined, 'Phone', n.phone!),
              if (n.website.isNotEmpty)
                _row(Icons.language, 'Website', n.website),
              if (n.address.isNotEmpty)
                _row(Icons.location_on_outlined, 'Address',
                    '${n.address}${n.city.isNotEmpty ? ', ${n.city}' : ''}'),
              _row(Icons.location_city_outlined, 'Province', n.province),
              _row(Icons.groups_outlined, 'Staff size', '${n.staffCount}'),
              _row(Icons.translate, 'Languages',
                  n.languagesSupported.join(', ')),
              if (n.ownerName != null)
                _row(Icons.person_outline, 'Owner', n.ownerName!),
              if (n.isRejected && n.rejectionReason.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rejected: ${n.rejectionReason}',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (canVerify) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Verify NGO',
                  icon: Icons.verified_outlined,
                  color: AppColors.success,
                  onPressed: () => _verify('verified'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Reject',
                  icon: Icons.block_outlined,
                  color: AppColors.danger,
                  outlined: true,
                  onPressed: () => _verify('rejected'),
                ),
              ),
            ],
          ),
        ],
        // Donor evaluation panel - shown to large orgs considering awarding tender
        if (isDonorViewing && n.isVerified) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.secondary, Color(0xFFC2410C)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(children: [
              Icon(Icons.volunteer_activism_rounded, color: Colors.white54, size: 40),
              SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Donor Evaluation View', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  SizedBox(height: 3),
                  Text('Review this NGO\'s project track record before awarding a tender.',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                ],
              )),
            ]),
          ),
          const SizedBox(height: 14),
          if (_projects.isNotEmpty) ...[
            const Text('Project History on Map',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            ...(_projects.take(5).map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.work_outline, color: AppColors.accent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((p['title'] ?? 'Untitled').toString(),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('${p['city'] ?? ''} · ${p['status'] ?? 'active'}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: p['status'] == 'resolved'
                          ? AppColors.successLight : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (p['status'] ?? 'active').toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        color: p['status'] == 'resolved'
                            ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ),
                ]),
              ),
            ))),
          ],
          ElevatedButton.icon(
            onPressed: () => context.go('/tenders'),
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
            label: const Text('Browse Tenders'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
        const SizedBox(height: 18),
        _ProjectHistory(analytics: _analytics, reports: _reports),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectHistory extends StatelessWidget {
  final Map<String, dynamic>? analytics;
  final List<Map<String, dynamic>> reports;
  const _ProjectHistory({required this.analytics, required this.reports});

  @override
  Widget build(BuildContext context) {
    final totals = (analytics?['totals'] as Map<String, dynamic>?) ?? {};
    final fmt = NumberFormat('#,###');
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
            'Project History & Impact',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Aggregated from monthly reports submitted by this NGO',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          if (reports.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'This NGO has not submitted any monthly reports yet.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          else ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Metric(
                  icon: Icons.people_alt_outlined,
                  label: 'Beneficiaries',
                  value: fmt.format(totals['beneficiariesReached'] ?? 0),
                  color: AppColors.success,
                ),
                _Metric(
                  icon: Icons.event_outlined,
                  label: 'Events',
                  value: fmt.format(totals['eventsConducted'] ?? 0),
                  color: AppColors.accent,
                ),
                _Metric(
                  icon: Icons.payments_outlined,
                  label: 'Funds Used',
                  value: 'PKR ${fmt.format(totals['fundsUtilized'] ?? 0)}',
                  color: AppColors.primary,
                ),
                _Metric(
                  icon: Icons.handshake_outlined,
                  label: 'Volunteers',
                  value: fmt.format(totals['volunteersEngaged'] ?? 0),
                  color: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Recent monthly reports',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...reports.take(5).map((r) {
              final p = (r['period'] as Map?) ?? {};
              final m = (r['metrics'] as Map?) ?? {};
              final monthName = DateFormat('MMMM y').format(
                DateTime(
                  (p['year'] as num?)?.toInt() ?? DateTime.now().year,
                  (p['month'] as num?)?.toInt() ?? 1,
                ),
              );
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 130,
                      child: Text(
                        monthName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${fmt.format(m['beneficiariesReached'] ?? 0)} reached · '
                        '${fmt.format(m['eventsConducted'] ?? 0)} events',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
