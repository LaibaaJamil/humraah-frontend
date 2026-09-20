import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/services/api_service.dart';
import '../models/notification.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _items = [];
  int _unreadCount = 0;
  Timer? _pollTimer;

  List<AppNotification> get items => _items;
  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;

  void startPolling() {
    _pollTimer?.cancel();
    _load(); // immediate
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.instance.get(ApiConstants.notifications);
      _items = ((res['data'] as List?) ?? [])
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      _unreadCount = (res['unread'] as num?)?.toInt() ?? _items.where((n) => !n.isRead).length;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markRead(String id) async {
    try {
      await ApiService.instance.put('${ApiConstants.notifications}/$id/read');
      final idx = _items.indexWhere((n) => n.id == id);
      if (idx >= 0 && !_items[idx].isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
      }
      await _load();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await ApiService.instance.put('${ApiConstants.notifications}/read-all');
      _unreadCount = 0;
      await _load();
    } catch (_) {}
  }

  void reset() {
    _items = [];
    _unreadCount = 0;
    stopPolling();
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
