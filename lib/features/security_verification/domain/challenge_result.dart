class ChallengeResult {
  const ChallengeResult({
    required this.verified,
    required this.challengeScore,
    required this.challengeType,
    required this.completedAt,
  });

  final bool verified;
  final int challengeScore;
  final String challengeType;
  final DateTime completedAt;

  Map<String, dynamic> toJson() {
    return {
      'verified': verified,
      'challengeScore': challengeScore,
      'challengeType': challengeType,
      'completedAt': completedAt.toUtc().toIso8601String(),
    };
  }
}
