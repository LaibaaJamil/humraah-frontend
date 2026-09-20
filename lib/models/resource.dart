class ResourceItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String sector;
  final String language;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final List<String> tags;
  final int downloadCount;
  final String? uploaderName;
  final String? ngoName;
  final String? ngoLogo;
  final DateTime? createdAt;

  ResourceItem({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'other',
    this.sector = 'general',
    this.language = 'English',
    required this.fileUrl,
    this.fileType = '',
    this.fileSize = 0,
    this.tags = const [],
    this.downloadCount = 0,
    this.uploaderName,
    this.ngoName,
    this.ngoLogo,
    this.createdAt,
  });

  factory ResourceItem.fromJson(Map<String, dynamic> json) {
    final uploader = json['uploadedBy'];
    final ngo = json['ngo'];
    return ResourceItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? 'other').toString(),
      sector: (json['sector'] ?? 'general').toString(),
      language: (json['language'] ?? 'English').toString(),
      fileUrl: (json['fileUrl'] ?? '').toString(),
      fileType: (json['fileType'] ?? '').toString(),
      fileSize: (json['fileSize'] ?? 0) is int
          ? json['fileSize'] as int
          : int.tryParse(json['fileSize'].toString()) ?? 0,
      tags: ((json['tags'] as List?) ?? []).map((e) => e.toString()).toList(),
      downloadCount: (json['downloadCount'] ?? 0) is int
          ? json['downloadCount'] as int
          : int.tryParse(json['downloadCount'].toString()) ?? 0,
      uploaderName: uploader is Map<String, dynamic> ? uploader['name']?.toString() : null,
      ngoName: ngo is Map<String, dynamic> ? ngo['name']?.toString() : null,
      ngoLogo: ngo is Map<String, dynamic> ? ngo['logo']?.toString() : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
