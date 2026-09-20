import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/location_search_field.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _city = TextEditingController();
  String _type = 'flag';
  String _flagCategory = 'medical';
  String _urgency = 'medium';
  LatLng _picked = const LatLng(33.6844, 73.0479);
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final res = await ApiService.instance.post(
        ApiConstants.mapPins,
        body: {
          'type': _type,
          'title': _title.text.trim(),
          'description': _description.text.trim(),
          'city': _city.text.trim(),
          'location': {'lat': _picked.latitude, 'lng': _picked.longitude},
          if (_type == 'flag') 'flagCategory': _flagCategory,
          if (_type == 'flag') 'urgencyLevel': _urgency,
        },
      );
      if (mounted) {
        final pinData = res['data'] as Map<String, dynamic>?;
        final isPending = pinData?['verificationStatus'] == 'pending';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPending
                ? 'Pin submitted — it will appear on the map once an NGO Admin reviews it.'
                : 'Pin created'),
            backgroundColor: isPending ? AppColors.warning : AppColors.success,
          ),
        );
        context.go('/map');
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
              onPressed: () => context.go('/map'),
            ),
            const Text(
              'Create Map Pin',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Pin Type',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      _typeChip('flag', 'Urgent Flag', Icons.flag,
                          AppColors.danger),
                      _typeChip('office', 'Office Location',
                          Icons.apartment, AppColors.primary),
                      _typeChip('project', 'Project Site',
                          Icons.work_outline, AppColors.accent),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _title,
                    label: 'Title',
                    hint: 'Brief title',
                    prefixIcon: Icons.title,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _description,
                    label: 'Description',
                    hint: 'What is needed / what is at this location',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  // ── Location Search ──────────────────
                  const Text('Search Location',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          fontSize: 13)),
                  const SizedBox(height: 6),
                  LocationSearchField(
                    onSelect: (result) {
                      setState(() {
                        _picked = LatLng(result.lat, result.lng);
                        _city.text = result.city.isNotEmpty
                            ? result.city
                            : result.address.split(',').first.trim();
                      });
                    },
                  ),
                  if (_city.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          const Icon(Icons.check_circle_outline,
                              color: AppColors.success, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            'City: ${_city.text} · GPS: ${_picked.latitude.toStringAsFixed(4)}, ${_picked.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                                color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
                          )),
                        ]),
                      ),
                    ),
                  if (_type == 'flag') ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Flag Category',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _flagChip('medical', 'Medical', Icons.medical_services_outlined),
                        _flagChip('legal', 'Legal', Icons.gavel_outlined),
                        _flagChip('food', 'Food', Icons.restaurant_outlined),
                        _flagChip('shelter', 'Shelter', Icons.house_outlined),
                        _flagChip('education', 'Education',
                            Icons.school_outlined),
                        _flagChip('other', 'Other', Icons.flag_outlined),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                        _urgencyChip(
                            'medium', 'Medium', AppColors.warning),
                        const SizedBox(width: 6),
                        _urgencyChip('high', 'High', AppColors.secondary),
                        const SizedBox(width: 6),
                        _urgencyChip(
                            'critical', 'Critical', AppColors.danger),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Text(
                    'Or tap directly on the map for exact location:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 320,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: _picked,
                        initialZoom: 6,
                        onTap: (_, p) => setState(() => _picked = p),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.humraah.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _picked,
                              width: 36,
                              height: 36,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _type == 'flag'
                                      ? AppColors.danger
                                      : AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  _type == 'flag'
                                      ? Icons.flag
                                      : Icons.location_on,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lat ${_picked.latitude.toStringAsFixed(4)}, Lng ${_picked.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 22),
                  AppButton(
                    label: 'Save Pin',
                    icon: Icons.save_outlined,
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

  Widget _typeChip(String value, String label, IconData icon, Color color) {
    final selected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _flagChip(String value, String label, IconData icon) {
    final selected = _flagCategory == value;
    return GestureDetector(
      onTap: () => setState(() => _flagCategory = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.dangerLight : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.danger : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? AppColors.danger : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.danger : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
