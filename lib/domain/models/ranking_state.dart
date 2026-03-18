class RankingState {
  const RankingState({this.topicSuccess = const {}, this.exploreRate = 0.15});

  final Map<String, double> topicSuccess;
  final double exploreRate;
}
