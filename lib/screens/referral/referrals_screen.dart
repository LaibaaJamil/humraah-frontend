import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/ngo.dart';
import '../../models/referral.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/status_badge.dart';

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Referral> _incoming = [];
  List<Referral> _outgoing = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
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
      final res = await Future.wait([
        api.get(ApiConstants.incomingReferrals),
        api.get(ApiConstants.outgoingReferrals),
      ]);
      _incoming = (res[0]['data'] as List)
          .map((e) => Referral.fromJson(e as Map<String, dynamic>))
          .toList();
      _outgoing = (res[1]['data'] as List)
          .map((e) => Referral.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _respond(Referral r, String status) async {
    try {
      await ApiService.instance.put(
        '${ApiConstants.referrals}/${r.id}/respond',
        body: {'status': status},
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      floatingActionButton: (user?.isNgoAdmin == true || user?.isNgoStaff == true)
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateSheet(),
              icon: const Icon(Icons.send_outlined),
              label: const Text('Refer Case'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Case Referrals',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'AES-encrypted secure case transfers between NGOs',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabs,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.inbox_outlined),
                      text: 'Incoming',
                    ),
                    Tab(
                      icon: Icon(Icons.outbox_outlined),
                      text: 'Outgoing',
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
                      _buildList(_incoming, true),
                      _buildList(_outgoing, false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Referral> items, bool isIncoming) {
    if (items.isEmpty) {
      return EmptyState(
        icon: isIncoming
            ? Icons.inbox_outlined
            : Icons.outbox_outlined,
        title: isIncoming ? 'No incoming referrals' : 'No outgoing referrals',
        message: isIncoming
            ? 'Cases referred to your NGO will appear here.'
            : 'Refer a case to another NGO using the button below.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final r = items[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _categoryColor(r.caseCategory).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _categoryIcon(r.caseCategory),
                        color: _categoryColor(r.caseCategory),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.caseTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isIncoming
                                ? 'From: ${r.fromNGOName ?? "Unknown"}'
                                : 'To: ${r.toNGOName ?? "Unknown"}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge.urgency(r.urgency),
                  ],
                ),
                if (r.details.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lock_outline,
                            size: 14, color: AppColors.success),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            r.details,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (r.contact.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          r.contact,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor(r.status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        r.status.toUpperCase(),
                        style: TextStyle(
                          color: _statusColor(r.status),
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (r.createdAt != null)
                      Text(
                        DateFormat('MMM d').format(r.createdAt!),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                if (isIncoming && r.status == 'pending') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _respond(r, 'accepted'),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Accept'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: const BorderSide(color: AppColors.success),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _respond(r, 'declined'),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Decline'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Color _categoryColor(String c) {
    switch (c) {
      case 'medical':
        return AppColors.danger;
      case 'legal':
        return AppColors.accent;
      case 'shelter':
        return AppColors.secondary;
      case 'rehabilitation':
        return AppColors.success;
      case 'counselling':
        return AppColors.primary;
      case 'financial':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _categoryIcon(String c) {
    switch (c) {
      case 'medical':
        return Icons.medical_services_outlined;
      case 'legal':
        return Icons.gavel_outlined;
      case 'shelter':
        return Icons.house_outlined;
      case 'rehabilitation':
        return Icons.psychology_outlined;
      case 'counselling':
        return Icons.support_outlined;
      case 'financial':
        return Icons.payments_outlined;
      default:
        return Icons.swap_horiz_outlined;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'accepted':
        return AppColors.success;
      case 'declined':
        return AppColors.danger;
      case 'closed':
        return AppColors.textMuted;
      default:
        return AppColors.warning;
    }
  }

  void _showCreateSheet() async {
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
        child: _CreateReferralForm(onCreated: () {
          Navigator.pop(context);
          _load();
        }),
      ),
    );
  }
}

class _CreateReferralForm extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateReferralForm({required this.onCreated});

  @override
  State<_CreateReferralForm> createState() => _CreateReferralFormState();
}

class _CreateReferralFormState extends State<_CreateReferralForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _details = TextEditingController();
  final _contact = TextEditingController();
  String _category = 'medical';
  String _urgency = 'medium';
  String? _selectedNgoId;
  List<NGO> _ngos = [];
  bool _loadingNgos = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadNgos();
  }

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _loadNgos() async {
    try {
      final res = await ApiService.instance.get(
        ApiConstants.ngos,
        query: {'status': 'verified', 'limit': 100},
      );
      final user = context.read<AuthProvider>().user;
      _ngos = (res['data'] as List)
          .map((e) => NGO.fromJson(e as Map<String, dynamic>))
          .where((n) => n.id != user?.ngo?.id)
          .toList();
      setState(() => _loadingNgos = false);
    } catch (_) {
      setState(() => _loadingNgos = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedNgoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a target NGO')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService.instance.post(
        ApiConstants.referrals,
        body: {
          'toNGO': _selectedNgoId,
          'caseTitle': _title.text.trim(),
          'caseCategory': _category,
          'details': _details.text.trim(),
          'contact': _contact.text.trim(),
          'urgency': _urgency,
        },
      );
      widget.onCreated();
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
    return SingleChildScrollView(
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
              'Refer a Case',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'All details encrypted with AES-256',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            if (_loadingNgos)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: LoadingIndicator(),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedNgoId,
                decoration: const InputDecoration(
                  labelText: 'Refer to NGO',
                  prefixIcon: Icon(Icons.apartment_outlined),
                ),
                items: _ngos
                    .map(
                      (n) => DropdownMenuItem(
                        value: n.id,
                        child: Text(n.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedNgoId = v),
              ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _title,
              label: 'Case title',
              hint: 'e.g. Urgent medical referral',
              prefixIcon: Icons.title,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            const Text(
              'Category',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                'medical',
                'legal',
                'shelter',
                'rehabilitation',
                'counselling',
                'financial',
                'other',
              ].map((c) {
                final selected = _category == c;
                return GestureDetector(
                  onTap: () => setState(() => _category = c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryLight
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const Text(
              'Urgency',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _urgencyChip('low', 'Low', AppColors.textMuted),
                const SizedBox(width: 6),
                _urgencyChip('medium', 'Medium', AppColors.warning),
                const SizedBox(width: 6),
                _urgencyChip('high', 'High', AppColors.secondary),
                const SizedBox(width: 6),
                _urgencyChip('critical', 'Critical', AppColors.danger),
              ],
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _details,
              label: 'Case details',
              hint: 'Encrypted on the server',
              prefixIcon: Icons.lock_outline,
              maxLines: 4,
              validator: (v) =>
                  v == null || v.length < 10 ? 'Min 10 characters' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _contact,
              label: 'Contact (optional, encrypted)',
              hint: 'Phone or alternate contact',
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'Send Referral',
              icon: Icons.send_outlined,
              loading: _saving,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _urgencyChip(String value, String label, Color color) {
    final selected = _urgency == value;
    return GestureDetector(
      onTap: () => setState(() => _urgency = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
