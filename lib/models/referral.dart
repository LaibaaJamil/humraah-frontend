class Referral {
  final String id;
  final String? fromNGOName;
  final String? toNGOName;
  final String caseTitle;
  final String caseCategory;
  final String details;
  final String contact;
  final String urgency;
  final String status;
  final String notes;
  final DateTime? createdAt;

  Referral({
    required this.id,
    this.fromNGOName,
    this.toNGOName,
    required this.caseTitle,
    required this.caseCategory,
    this.details = '',
    this.contact = '',
    this.urgency = 'medium',
    this.status = 'pending',
    this.notes = '',
    this.createdAt,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    final from = json['fromNGO'];
    final to = json['toNGO'];
    return Referral(
      id: (json['_id'] ?? '').toString(),
      fromNGOName: from is Map<String, dynamic> ? from['name']?.toString() : null,
      toNGOName: to is Map<String, dynamic> ? to['name']?.toString() : null,
      caseTitle: (json['caseTitle'] ?? '').toString(),
      caseCategory: (json['caseCategory'] ?? 'other').toString(),
      details: (json['details'] ?? '').toString(),
      contact: (json['contact'] ?? '').toString(),
      urgency: (json['urgency'] ?? 'medium').toString(),
      status: (json['status'] ?? 'pending').toString(),
      notes: (json['notes'] ?? '').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
