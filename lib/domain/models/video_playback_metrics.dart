class VideoPlaybackMetrics {
  const VideoPlaybackMetrics({
    required this.playCount,
    required this.completionRate,
    required this.replayRate,
  });

  final int playCount;
  final double completionRate;
  final double replayRate;
}
