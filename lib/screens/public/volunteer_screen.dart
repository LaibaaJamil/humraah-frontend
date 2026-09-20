import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/ngo.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/loading_indicator.dart';

class VolunteerScreen extends StatefulWidget {
  const VolunteerScreen({super.key});

  @override
  State<VolunteerScreen> createState() => _VolunteerScreenState();
}

class _VolunteerScreenState extends State<VolunteerScreen> {
  List<NGO> _ngos = [];
  List<Map<String, dynamic>> _myRequests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ApiService.instance;
      final results = await Future.wait([
        api.get(ApiConstants.ngos, query: {'status': 'verified'}),
        api.get(ApiConstants.myVolunteerRequests),
      ]);
      final ngos = ((results[0]['data'] as List?) ?? [])
          .map((e) => NGO.fromJson(e as Map<String, dynamic>))
          .where((n) => n.isVerified)
          .toList();
      final reqs = ((results[1]['data'] as List?) ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      setState(() {
        _ngos = ngos;
        _myRequests = reqs;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingIndicator(label: 'Loading NGOs...');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/dashboard'),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Volunteer with an NGO',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Offer your time or skills to a verified nonprofit working in your area.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 20),
          if (_myRequests.isNotEmpty) ...[
            const Text(
              'Your requests',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ..._myRequests.map(_buildRequest),
            const SizedBox(height: 24),
          ],
          const Text(
            'Verified NGOs',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap "Volunteer" to send a request.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          if (_ngos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No verified NGOs available right now.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 1000
                    ? 3
                    : c.maxWidth >= 700
                        ? 2
                        : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _ngos.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    mainAxisExtent: 220,
                  ),
                  itemBuilder: (_, i) => _NGOTile(
                    ngo: _ngos[i],
                    onVolunteer: () => _showRequestSheet(_ngos[i]),
                    onView: () => context.go('/ngos/${_ngos[i].id}'),
                  ),
                );
              },
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRequest(Map<String, dynamic> r) {
    final ngo = (r['ngo'] as Map?) ?? {};
    final status = (r['status'] ?? 'pending').toString();
    final created = DateTime.tryParse(r['createdAt']?.toString() ?? '');
    Color color;
    switch (status) {
      case 'accepted':
        color = AppColors.success;
        break;
      case 'declined':
        color = AppColors.danger;
        break;
      default:
        color = AppColors.warning;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.apartment_outlined,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (ngo['name'] ?? 'NGO').toString(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                if (created != null)
                  Text(
                    'Sent ${DateFormat('MMM d, y').format(created)}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestSheet(NGO ngo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: _RequestForm(
            ngo: ngo,
            onSent: () {
              Navigator.pop(context);
              _load();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Volunteer request sent successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NGOTile extends StatelessWidget {
  final NGO ngo;
  final VoidCallback onVolunteer;
  final VoidCallback onView;
  const _NGOTile({
    required this.ngo,
    required this.onVolunteer,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.apartment_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ngo.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ngo.description.isEmpty
                ? '${ngo.city.isNotEmpty ? ngo.city : 'Pakistan'} · ${ngo.sectors.join(", ")}'
                : ngo.description,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.info_outline, size: 14),
                  label: const Text('Details'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onVolunteer,
                  icon: const Icon(Icons.handshake_outlined, size: 14),
                  label: const Text('Volunteer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestForm extends StatefulWidget {
  final NGO ngo;
  final VoidCallback onSent;
  const _RequestForm({required this.ngo, required this.onSent});

  @override
  State<_RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends State<_RequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();
  final _skills = TextEditingController();
  final _availability = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _message.dispose();
    _skills.dispose();
    _availability.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiService.instance.post(
        ApiConstants.volunteers,
        body: {
          'ngo': widget.ngo.id,
          'message': _message.text.trim(),
          'skills': _skills.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
          'availability': _availability.text.trim(),
          'contactPhone': _phone.text.trim(),
        },
      );
      widget.onSent();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.danger),
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
            Text(
              'Volunteer with ${widget.ngo.name}',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _message,
              label: 'Why you want to help',
              hint: 'Briefly introduce yourself and what motivates you',
              prefixIcon: Icons.message_outlined,
              maxLines: 4,
              validator: (v) =>
                  v == null || v.trim().length < 15 ? 'Min 15 characters' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _skills,
              label: 'Skills (comma-separated)',
              hint: 'e.g. teaching, first aid, translation',
              prefixIcon: Icons.stars_outlined,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _availability,
              label: 'Availability',
              hint: 'e.g. Weekends, evenings, full-time',
              prefixIcon: Icons.access_time_outlined,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _phone,
              label: 'Contact phone',
              hint: '03001234567',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Send Request',
              icon: Icons.send_outlined,
              color: AppColors.accent,
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
