class MapPin {
  final String id;
  final String type;
  final String title;
  final String description;
  final double lat;
  final double lng;
  final String address;
  final String city;
  final String? flagCategory;
  final String urgencyLevel;
  final String status;
  final String verificationStatus;
  final String? ngoName;
  final String? ngoId;
  final String? createdById;
  final String? createdByName;
  final List<String> respondedBy;
  final DateTime? createdAt;

  MapPin({
    required this.id,
    required this.type,
    required this.title,
    this.description = '',
    required this.lat,
    required this.lng,
    this.address = '',
    this.city = '',
    this.flagCategory,
    this.urgencyLevel = 'medium',
    this.status = 'active',
    this.verificationStatus = 'verified',
    this.ngoName,
    this.ngoId,
    this.createdById,
    this.createdByName,
    this.respondedBy = const [],
    this.createdAt,
  });

  factory MapPin.fromJson(Map<String, dynamic> json) {
    final loc = (json['location'] as Map<String, dynamic>?) ?? {};
    final ngo = json['ngo'];
    final createdBy = json['createdBy'];
    return MapPin(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? 'project').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      lat: (loc['lat'] ?? 0).toDouble(),
      lng: (loc['lng'] ?? 0).toDouble(),
      address: (json['address'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      flagCategory: json['flagCategory']?.toString(),
      urgencyLevel: (json['urgencyLevel'] ?? 'medium').toString(),
      status: (json['status'] ?? 'active').toString(),
      verificationStatus: (json['verificationStatus'] ?? 'verified').toString(),
      ngoName: ngo is Map<String, dynamic> ? ngo['name']?.toString() : null,
      ngoId: ngo is Map<String, dynamic>
          ? (ngo['_id'] ?? ngo['id'])?.toString()
          : ngo?.toString(),
      createdById: createdBy is Map<String, dynamic>
          ? (createdBy['_id'] ?? createdBy['id'])?.toString()
          : createdBy?.toString(),
      createdByName: createdBy is Map<String, dynamic> ? createdBy['name']?.toString() : null,
      respondedBy: ((json['respondedBy'] as List?) ?? []).map((e) => e.toString()).toList(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  bool get isFlag => type == 'flag';
  bool get isOffice => type == 'office';
  bool get isProject => type == 'project';
  bool get isPending => verificationStatus == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved => status == 'resolved';
}
