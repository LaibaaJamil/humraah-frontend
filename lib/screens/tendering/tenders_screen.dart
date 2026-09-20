import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/tender.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/cards/tender_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';

class TendersScreen extends StatefulWidget {
  const TendersScreen({super.key});

  @override
  State<TendersScreen> createState() => _TendersScreenState();
}

class _TendersScreenState extends State<TendersScreen> {
  List<Tender> _tenders = [];
  bool _loading = true;
  String _statusFilter = 'open';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.instance.get(
        ApiConstants.tenders,
        query: {if (_statusFilter.isNotEmpty) 'status': _statusFilter},
      );
      final list = (res['data'] as List)
          .map((e) => Tender.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _tenders = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final canPost = user != null && user.isDonor;
    final canApply = user != null && (user.isNgoAdmin || user.isNgoStaff);

    return Scaffold(
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/tenders/new'),
              icon: const Icon(Icons.post_add_outlined),
              label: const Text('Post Tender'),
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Funding & Tendering',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Browse grant calls. Apply alone or build coalitions.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (canApply)
                  TextButton.icon(
                    onPressed: () => context.go('/tenders/applications'),
                    icon: const Icon(Icons.list_alt_outlined),
                    label: const Text('My Applications'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _statusChip('All', ''),
                  const SizedBox(width: 8),
                  _statusChip('Open', 'open'),
                  const SizedBox(width: 8),
                  _statusChip('Closed', 'closed'),
                  const SizedBox(width: 8),
                  _statusChip('Awarded', 'awarded'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: LoadingIndicator(),
              )
            else if (_tenders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No tenders found',
                  message: 'Try changing the filter or check back soon.',
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
                      children: _tenders
                          .map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: TenderCard(
                                tender: t,
                                onTap: () => context.go('/tenders/${t.id}'),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _tenders.length,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 380,
                      mainAxisExtent: 290,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                    ),
                    itemBuilder: (_, i) => TenderCard(
                      tender: _tenders[i],
                      onTap: () => context.go('/tenders/${_tenders[i].id}'),
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

  Widget _statusChip(String label, String value) {
    final selected = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _statusFilter = value);
        _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
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
