import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/tender.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/loading_indicator.dart';

class TenderDetailScreen extends StatefulWidget {
  final String id;
  const TenderDetailScreen({super.key, required this.id});

  @override
  State<TenderDetailScreen> createState() => _TenderDetailScreenState();
}

class _TenderDetailScreenState extends State<TenderDetailScreen> {
  Tender? _tender;
  List<Map<String, dynamic>> _applications = [];
  bool _loadingApps = false;
  String? _appsError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.instance
          .get('${ApiConstants.tenders}/${widget.id}');
      setState(() {
        _tender = Tender.fromJson(res['data'] as Map<String, dynamic>);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadApplications() async {
    setState(() {
      _loadingApps = true;
      _appsError = null;
    });
    try {
      final res = await ApiService.instance
          .get('${ApiConstants.tenders}/${widget.id}/applications');
      setState(() {
        _applications = ((res['data'] as List?) ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();
        _loadingApps = false;
      });
    } catch (e) {
      setState(() {
        _loadingApps = false;
        _appsError = e.toString();
      });
    }
  }

  Future<void> _decide(String appId, String status) async {
    try {
      await ApiService.instance.put(
        '${ApiConstants.tenders}/applications/$appId',
        body: {'status': status},
      );
      await _loadApplications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application ${status.toLowerCase()}'),
            backgroundColor: status == 'awarded'
                ? AppColors.success
                : AppColors.textSecondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingIndicator();
    final t = _tender;
    if (t == null) {
      return Center(
        child: TextButton(
          onPressed: () => context.go('/tenders'),
          child: const Text('Tender not found · go back'),
        ),
      );
    }
    final user = context.watch<AuthProvider>().user;
    final canApply =
        user != null && (user.isNgoAdmin || user.isNgoStaff) && t.isOpen;
    final isOwner = user != null && t.postedById != null && user.id == t.postedById;
    final canSeeApps = isOwner || user?.isSuperAdmin == true;
    final fmt = NumberFormat('#,###');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/tenders'),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: t.isOpen ? AppColors.successLight : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                t.status.toUpperCase(),
                style: TextStyle(
                  color:
                      t.isOpen ? AppColors.success : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
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
              Text(
                t.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t.donorOrganization.isNotEmpty
                    ? 'Posted by ${t.donorOrganization}'
                    : 'Posted by ${t.postedByName ?? "Donor"}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _kpi(
                      Icons.payments_outlined,
                      'Budget',
                      '${t.currency} ${fmt.format(t.budgetAmount)}',
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _kpi(
                      Icons.schedule_outlined,
                      'Deadline',
                      DateFormat('MMM d, y').format(t.deadline),
                      t.timeLeft.inDays < 7 && t.isOpen
                          ? AppColors.danger
                          : AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _kpi(Icons.location_on_outlined, 'Location',
                        t.location, AppColors.secondary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _kpi(Icons.handshake_outlined,
                        t.allowCoalitions ? 'Coalitions' : 'Solo only',
                        t.allowCoalitions
                            ? 'Up to ${t.maxCoalitionPartners}'
                            : 'Single applicant',
                        AppColors.success),
                  ),
                ],
              ),
              const Divider(height: 32),
              const Text(
                'Description',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t.description,
                style: const TextStyle(
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              if (t.eligibility.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Eligibility',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.eligibility,
                  style: const TextStyle(
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (canApply) ...[
          const SizedBox(height: 16),
          AppButton(
            label: 'Apply to this Tender',
            icon: Icons.send_outlined,
            color: AppColors.primary,
            onPressed: () => _showApplySheet(t),
          ),
        ],
        if (canSeeApps) ...[
          const SizedBox(height: 20),
          _ApplicantsSection(
            applications: _applications,
            loading: _loadingApps,
            error: _appsError,
            onLoad: _loadApplications,
            onDecide: isOwner ? _decide : null,
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _kpi(IconData icon, String label, String value, Color color) {
    return Container(
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
              const SizedBox(width: 4),
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
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showApplySheet(Tender t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _ApplyForm(
          tender: t,
          onApplied: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Application submitted'),
                backgroundColor: AppColors.success,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ApplicantsSection extends StatelessWidget {
  final List<Map<String, dynamic>> applications;
  final bool loading;
  final String? error;
  final Future<void> Function() onLoad;
  final Future<void> Function(String appId, String status)? onDecide;

  const _ApplicantsSection({
    required this.applications,
    required this.loading,
    required this.error,
    required this.onLoad,
    required this.onDecide,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'NGO Applications',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: loading ? null : onLoad,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(applications.isEmpty ? 'Load' : 'Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'NGOs that have applied to this tender. Review their proposals before awarding.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(error!,
                  style: const TextStyle(color: AppColors.danger)),
            )
          else if (applications.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No applications yet. Click "Load" to refresh.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          else
            ...applications.map((a) => _ApplicantCard(
                  app: a,
                  onDecide: onDecide,
                )),
        ],
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final Map<String, dynamic> app;
  final Future<void> Function(String appId, String status)? onDecide;
  const _ApplicantCard({required this.app, required this.onDecide});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final ngo = (app['applicantNGO'] as Map?) ?? {};
    final submittedBy = (app['submittedBy'] as Map?) ?? {};
    final status = (app['status'] ?? 'submitted').toString();
    final amount = app['requestedAmount'] as num? ?? 0;
    final months = app['timelineMonths'] as num? ?? 12;
    final summary = (app['proposalSummary'] ?? '').toString();
    final coalition =
        (app['coalitionPartners'] as List?) ?? const [];
    final ngoId = (ngo['_id'] ?? ngo['id'])?.toString();
    final appId = (app['_id'] ?? '').toString();

    Color statusColor;
    switch (status) {
      case 'awarded':
        statusColor = AppColors.success;
        break;
      case 'rejected':
        statusColor = AppColors.danger;
        break;
      case 'shortlisted':
        statusColor = AppColors.accent;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.apartment_outlined,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (ngo['name'] ?? 'Unknown NGO').toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    Text(
                      '${ngo['sector'] ?? ''} · ${ngo['city'] ?? ''}'
                          .replaceAll(RegExp(r'^ · | · $'), ''),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _kpi('Requested', 'PKR ${fmt.format(amount)}'),
              const SizedBox(width: 16),
              _kpi('Timeline', '${months.toInt()} months'),
              const SizedBox(width: 16),
              _kpi('Coalition', '${coalition.length} partners'),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              summary,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (submittedBy['name'] != null)
                Expanded(
                  child: Text(
                    'Contact: ${submittedBy['name']}'
                    '${submittedBy['email'] != null ? ' · ${submittedBy['email']}' : ''}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
              if (ngoId != null)
                TextButton.icon(
                  onPressed: () => context.go('/ngos/$ngoId'),
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('View NGO'),
                ),
            ],
          ),
          if (onDecide != null && status == 'submitted') ...[
            const Divider(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onDecide!(appId, 'shortlisted'),
                    icon: const Icon(Icons.star_outline, size: 16),
                    label: const Text('Shortlist'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onDecide!(appId, 'awarded'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Award'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => onDecide!(appId, 'rejected'),
                    icon: const Icon(Icons.close, size: 16,
                        color: AppColors.danger),
                    label: const Text('Reject',
                        style: TextStyle(color: AppColors.danger)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _kpi(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ApplyForm extends StatefulWidget {
  final Tender tender;
  final VoidCallback onApplied;
  const _ApplyForm({required this.tender, required this.onApplied});

  @override
  State<_ApplyForm> createState() => _ApplyFormState();
}

class _ApplyFormState extends State<_ApplyForm> {
  final _formKey = GlobalKey<FormState>();
  final _summary = TextEditingController();
  final _amount = TextEditingController();
  final _months = TextEditingController(text: '12');
  bool _saving = false;

  @override
  void dispose() {
    _summary.dispose();
    _amount.dispose();
    _months.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiService.instance.post(
        '${ApiConstants.tenders}/${widget.tender.id}/apply',
        body: {
          'proposalSummary': _summary.text.trim(),
          'requestedAmount': num.tryParse(_amount.text) ?? 0,
          'timelineMonths': int.tryParse(_months.text) ?? 12,
        },
      );
      widget.onApplied();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Apply to tender',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _summary,
              label: 'Proposal summary',
              hint: 'Describe your approach in 3-5 sentences',
              prefixIcon: Icons.description_outlined,
              maxLines: 4,
              validator: (v) =>
                  v == null || v.length < 20 ? 'Min 20 characters' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _amount,
              label: 'Requested amount (PKR)',
              hint: 'e.g. 2500000',
              prefixIcon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  num.tryParse(v ?? '') == null ? 'Enter a number' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _months,
              label: 'Timeline (months)',
              hint: '12',
              prefixIcon: Icons.calendar_today_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'Submit Application',
              icon: Icons.send,
              loading: _saving,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
