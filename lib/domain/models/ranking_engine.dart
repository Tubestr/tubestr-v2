import 'dart:math';

import '../../core/storage/app_database.dart';
import 'ranking_state.dart';

enum FeedShelf {
  forYou('For You'),
  recent('Recent'),
  action('Action'),
  favorites('Favorites');

  const FeedShelf(this.label);

  final String label;
}

class RankedVideo {
  const RankedVideo({
    required this.video,
    required this.score,
  });

  final LocalVideo video;
  final double score;
}

class RankingResult {
  const RankingResult({
    required this.ranked,
    required this.shelves,
    this.hero,
  });

  final List<RankedVideo> ranked;
  final RankedVideo? hero;
  final Map<FeedShelf, List<RankedVideo>> shelves;
}

class RankingEngine {
  const RankingEngine();

  RankingResult rank({
    required List<LocalVideo> videos,
    RankingState rankingState = const RankingState(),
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    if (videos.isEmpty) {
      return const RankingResult(ranked: [], shelves: {});
    }

    final baseRanked = videos
        .map(
          (video) => RankedVideo(
            video: video,
            score: _baseScore(video, rankingState, now),
          ),
        )
        .toList()
      ..sort((left, right) => right.score.compareTo(left.score));

    final diversified = _applyDiversityPenalty(baseRanked);
    final explored =
        _injectExploreSamples(diversified, videos, rankingState.exploreRate);

    return RankingResult(
      ranked: explored,
      hero: explored.isEmpty ? null : explored.first,
      shelves: {
        FeedShelf.forYou: explored,
        FeedShelf.recent: _sortByRecency(videos),
        FeedShelf.action:
            videos.where((video) => video.loudness >= 0.4).map(_zeroScore).toList(),
        FeedShelf.favorites:
            videos.where((video) => video.liked).map(_zeroScore).toList(),
      },
    );
  }

  double _baseScore(
    LocalVideo video,
    RankingState rankingState,
    DateTime referenceDate,
  ) {
    final completion = _clamp(video.completionRate);
    final replay = _clamp(video.replayRate);
    final recency = _recencyBoost(video, referenceDate);
    final topic = _topicMatch(video, rankingState);
    final likeBoost = video.liked ? 1.0 : 0.0;
    final fatigue = _fatiguePenalty(video);

    return 0.4 * completion +
        0.2 * replay +
        0.15 * recency +
        0.15 * topic +
        0.25 * likeBoost -
        0.2 * fatigue;
  }

  double _clamp(double value) => value.clamp(0.0, 1.0);

  double _recencyBoost(LocalVideo video, DateTime referenceDate) {
    final age = referenceDate.difference(video.createdAt).inSeconds / 86400;
    return _clamp(1 - (age / 14));
  }

  double _topicMatch(LocalVideo video, RankingState rankingState) {
    if (video.tags.isEmpty) {
      return 0;
    }
    final scores = video.tags
        .map((tag) => rankingState.topicSuccess[tag])
        .whereType<double>()
        .toList();
    if (scores.isEmpty) {
      return 0;
    }
    return _clamp(scores.reduce((left, right) => left + right) / scores.length);
  }

  double _fatiguePenalty(LocalVideo video) {
    return (video.playCount / 10).clamp(0, 1).toDouble();
  }

  List<RankedVideo> _applyDiversityPenalty(List<RankedVideo> ranked) {
    if (ranked.length < 2) {
      return ranked;
    }

    final adjusted = <RankedVideo>[];
    for (final candidate in ranked) {
      final penalty = adjusted
              .map((existing) => _diversityPenalty(existing.video, candidate.video))
              .fold<double>(0, (current, value) => value > current ? value : current);
      adjusted.add(RankedVideo(video: candidate.video, score: candidate.score - penalty));
    }
    adjusted.sort((left, right) => right.score.compareTo(left.score));
    return adjusted;
  }

  double _diversityPenalty(LocalVideo left, LocalVideo right) {
    final leftSet = left.tags.toSet();
    final rightSet = right.tags.toSet();
    if (leftSet.isEmpty && rightSet.isEmpty) {
      return 0;
    }
    final intersection = leftSet.intersection(rightSet).length;
    final union = leftSet.union(rightSet).length;
    final similarity = union == 0 ? 0 : intersection / union;
    return similarity * 0.2;
  }

  List<RankedVideo> _injectExploreSamples(
    List<RankedVideo> ranked,
    List<LocalVideo> allVideos,
    double exploreRate,
  ) {
    if (exploreRate <= 0 || allVideos.isEmpty) {
      return ranked;
    }

    final exploreCount = (allVideos.length * exploreRate).floor().clamp(1, allVideos.length);
    final generator = Random(allVideos.length);
    final shuffled = [...allVideos]..shuffle(generator);
    final exploratory = shuffled.take(exploreCount).map(
          (video) => RankedVideo(
            video: video,
            score: ranked.isEmpty ? 0.5 : ranked.first.score,
          ),
        );

    final blended = [...ranked];
    for (final entry in exploratory.indexed) {
      final index = (entry.$1 * 3 + 2).clamp(0, blended.length);
      blended.insert(index, entry.$2);
    }

    final seen = <String>{};
    return blended.where((item) => seen.add(item.video.id)).toList();
  }

  List<RankedVideo> _sortByRecency(List<LocalVideo> videos) {
    final sorted = [...videos]..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return sorted.map(_zeroScore).toList();
  }

  RankedVideo _zeroScore(LocalVideo video) => RankedVideo(video: video, score: 0);
}
