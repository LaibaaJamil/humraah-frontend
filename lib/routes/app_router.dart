import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home_shell.dart';
import '../screens/splash_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/ngo/ngo_directory_screen.dart';
import '../screens/ngo/ngo_detail_screen.dart';
import '../screens/ngo/my_ngo_screen.dart';
import '../screens/resources/resources_screen.dart';
import '../screens/resources/upload_resource_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/map/create_pin_screen.dart';
import '../screens/tendering/tenders_screen.dart';
import '../screens/tendering/tender_detail_screen.dart';
import '../screens/tendering/create_tender_screen.dart';
import '../screens/tendering/my_applications_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/reports/submit_report_screen.dart';
import '../screens/referral/referrals_screen.dart';
import '../screens/admin/admin_panel_screen.dart';
import '../screens/admin/admin_pending_screen.dart';
import '../screens/admin/donor_management_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/public/report_issue_screen.dart';
import '../screens/public/volunteer_screen.dart';
import '../screens/volunteer/volunteer_requests_screen.dart';
import '../screens/public/report_success_screen.dart';

class AppRouter {
  static GoRouter create(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggedIn = auth.isAuthenticated;
        final loc = state.matchedLocation;
        final isAuthScreen = loc == '/login' || loc == '/register';
        if (loc == '/') return null;
        if (!loggedIn && !isAuthScreen) return '/login';
        if (loggedIn && isAuthScreen) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

        ShellRoute(
          builder: (context, state, child) => HomeShell(child: child),
          routes: [
            GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
            GoRoute(path: '/ngos', builder: (_, __) => const NGODirectoryScreen()),
            GoRoute(
              path: '/ngos/:id',
              builder: (_, state) =>
                  NGODetailScreen(id: state.pathParameters['id']!),
            ),
            GoRoute(path: '/my-ngo', builder: (_, __) => const MyNGOScreen()),
            GoRoute(path: '/resources', builder: (_, __) => const ResourcesScreen()),
            GoRoute(
              path: '/resources/upload',
              builder: (_, __) => const UploadResourceScreen(),
            ),
            GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
            GoRoute(
              path: '/map/new',
              builder: (_, __) => const CreatePinScreen(),
            ),
            GoRoute(path: '/tenders', builder: (_, __) => const TendersScreen()),
            GoRoute(
              path: '/tenders/new',
              builder: (_, __) => const CreateTenderScreen(),
            ),
            GoRoute(
              path: '/tenders/applications',
              builder: (_, __) => const MyApplicationsScreen(),
            ),
            GoRoute(
              path: '/tenders/:id',
              builder: (_, state) =>
                  TenderDetailScreen(id: state.pathParameters['id']!),
            ),
            GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
            GoRoute(
              path: '/reports/new',
              builder: (_, __) => const SubmitReportScreen(),
            ),
            GoRoute(path: '/referrals', builder: (_, __) => const ReferralsScreen()),
            GoRoute(path: '/admin', builder: (_, __) => const AdminPanelScreen()),
            GoRoute(
              path: '/admin/pending',
              builder: (_, __) => const AdminPendingScreen(),
            ),
            GoRoute(
              path: '/admin/donors',
              builder: (_, __) => const DonorManagementScreen(),
            ),
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
            GoRoute(
              path: '/notifications',
              builder: (_, __) => const NotificationsScreen(),
            ),
            GoRoute(
              path: '/report-issue',
              builder: (_, __) => const ReportIssueScreen(),
            ),
            GoRoute(
              path: '/volunteer',
              builder: (_, __) => const VolunteerScreen(),
            ),
            GoRoute(
              path: '/volunteers/requests',
              builder: (_, __) => const VolunteerRequestsScreen(),
            ),
            GoRoute(
              path: '/report-success',
              builder: (_, __) => const ReportSuccessScreen(),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text('Page not found: ${state.matchedLocation}'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Back to dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
