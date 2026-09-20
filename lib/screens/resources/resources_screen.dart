import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/resource.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/cards/resource_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  List<ResourceItem> _items = [];
  bool _loading = true;
  String _category = '';
  String _language = '';
  String _search = '';
  final _searchCtrl = TextEditingController();

  static const _categories = [
    {'value': '', 'label': 'All', 'icon': Icons.apps},
    {'value': 'poster', 'label': 'Posters', 'icon': Icons.image_outlined},
    {'value': 'video', 'label': 'Videos', 'icon': Icons.play_circle_outline},
    {
      'value': 'research',
      'label': 'Research',
      'icon': Icons.menu_book_outlined
    },
    {'value': 'manual', 'label': 'Manuals', 'icon': Icons.description_outlined},
    {
      'value': 'infographic',
      'label': 'Infographics',
      'icon': Icons.bar_chart_outlined
    },
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.instance.get(
        ApiConstants.resources,
        query: {
          if (_category.isNotEmpty) 'category': _category,
          if (_language.isNotEmpty) 'language': _language,
          if (_search.isNotEmpty) 'search': _search,
          'limit': 60,
        },
      );
      final list = (res['data'] as List)
          .map((e) => ResourceItem.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _download(ResourceItem r) async {
    try {
      await ApiService.instance
          .post('${ApiConstants.resources}/${r.id}/download');
      final url = ApiConstants.fileUrl(r.fileUrl);
      if (url.isNotEmpty) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
      _load();
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final canUpload = user != null && (user.isNgoAdmin || user.isNgoStaff);
    return Scaffold(
      floatingActionButton: canUpload
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/resources/upload'),
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Upload'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Shared Knowledge Cupboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Multilingual posters, videos, research and training manuals',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search by title, description, tags...',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
              onSubmitted: (v) {
                _search = v;
                _load();
              },
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((c) {
                  final selected = _category == c['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _category = c['value'] as String);
                        _load();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color:
                              selected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                selected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              c['icon'] as IconData,
                              size: 14,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              c['label'] as String,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _langChip('All', ''),
                const SizedBox(width: 6),
                _langChip('English', 'English'),
                const SizedBox(width: 6),
                _langChip('Urdu', 'Urdu'),
                const SizedBox(width: 6),
                _langChip('Both', 'Both'),
              ],
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: LoadingIndicator(),
              )
            else if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'No resources yet',
                  message:
                      'Be the first to upload a resource for the community.',
                ),
              )
            else
              LayoutBuilder(
                builder: (context, c) {
                  final cols = c.maxWidth >= 1200
                      ? 4
                      : c.maxWidth >= 900
                          ? 3
                          : c.maxWidth >= 600
                              ? 2
                              : 1;
                  if (cols == 1) {
                    return Column(
                      children: _items
                          .map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ResourceCard(
                                resource: r,
                                onDownload: () => _download(r),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 320,
                      mainAxisExtent: 240,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                    ),
                    itemBuilder: (_, i) => ResourceCard(
                      resource: _items[i],
                      onDownload: () => _download(_items[i]),
                    ),
                  );
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _langChip(String label, String value) {
    final selected = _language == value;
    return GestureDetector(
      onTap: () {
        setState(() => _language = value);
        _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentLight : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.accent : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
