import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/security_verification/domain/challenge_engine.dart';
import 'package:to_do_app/features/security_verification/domain/challenge_result.dart';

enum SecurityLevel { easy, medium, hard }

enum ChallengeFlowStatus { idle, inProgress, failed, completed }

extension SecurityLevelChallengeCount on SecurityLevel {
  int get challengeCount => switch (this) {
        SecurityLevel.easy => 1,
        SecurityLevel.medium => 2,
        SecurityLevel.hard => 3,
      };
}

class ChallengeState {
  const ChallengeState({
    required this.level,
    required this.challenges,
    required this.currentIndex,
    required this.status,
    this.result,
  });

  const ChallengeState.initial()
      : level = SecurityLevel.hard,
        challenges = const [],
        currentIndex = 0,
        status = ChallengeFlowStatus.idle,
        result = null;

  final SecurityLevel level;
  final List<Challenge> challenges;
  final int currentIndex;
  final ChallengeFlowStatus status;
  final ChallengeResult? result;

  Challenge? get currentChallenge =>
      currentIndex < challenges.length ? challenges[currentIndex] : null;

  int get totalSteps => level.challengeCount;

  ChallengeState copyWith({
    SecurityLevel? level,
    List<Challenge>? challenges,
    int? currentIndex,
    ChallengeFlowStatus? status,
    ChallengeResult? result,
    bool clearResult = false,
  }) {
    return ChallengeState(
      level: level ?? this.level,
      challenges: challenges ?? this.challenges,
      currentIndex: currentIndex ?? this.currentIndex,
      status: status ?? this.status,
      result: clearResult ? null : result ?? this.result,
    );
  }
}

class ChallengeController extends AutoDisposeNotifier<ChallengeState> {
  ChallengeController() : _engine = ChallengeEngine();

  final ChallengeEngine _engine;

  @override
  ChallengeState build() => const ChallengeState.initial();

  void start({SecurityLevel level = SecurityLevel.hard}) {
    state = ChallengeState(
      level: level,
      challenges: _engine.generateSequence(level.challengeCount),
      currentIndex: 0,
      status: ChallengeFlowStatus.inProgress,
    );
  }

  void retry() => start(level: state.level);

  bool submit(Object? answer) {
    final challenge = state.currentChallenge;
    if (challenge == null || state.status != ChallengeFlowStatus.inProgress) {
      return false;
    }

    if (!challenge.verify(answer)) {
      state = state.copyWith(status: ChallengeFlowStatus.failed, clearResult: true);
      return false;
    }

    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.challenges.length) {
      final challengeTypes = state.challenges.map((item) => item.type.id).join(',');
      state = state.copyWith(
        currentIndex: state.currentIndex,
        status: ChallengeFlowStatus.completed,
        result: ChallengeResult(
          verified: true,
          challengeScore: 100,
          challengeType: challengeTypes,
          completedAt: DateTime.now().toUtc(),
        ),
      );
      return true;
    }

    state = state.copyWith(currentIndex: nextIndex);
    return true;
  }

  void reset() {
    state = const ChallengeState.initial();
  }
}

final challengeControllerProvider =
    NotifierProvider.autoDispose<ChallengeController, ChallengeState>(
  ChallengeController.new,
);
