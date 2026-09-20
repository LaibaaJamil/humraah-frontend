import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/ngo.dart';
import '../../widgets/cards/ngo_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';

class NGODirectoryScreen extends StatefulWidget {
  const NGODirectoryScreen({super.key});

  @override
  State<NGODirectoryScreen> createState() => _NGODirectoryScreenState();
}

class _NGODirectoryScreenState extends State<NGODirectoryScreen> {
  List<NGO> _ngos = [];
  bool _loading = true;
  String _search = '';
  String _statusFilter = 'verified';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.instance.get(
        ApiConstants.ngos,
        query: {
          if (_statusFilter.isNotEmpty) 'status': _statusFilter,
          if (_search.isNotEmpty) 'search': _search,
          'limit': 50,
        },
      );
      final list = (res['data'] as List)
          .map((e) => NGO.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _ngos = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'NGO Directory',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Verified high-trust network of nonprofits across Pakistan',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search NGOs by name, sector, city...',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                  onSubmitted: (v) {
                    setState(() => _search = v);
                    _load();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', ''),
                const SizedBox(width: 8),
                _filterChip('Verified', 'verified'),
                const SizedBox(width: 8),
                _filterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _filterChip('Rejected', 'rejected'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: LoadingIndicator(),
            )
          else if (_ngos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: EmptyState(
                icon: Icons.apartment_outlined,
                title: 'No NGOs found',
                message: 'Try adjusting your filters or search query.',
              ),
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 1100
                    ? 3
                    : c.maxWidth >= 700
                        ? 2
                        : 1;
                if (cols == 1) {
                  return Column(
                    children: _ngos
                        .map(
                          (ngo) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: NGOCard(
                              ngo: ngo,
                              onTap: () => context.go('/ngos/${ngo.id}'),
                            ),
                          ),
                        )
                        .toList(),
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _ngos.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 420,
                    mainAxisExtent: 240,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                  ),
                  itemBuilder: (_, i) => NGOCard(
                    ngo: _ngos[i],
                    onTap: () => context.go('/ngos/${_ngos[i].id}'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String status) {
    final selected = _statusFilter == status;
    return GestureDetector(
      onTap: () {
        setState(() => _statusFilter = status);
        _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
