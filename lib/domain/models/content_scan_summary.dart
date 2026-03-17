import 'dart:convert';

class ContentScanSummary {
  const ContentScanSummary({
    required this.riskLevel,
    required this.flags,
    required this.labels,
    required this.needsReview,
    required this.summary,
  });

  final String riskLevel;
  final List<String> flags;
  final List<String> labels;
  final bool needsReview;
  final String summary;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'risk_level': riskLevel,
    'flags': flags,
    'labels': labels,
    'needs_review': needsReview,
    'summary': summary,
  };

  String encode() => jsonEncode(toJson());

  factory ContentScanSummary.fromJson(Map<String, dynamic> json) {
    return ContentScanSummary(
      riskLevel: json['risk_level']?.toString() ?? 'low',
      flags: (json['flags'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      labels: (json['labels'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      needsReview: json['needs_review'] == true,
      summary: json['summary']?.toString() ?? '',
    );
  }

  factory ContentScanSummary.decode(String raw) {
    return ContentScanSummary.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }
}
