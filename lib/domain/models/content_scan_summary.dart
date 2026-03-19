import 'dart:convert';

class ContentScanSummary {
  const ContentScanSummary({
    required this.scanVersion,
    required this.riskLevel,
    required this.highestRiskCategory,
    required this.confidence,
    required this.reviewReasons,
    required this.flags,
    required this.labels,
    required this.needsReview,
    required this.summary,
  });

  final int scanVersion;
  final String riskLevel;
  final String? highestRiskCategory;
  final double confidence;
  final List<String> reviewReasons;
  final List<String> flags;
  final List<String> labels;
  final bool needsReview;
  final String summary;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'scan_version': scanVersion,
    'risk_level': riskLevel,
    'highest_risk_category': highestRiskCategory,
    'confidence': confidence,
    'review_reasons': reviewReasons,
    'flags': flags,
    'labels': labels,
    'needs_review': needsReview,
    'summary': summary,
  };

  String encode() => jsonEncode(toJson());

  factory ContentScanSummary.fromJson(Map<String, dynamic> json) {
    return ContentScanSummary(
      scanVersion: _parseInt(json['scan_version']) ?? 0,
      riskLevel: json['risk_level']?.toString() ?? 'low',
      highestRiskCategory: json['highest_risk_category']?.toString(),
      confidence: _parseDouble(json['confidence']) ?? 0,
      reviewReasons:
          (json['review_reasons'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(growable: false),
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
    return ContentScanSummary.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}

int? _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse('$value');
}

double? _parseDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse('$value');
}
