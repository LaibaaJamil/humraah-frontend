class NGO {
  final String id;
  final String name;
  final String registrationNumber;
  final String description;
  final List<String> sectors;
  final String email;
  final String? phone;
  final String website;
  final String address;
  final String city;
  final String province;
  final double lat;
  final double lng;
  final String logo;
  final String legalCertificate;
  final String verificationStatus;
  final String rejectionReason;
  final String? ownerId;
  final String? ownerName;
  final int staffCount;
  final List<String> languagesSupported;
  final DateTime? createdAt;

  NGO({
    required this.id,
    required this.name,
    required this.registrationNumber,
    this.description = '',
    this.sectors = const [],
    required this.email,
    this.phone,
    this.website = '',
    this.address = '',
    this.city = '',
    this.province = '',
    this.lat = 0,
    this.lng = 0,
    this.logo = '',
    this.legalCertificate = '',
    this.verificationStatus = 'pending',
    this.rejectionReason = '',
    this.ownerId,
    this.ownerName,
    this.staffCount = 0,
    this.languagesSupported = const ['English', 'Urdu'],
    this.createdAt,
  });

  factory NGO.fromJson(Map<String, dynamic> json) {
    final loc = (json['location'] as Map<String, dynamic>?) ?? {};
    String? ownerId;
    String? ownerName;
    if (json['owner'] is Map<String, dynamic>) {
      final o = json['owner'] as Map<String, dynamic>;
      ownerId = (o['_id'] ?? o['id'])?.toString();
      ownerName = o['name']?.toString();
    } else if (json['owner'] != null) {
      ownerId = json['owner'].toString();
    }
    return NGO(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      registrationNumber: (json['registrationNumber'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      sectors: ((json['sectors'] as List?) ?? []).map((e) => e.toString()).toList(),
      email: (json['email'] ?? '').toString(),
      phone: json['phone']?.toString(),
      website: (json['website'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      province: (json['province'] ?? '').toString(),
      lat: (loc['lat'] ?? 0).toDouble(),
      lng: (loc['lng'] ?? 0).toDouble(),
      logo: (json['logo'] ?? '').toString(),
      legalCertificate: (json['legalCertificate'] ?? '').toString(),
      verificationStatus: (json['verificationStatus'] ?? 'pending').toString(),
      rejectionReason: (json['rejectionReason'] ?? '').toString(),
      ownerId: ownerId,
      ownerName: ownerName,
      staffCount: (json['staffCount'] ?? 0) is int
          ? json['staffCount'] as int
          : int.tryParse(json['staffCount'].toString()) ?? 0,
      languagesSupported: ((json['languagesSupported'] as List?) ?? const ['English', 'Urdu'])
          .map((e) => e.toString())
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'registrationNumber': registrationNumber,
        'description': description,
        'sectors': sectors,
        'email': email,
        'phone': phone,
        'website': website,
        'address': address,
        'city': city,
        'province': province,
        'location': {'lat': lat, 'lng': lng},
        'logo': logo,
        'verificationStatus': verificationStatus,
        'staffCount': staffCount,
      };

  bool get isVerified => verificationStatus == 'verified';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';
}
