import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class CreateTenderScreen extends StatefulWidget {
  const CreateTenderScreen({super.key});

  @override
  State<CreateTenderScreen> createState() => _CreateTenderScreenState();
}

class _CreateTenderScreenState extends State<CreateTenderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _budget = TextEditingController();
  final _eligibility = TextEditingController();
  final _location = TextEditingController(text: 'Pakistan');
  final _sector = TextEditingController(text: 'general');
  final _donor = TextEditingController();
  bool _allowCoalitions = true;
  int _maxPartners = 5;
  DateTime _deadline = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _budget.dispose();
    _eligibility.dispose();
    _location.dispose();
    _sector.dispose();
    _donor.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (p != null) setState(() => _deadline = p);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiService.instance.post(
        ApiConstants.tenders,
        body: {
          'title': _title.text.trim(),
          'description': _description.text.trim(),
          'sector': _sector.text.trim(),
          'budgetAmount': num.tryParse(_budget.text) ?? 0,
          'currency': 'PKR',
          'deadline': _deadline.toIso8601String(),
          'eligibility': _eligibility.text.trim(),
          'location': _location.text.trim(),
          'allowCoalitions': _allowCoalitions,
          'maxCoalitionPartners': _maxPartners,
          'donorOrganization': _donor.text.trim(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tender posted'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/tenders');
      }
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
    final user = context.watch<AuthProvider>().user;
    // Guard: only large donor organizations can post tenders
    if (user == null || !user.isDonor || !user.isLargeOrg) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.warningLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outlined, color: AppColors.warning, size: 40),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Restricted Access',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Only large verified donor organizations (e.g. UNICEF, WFP, UN agencies) can post tenders.\n\nNGOs and other organizations should browse and bid on existing tenders.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () => context.go('/tenders'),
                  icon: const Icon(Icons.list_alt_outlined, size: 16),
                  label: const Text('Browse Tenders'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/tenders'),
            ),
            const Text(
              'Post New Tender',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _title,
                    label: 'Tender title',
                    hint: 'e.g. Education Sector Awareness Grant',
                    prefixIcon: Icons.title,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _description,
                    label: 'Description',
                    hint: 'Scope and objectives',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 4,
                    validator: (v) =>
                        v == null || v.length < 30 ? 'Add more detail' : null,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _budget,
                    label: 'Budget (PKR)',
                    hint: 'e.g. 5000000',
                    prefixIcon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        num.tryParse(v ?? '') == null ? 'Enter a number' : null,
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickDeadline,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 18, color: AppColors.textMuted),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Deadline',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${_deadline.day}/${_deadline.month}/${_deadline.year}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.edit_outlined, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _location,
                    label: 'Location',
                    hint: 'e.g. Punjab, Sindh, Pakistan',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _sector,
                    label: 'Sector',
                    hint: 'e.g. education, child_protection',
                    prefixIcon: Icons.category_outlined,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _donor,
                    label: 'Donor organization',
                    hint: 'e.g. UNICEF Pakistan',
                    prefixIcon: Icons.business_outlined,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _eligibility,
                    label: 'Eligibility (optional)',
                    hint: 'Who can apply',
                    prefixIcon: Icons.checklist_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _allowCoalitions,
                          onChanged: (v) =>
                              setState(() => _allowCoalitions = v),
                          activeThumbColor: AppColors.primary,
                          title: const Text('Allow coalitions'),
                          subtitle: const Text(
                            'NGOs can join forces and apply together',
                          ),
                        ),
                        if (_allowCoalitions) ...[
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Max partners:'),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Slider(
                                  value: _maxPartners.toDouble(),
                                  min: 2,
                                  max: 10,
                                  divisions: 8,
                                  label: '$_maxPartners',
                                  onChanged: (v) =>
                                      setState(() => _maxPartners = v.toInt()),
                                ),
                              ),
                              Text(
                                '$_maxPartners',
                                style:
                                    const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  AppButton(
                    label: 'Post Tender',
                    icon: Icons.publish_outlined,
                    color: AppColors.secondary,
                    loading: _saving,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
