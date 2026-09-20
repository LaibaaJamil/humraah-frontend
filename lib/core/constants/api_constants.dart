import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://humraah-backend-u736.onrender.com';
    } else {
      return 'https://humraah-backend-u736.onrender.com';
    }
  }

  static String get apiBase => '$baseUrl/api';

  // AUTH
  static String get register => '/auth/register';
  static String get login => '/auth/login';
  static String get me => '/auth/me';
  static String get profile => '/auth/profile';
  static String get changePassword => '/auth/change-password';

  // NGOs
  static String get ngos => '/ngos';
  static String get myNGO => '/ngos/me/details';

  // Resources
  static String get resources => '/resources';
  static String get resourceStats => '/resources/stats/overview';

  // Map
  static String get mapPins => '/map';
  static String get mapPinsPending => '/map/pending';
  static String get mapHeatmap => '/map/heatmap';

  // Tenders
  static String get tenders => '/tenders';
  static String get myApplications => '/tenders/applications/me';

  // Reports (NGO impact reports)
  static String get reports => '/reports';
  static String get myReports => '/reports/me';
  static String get reportAnalytics => '/reports/analytics';
  static String get nationalImpact => '/reports/national-impact';

  // Citizen Reports (RETIRED — issue reports now go through /map as type=flag.
  // Kept only so old references don't fail to compile; do not call this endpoint.)
  static String get citizenReports => '/citizen-reports';

  // Referrals
  static String get referrals => '/referrals';
  static String get incomingReferrals => '/referrals/incoming';
  static String get outgoingReferrals => '/referrals/outgoing';

  // Notifications
  static String get notifications => '/notifications';

  // Admin
  static String get adminDashboard => '/admin/dashboard';
  static String get adminUsers => '/admin/users';
  static String get adminPending => '/admin/verifications/pending';
  static String get adminMarkDonor => '/admin/users';
  static String get adminChangeRole => '/admin/users';
  static String get adminAssignNgo => '/admin/users';

  // Volunteers
  static String get volunteers => '/volunteers';
  static String get volunteerMine => '/volunteers/me';
  static String get volunteerForNgo => '/volunteers/ngo';
  static String get myVolunteerRequests => '/volunteers/me';
  static String get ngoVolunteerRequests => '/volunteers/ngo';

  // FILE HANDLING (safe)
  static String fileUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }
}
