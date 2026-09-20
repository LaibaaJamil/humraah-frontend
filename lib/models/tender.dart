class Tender {
  final String id;
  final String title;
  final String description;
  final String sector;
  final num budgetAmount;
  final String currency;
  final DateTime deadline;
  final String eligibility;
  final String location;
  final bool allowCoalitions;
  final int maxCoalitionPartners;
  final String status;
  final String donorOrganization;
  final String? postedByName;
  final String? postedById;
  final DateTime? createdAt;

  Tender({
    required this.id,
    required this.title,
    required this.description,
    this.sector = 'general',
    this.budgetAmount = 0,
    this.currency = 'PKR',
    required this.deadline,
    this.eligibility = '',
    this.location = 'Pakistan',
    this.allowCoalitions = true,
    this.maxCoalitionPartners = 5,
    this.status = 'open',
    this.donorOrganization = '',
    this.postedByName,
    this.postedById,
    this.createdAt,
  });

  factory Tender.fromJson(Map<String, dynamic> json) {
    final posted = json['postedBy'];
    String? postedById;
    String? postedByName;
    if (posted is Map<String, dynamic>) {
      postedById = (posted['_id'] ?? posted['id'])?.toString();
      postedByName = posted['name']?.toString();
    } else if (posted != null) {
      postedById = posted.toString();
    }
    return Tender(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      sector: (json['sector'] ?? 'general').toString(),
      budgetAmount: (json['budgetAmount'] ?? 0) is num
          ? json['budgetAmount'] as num
          : num.tryParse(json['budgetAmount'].toString()) ?? 0,
      currency: (json['currency'] ?? 'PKR').toString(),
      deadline: DateTime.tryParse(json['deadline']?.toString() ?? '') ?? DateTime.now(),
      eligibility: (json['eligibility'] ?? '').toString(),
      location: (json['location'] ?? 'Pakistan').toString(),
      allowCoalitions: json['allowCoalitions'] ?? true,
      maxCoalitionPartners: (json['maxCoalitionPartners'] ?? 5) is int
          ? json['maxCoalitionPartners'] as int
          : int.tryParse(json['maxCoalitionPartners'].toString()) ?? 5,
      status: (json['status'] ?? 'open').toString(),
      donorOrganization: (json['donorOrganization'] ?? '').toString(),
      postedByName: postedByName,
      postedById: postedById,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Duration get timeLeft => deadline.difference(DateTime.now());
  bool get isOpen => status == 'open';
  bool get isExpired => DateTime.now().isAfter(deadline);
}

class TenderApplication {
  final String id;
  final String tenderId;
  final String? tenderTitle;
  final num requestedAmount;
  final int timelineMonths;
  final String proposalSummary;
  final String status;
  final String feedback;
  final DateTime? createdAt;

  TenderApplication({
    required this.id,
    required this.tenderId,
    this.tenderTitle,
    required this.requestedAmount,
    this.timelineMonths = 12,
    required this.proposalSummary,
    this.status = 'submitted',
    this.feedback = '',
    this.createdAt,
  });

  factory TenderApplication.fromJson(Map<String, dynamic> json) {
    final tender = json['tender'];
    String tId;
    String? tTitle;
    if (tender is Map<String, dynamic>) {
      tId = (tender['_id'] ?? '').toString();
      tTitle = tender['title']?.toString();
    } else {
      tId = tender?.toString() ?? '';
    }
    return TenderApplication(
      id: (json['_id'] ?? '').toString(),
      tenderId: tId,
      tenderTitle: tTitle,
      requestedAmount: (json['requestedAmount'] ?? 0) is num
          ? json['requestedAmount'] as num
          : num.tryParse(json['requestedAmount'].toString()) ?? 0,
      timelineMonths: (json['timelineMonths'] ?? 12) is int
          ? json['timelineMonths'] as int
          : int.tryParse(json['timelineMonths'].toString()) ?? 12,
      proposalSummary: (json['proposalSummary'] ?? '').toString(),
      status: (json['status'] ?? 'submitted').toString(),
      feedback: (json['feedback'] ?? '').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
