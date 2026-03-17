import '../../core/storage/app_database.dart';
import '../../domain/models/content_scan_summary.dart';

class ContentScanService {
  const ContentScanService();

  ContentScanSummary scanVideo(LocalVideo video) {
    final titleTokens = video.title
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.isNotEmpty);
    final labels = <String>{
      ...titleTokens,
      ...video.tags.map((tag) => tag.toLowerCase()),
      ...video.cvLabels.map((label) => label.toLowerCase()),
    };
    final flags = <String>[];
    var score = 0;

    const highRiskTerms = <String>{
      'violence',
      'blood',
      'weapon',
      'nudity',
      'explicit',
      'fight',
      'abuse',
    };
    const reviewTerms = <String>{
      'scary',
      'crying',
      'yelling',
      'prank',
      'mature',
      'shouting',
    };

    if (labels.any(highRiskTerms.contains)) {
      flags.add('high_risk_label');
      score += 2;
    }
    if (labels.any(reviewTerms.contains)) {
      flags.add('review_label');
      score += 1;
    }

    if (video.loudness > 0.85) {
      flags.add('very_loud_audio');
      score += 1;
    }

    if (video.faceCount > 3) {
      flags.add('crowded_frame');
      score += 1;
    }

    if (video.durationSeconds > 180) {
      flags.add('long_clip');
      score += 1;
    }

    if (labels.contains('live') || labels.contains('challenge')) {
      flags.add('attention_seeking_title');
      score += 1;
    }

    final riskLevel = switch (score) {
      >= 3 => 'high',
      > 0 => 'medium',
      _ => 'low',
    };
    final needsReview = riskLevel != 'low';
    final reasons = flags.map(_humanizeFlag).take(2).toList(growable: false);
    final summary = switch ((riskLevel, reasons.isEmpty)) {
      ('high', false) => 'Needs review: ${reasons.join(' and ')}.',
      ('medium', false) => 'Please check: ${reasons.join(' and ')}.',
      ('high', true) => 'Needs parent review before sharing.',
      ('medium', true) => 'Looks okay, but a parent should check it first.',
      _ => 'No obvious concerns were found.',
    };

    return ContentScanSummary(
      riskLevel: riskLevel,
      flags: flags,
      labels: labels.toList(growable: false)..sort(),
      needsReview: needsReview,
      summary: summary,
    );
  }

  String _humanizeFlag(String flag) {
    return switch (flag) {
      'high_risk_label' => 'possibly unsafe content',
      'review_label' => 'a sensitive topic',
      'very_loud_audio' => 'very loud audio',
      'crowded_frame' => 'lots of faces in frame',
      'long_clip' => 'a long video',
      'attention_seeking_title' => 'an intense title',
      _ => flag.replaceAll('_', ' '),
    };
  }
}
