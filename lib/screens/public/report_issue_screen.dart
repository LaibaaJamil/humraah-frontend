import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/location_search_field.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});
  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();

  double _lat = 30.3753;
  double _lng = 69.3451;
  bool _locationSelected = false;

  String _category = 'medical';
  String _urgency = 'high';
  bool _saving = false;
  String? _selectedImage;
  String? _selectedImageName;
  final ImagePicker _picker = ImagePicker();

  static const _categories = [
    ('medical',   'Medical',   Icons.local_hospital_outlined),
    ('legal',     'Legal Aid', Icons.gavel_outlined),
    ('food',      'Food',      Icons.restaurant_outlined),
    ('shelter',   'Shelter',   Icons.home_outlined),
    ('education', 'Education', Icons.school_outlined),
    ('other',     'Other',     Icons.help_outline),
  ];

  static const _urgencyLevels = [
    ('low',      'Low',      AppColors.textMuted),
    ('medium',   'Medium',   AppColors.warning),
    ('high',     'High',     AppColors.secondary),
    ('critical', 'Critical', AppColors.danger),
  ];

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _selectedImage = base64Encode(bytes);
      _selectedImageName = file.name;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _city.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_locationSelected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please search and select a location'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please upload at least 1 photo as evidence'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService.instance.post(ApiConstants.mapPins, body: {
        'type': 'flag',
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'city': _city.text.trim(),
        'address': _address.text.trim(),
        'flagCategory': _category,
        'urgencyLevel': _urgency,
        'images': [_selectedImage],
        'location': {'lat': _lat, 'lng': _lng},
      });
      if (!mounted) return;
      context.go('/report-success');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
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
        Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/dashboard')),
          const SizedBox(width: 4),
          const Expanded(child: Text('Report an Issue',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
        ]),
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 4, 20),
          child: Text(
            'Flag a local issue that needs NGO attention. Your report goes to verified staff for review.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Category ──────────────────────────────
              const _Label('Issue Category'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _categories.map((c) => _chip(
                  label: c.$2, icon: c.$3,
                  selected: _category == c.$1,
                  onTap: () => setState(() => _category = c.$1),
                )).toList(),
              ),
              const SizedBox(height: 20),

              // ── Urgency ───────────────────────────────
              const _Label('Urgency Level'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _urgencyLevels.map((u) => _chip(
                  label: u.$2, color: u.$3,
                  selected: _urgency == u.$1,
                  onTap: () => setState(() => _urgency = u.$1),
                )).toList(),
              ),
              const SizedBox(height: 20),

              // ── Title ─────────────────────────────────
              AppTextField(
                controller: _title,
                label: 'Short Title',
                hint: 'e.g. Family needs emergency medicines',
                prefixIcon: Icons.title,
                validator: (v) => v == null || v.trim().length < 5 ? 'Min 5 characters' : null,
              ),
              const SizedBox(height: 14),

              // ── Description ───────────────────────────
              AppTextField(
                controller: _description,
                label: 'Details',
                hint: 'Explain what is happening, who is affected and what help is needed',
                prefixIcon: Icons.notes_outlined,
                maxLines: 4,
                validator: (v) => v == null || v.trim().length < 15 ? 'Min 15 characters' : null,
              ),
              const SizedBox(height: 20),

              // ── Location Search ───────────────────────
              const _Label('Location'),
              const SizedBox(height: 8),
              LocationSearchField(
                onSelect: (result) {
                  setState(() {
                    _lat = result.lat;
                    _lng = result.lng;
                    _city.text = result.city.isNotEmpty ? result.city : result.address.split(',').first.trim();
                    _address.text = result.address;
                    _locationSelected = true;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Show selected coordinates
              if (_locationSelected)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('City: ${_city.text}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('GPS: ${_lat.toStringAsFixed(5)}, ${_lng.toStringAsFixed(5)}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                    ])),
                  ]),
                ),
              const SizedBox(height: 14),

              // ── Image Upload ──────────────────────────
              const _Label('Evidence Photo (Required)'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedImage != null
                        ? AppColors.successLight
                        : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedImage != null ? AppColors.success : AppColors.border,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(
                      _selectedImage != null
                          ? Icons.check_circle_outline
                          : Icons.camera_alt_outlined,
                      color: _selectedImage != null ? AppColors.success : AppColors.textMuted,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Flexible(child: Text(
                      _selectedImage != null
                          ? '✓ Photo selected${_selectedImageName != null ? ': $_selectedImageName' : ''}'
                          : 'Tap to upload a photo of the issue',
                      style: TextStyle(
                        color: _selectedImage != null ? AppColors.success : AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    )),
                  ]),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Clear, relevant photos help NGOs verify and respond faster.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
              ),
              const SizedBox(height: 24),

              // ── Submit ────────────────────────────────
              AppButton(
                label: 'Submit Report',
                icon: Icons.send_outlined,
                color: AppColors.danger,
                loading: _saving,
                onPressed: _submit,
              ),
            ]),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _chip({required String label, IconData? icon, Color? color, required bool selected, required VoidCallback onTap}) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? c : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? c : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
          ],
          Text(label, style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600, fontSize: 12.5,
          )),
        ]),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(
      fontWeight: FontWeight.w700, fontSize: 12,
      color: AppColors.textSecondary, letterSpacing: 0.4,
    ));
  }
}
