class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? createdAt;
  final String? actionUrl;
  final String? relatedModel;
  final String? relatedEntity;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    this.createdAt,
    this.actionUrl,
    this.relatedModel,
    this.relatedEntity,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: (json['_id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        message: (json['message'] ?? '').toString(),
        type: (json['type'] ?? 'info').toString(),
        isRead: json['isRead'] ?? false,
        actionUrl: json['actionUrl']?.toString(),
        relatedModel: json['relatedModel']?.toString(),
        relatedEntity: json['relatedEntity']?.toString(),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );
}
