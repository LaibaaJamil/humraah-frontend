class ReportMetrics {
  final int beneficiariesReached;
  final int eventsConducted;
  final int resourcesDistributed;
  final int volunteersEngaged;
  final num fundsUtilized;

  ReportMetrics({
    this.beneficiariesReached = 0,
    this.eventsConducted = 0,
    this.resourcesDistributed = 0,
    this.volunteersEngaged = 0,
    this.fundsUtilized = 0,
  });

  factory ReportMetrics.fromJson(Map<String, dynamic> json) => ReportMetrics(
        beneficiariesReached: (json['beneficiariesReached'] ?? 0) as int,
        eventsConducted: (json['eventsConducted'] ?? 0) as int,
        resourcesDistributed: (json['resourcesDistributed'] ?? 0) as int,
        volunteersEngaged: (json['volunteersEngaged'] ?? 0) as int,
        fundsUtilized: (json['fundsUtilized'] ?? 0) as num,
      );

  Map<String, dynamic> toJson() => {
        'beneficiariesReached': beneficiariesReached,
        'eventsConducted': eventsConducted,
        'resourcesDistributed': resourcesDistributed,
        'volunteersEngaged': volunteersEngaged,
        'fundsUtilized': fundsUtilized,
      };
}

class Report {
  final String id;
  final int month;
  final int year;
  final String sector;
  final ReportMetrics metrics;
  final int women;
  final int men;
  final int children;
  final List<String> locations;
  final String summary;

  Report({
    required this.id,
    required this.month,
    required this.year,
    this.sector = 'general',
    required this.metrics,
    this.women = 0,
    this.men = 0,
    this.children = 0,
    this.locations = const [],
    this.summary = '',
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    final p = (json['period'] as Map<String, dynamic>?) ?? {};
    final m = (json['metrics'] as Map<String, dynamic>?) ?? {};
    final b = (json['breakdown'] as Map<String, dynamic>?) ?? {};
    return Report(
      id: (json['_id'] ?? '').toString(),
      month: (p['month'] ?? 1) as int,
      year: (p['year'] ?? DateTime.now().year) as int,
      sector: (json['sector'] ?? 'general').toString(),
      metrics: ReportMetrics.fromJson(m),
      women: (b['women'] ?? 0) as int,
      men: (b['men'] ?? 0) as int,
      children: (b['children'] ?? 0) as int,
      locations:
          ((json['locations'] as List?) ?? []).map((e) => e.toString()).toList(),
      summary: (json['summary'] ?? '').toString(),
    );
  }
}
