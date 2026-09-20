import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class UploadResourceScreen extends StatefulWidget {
  const UploadResourceScreen({super.key});

  @override
  State<UploadResourceScreen> createState() => _UploadResourceScreenState();
}

class _UploadResourceScreenState extends State<UploadResourceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _tags = TextEditingController();
  final _sector = TextEditingController(text: 'general');
  String _category = 'poster';
  String _language = 'English';
  String _visibility = 'public';
  PlatformFile? _file;
  bool _uploading = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _tags.dispose();
    _sector.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() => _file = res.files.first);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_file == null || _file!.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a file')),
      );
      return;
    }
    setState(() => _uploading = true);
    try {
      await ApiService.instance.uploadFile(
        ApiConstants.resources,
        fieldName: 'file',
        bytes: _file!.bytes!,
        filename: _file!.name,
        fields: {
          'title': _title.text.trim(),
          'description': _description.text.trim(),
          'category': _category,
          'language': _language,
          'sector': _sector.text.trim(),
          'visibility': _visibility,
          'tags': _tags.text.trim(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resource uploaded'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/resources');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
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
              onPressed: () => context.go('/resources'),
            ),
            const SizedBox(width: 4),
            const Text(
              'Upload Resource',
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
                    label: 'Title',
                    hint: 'e.g. Child protection awareness poster',
                    prefixIcon: Icons.title,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _description,
                    label: 'Description',
                    hint: 'Brief description of the resource',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _catChip('poster', 'Poster', Icons.image_outlined),
                      _catChip('video', 'Video', Icons.play_circle_outline),
                      _catChip(
                          'research', 'Research', Icons.menu_book_outlined),
                      _catChip('manual', 'Manual', Icons.description_outlined),
                      _catChip('infographic', 'Infographic',
                          Icons.bar_chart_outlined),
                      _catChip(
                          'other', 'Other', Icons.insert_drive_file_outlined),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Language',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      _langChip('English'),
                      _langChip('Urdu'),
                      _langChip('Both'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _sector,
                    label: 'Sector',
                    hint: 'e.g. child_protection, education, medical',
                    prefixIcon: Icons.category_outlined,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _tags,
                    label: 'Tags (comma separated)',
                    hint: 'urdu, awareness, children',
                    prefixIcon: Icons.tag,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Visibility',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      _visibilityChip('public'),
                      _visibilityChip('private'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  InkWell(
                    onTap: _pickFile,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _file != null
                              ? AppColors.primary
                              : AppColors.border,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _file != null
                                ? Icons.check_circle_outline
                                : Icons.cloud_upload_outlined,
                            size: 32,
                            color: _file != null
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _file != null
                                ? _file!.name
                                : 'Click to choose file',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _file != null
                                ? '${(_file!.size / 1024 / 1024).toStringAsFixed(2)} MB'
                                : 'PDF, image, video or document (max 25 MB)',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Upload Resource',
                    icon: Icons.cloud_upload_outlined,
                    loading: _uploading,
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

  Widget _catChip(String value, String label, IconData icon) {
    final selected = _category == value;
    return GestureDetector(
      onTap: () => setState(() => _category = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _langChip(String value) {
    final selected = _language == value;
    return GestureDetector(
      onTap: () => setState(() => _language = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentLight : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: selected ? AppColors.accent : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _visibilityChip(String value) {
    final selected = _visibility == value;

    return GestureDetector(
      onTap: () => setState(() => _visibility = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          value.toUpperCase(),
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
