import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/empty_state.dart';
import 'ngo_detail_screen.dart';

class MyNGOScreen extends StatelessWidget {
  const MyNGOScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user?.ngo == null) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.apartment_outlined,
          title: 'No NGO associated',
          message: 'Register your NGO from your profile screen.',
          action: ElevatedButton.icon(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person_outline),
            label: const Text('Profile'),
          ),
        ),
      );
    }
    return NGODetailScreen(id: user!.ngo!.id);
  }
}
