import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/notification.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/common/empty_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _typeLabel(String t) {
    switch (t) {
      case 'flag':      return 'Flag';
      case 'tender':    return 'Tender';
      case 'referral':  return 'Referral';
      case 'success':   return 'Update';
      case 'warning':   return 'Alert';
      case 'volunteer': return 'Volunteer';
      default:          return 'Info';
    }
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'flag':      return Icons.flag_outlined;
      case 'tender':    return Icons.account_balance_wallet_outlined;
      case 'referral':  return Icons.swap_horiz_outlined;
      case 'success':   return Icons.check_circle_outline;
      case 'warning':   return Icons.warning_amber_outlined;
      case 'volunteer': return Icons.handshake_outlined;
      default:          return Icons.notifications_outlined;
    }
  }

  Color _typeColor(String t) {
    switch (t) {
      case 'flag':      return AppColors.danger;
      case 'tender':    return AppColors.accent;
      case 'referral':  return AppColors.primary;
      case 'success':   return AppColors.success;
      case 'warning':   return AppColors.warning;
      case 'volunteer': return AppColors.secondary;
      default:          return AppColors.textSecondary;
    }
  }

  void _handleTap(BuildContext context, AppNotification n) async {
    // Mark as read
    await context.read<NotificationProvider>().markRead(n.id);
    if (!context.mounted) return;

    // Navigate: prefer actionUrl, fallback by relatedModel, fallback by type
    final url = n.actionUrl ?? '';
    if (url.isNotEmpty) { context.go(url); return; }

    final model = (n.relatedModel ?? '').toLowerCase();
    switch (model) {
      case 'volunteerrequest': context.go('/volunteers/requests'); break;
      case 'referral':         context.go('/referrals');           break;
      case 'report':           context.go('/reports');             break;
      case 'citizenreport':    context.go('/admin/pending');       break;
      case 'ngo':              context.go('/admin/pending');       break;
      case 'mappin':           context.go('/map');                 break;
      case 'tender':           context.go('/tenders');             break;
      default:
        // Fallback by notification type
        switch (n.type) {
          case 'volunteer': context.go('/volunteers/requests'); break;
          case 'referral':  context.go('/referrals');           break;
          case 'tender':    context.go('/tenders');             break;
          case 'flag':      context.go('/admin/pending');       break;
          default:          context.go('/dashboard');
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final items = provider.items;
    final unread = provider.unreadCount;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => provider.startPolling(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/dashboard'),
              ),
              const Expanded(
                child: Text('Notifications',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ),
              if (unread > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$unread unread',
                      style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => provider.markAllRead(),
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text('Mark all read'),
                ),
              ],
            ]),
            const SizedBox(height: 12),

            if (provider.items.isEmpty && !provider.hasUnread)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: EmptyState(
                  icon: Icons.notifications_none_outlined,
                  title: 'No notifications',
                  message: 'Updates and alerts will appear here.',
                ),
              )
            else
              ...items.map((n) => _NotifCard(
                    notification: n,
                    typeIcon: _typeIcon(n.type),
                    typeColor: _typeColor(n.type),
                    typeLabel: _typeLabel(n.type),
                    onTap: () => _handleTap(context, n),
                  )),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotification notification;
  final IconData typeIcon;
  final Color typeColor;
  final String typeLabel;
  final VoidCallback onTap;

  const _NotifCard({
    required this.notification,
    required this.typeIcon,
    required this.typeColor,
    required this.typeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final hasAction = (n.actionUrl ?? '').isNotEmpty ||
        (n.relatedModel ?? '').isNotEmpty ||
        n.type != 'info';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.isRead ? AppColors.surface : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: n.isRead ? AppColors.border : AppColors.primary),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(typeIcon, size: 18, color: typeColor),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(n.title,
                          style: TextStyle(
                              fontWeight: n.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              fontSize: 14)),
                    ),
                    // Unread dot
                    if (!n.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ]),
                  const SizedBox(height: 3),
                  Text(n.message,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4)),
                  const SizedBox(height: 6),
                  Row(children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(typeLabel,
                          style: TextStyle(
                              color: typeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    if (n.createdAt != null)
                      Text(
                        DateFormat('MMM d, h:mm a').format(n.createdAt!),
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                  ]),
                  if (hasAction && !n.isRead) ...[
                    const SizedBox(height: 6),
                    const Text('Tap to view →',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
