import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class SubmitReportScreen extends StatefulWidget {
  const SubmitReportScreen({super.key});

  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen> {
  final _formKey = GlobalKey<FormState>();
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  final _sector = TextEditingController(text: 'general');
  final _beneficiaries = TextEditingController();
  final _events = TextEditingController();
  final _resources = TextEditingController();
  final _volunteers = TextEditingController();
  final _funds = TextEditingController();
  final _women = TextEditingController();
  final _men = TextEditingController();
  final _children = TextEditingController();
  final _summary = TextEditingController();
  final _locations = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _sector.dispose();
    _beneficiaries.dispose();
    _events.dispose();
    _resources.dispose();
    _volunteers.dispose();
    _funds.dispose();
    _women.dispose();
    _men.dispose();
    _children.dispose();
    _summary.dispose();
    _locations.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiService.instance.post(
        ApiConstants.reports,
        body: {
          'period': {'month': _month, 'year': _year},
          'sector': _sector.text.trim(),
          'metrics': {
            'beneficiariesReached': int.tryParse(_beneficiaries.text) ?? 0,
            'eventsConducted': int.tryParse(_events.text) ?? 0,
            'resourcesDistributed': int.tryParse(_resources.text) ?? 0,
            'volunteersEngaged': int.tryParse(_volunteers.text) ?? 0,
            'fundsUtilized': num.tryParse(_funds.text) ?? 0,
          },
          'breakdown': {
            'women': int.tryParse(_women.text) ?? 0,
            'men': int.tryParse(_men.text) ?? 0,
            'children': int.tryParse(_children.text) ?? 0,
          },
          'summary': _summary.text.trim(),
          'locations': _locations.text.isEmpty
              ? []
              : _locations.text.split(',').map((s) => s.trim()).toList(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/reports');
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/reports'),
            ),
            const Text(
              'Submit Monthly Report',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _month,
                            decoration: const InputDecoration(
                              labelText: 'Month',
                              prefixIcon: Icon(Icons.calendar_month_outlined),
                            ),
                            items: List.generate(12, (i) => i + 1)
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(_monthName(m)),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _month = v ?? _month),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _year,
                            decoration: const InputDecoration(
                              labelText: 'Year',
                              prefixIcon: Icon(Icons.event_outlined),
                            ),
                            items: [2024, 2025, 2026, 2027]
                                .map(
                                  (y) => DropdownMenuItem(
                                    value: y,
                                    child: Text('$y'),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _year = v ?? _year),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _sector,
                    label: 'Sector',
                    prefixIcon: Icons.category_outlined,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Activity Metrics',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _beneficiaries,
                          label: 'Beneficiaries reached',
                          hint: '0',
                          prefixIcon: Icons.people_alt_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppTextField(
                          controller: _events,
                          label: 'Events conducted',
                          hint: '0',
                          prefixIcon: Icons.event_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _resources,
                          label: 'Resources distributed',
                          hint: '0',
                          prefixIcon: Icons.inventory_2_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppTextField(
                          controller: _volunteers,
                          label: 'Volunteers engaged',
                          hint: '0',
                          prefixIcon: Icons.volunteer_activism_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _funds,
                    label: 'Funds utilized (PKR)',
                    hint: '0',
                    prefixIcon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Demographic Breakdown',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _women,
                          label: 'Women',
                          hint: '0',
                          prefixIcon: Icons.female_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppTextField(
                          controller: _men,
                          label: 'Men',
                          hint: '0',
                          prefixIcon: Icons.male_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppTextField(
                          controller: _children,
                          label: 'Children',
                          hint: '0',
                          prefixIcon: Icons.child_care_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    controller: _locations,
                    label: 'Locations (comma separated)',
                    hint: 'Islamabad, Lahore, Karachi',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _summary,
                    label: 'Summary',
                    hint: 'Highlights and challenges from this month',
                    prefixIcon: Icons.short_text,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 22),
                  AppButton(
                    label: 'Submit Report',
                    icon: Icons.upload_outlined,
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

  String _monthName(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}
