class AttractivenessScoreRequest {
  final double attractivenessScore;
  final DateTime timestamp;

  AttractivenessScoreRequest({
    required this.attractivenessScore,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'attractiveness_score': attractivenessScore,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
