import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/streak/data/datasource/streak_remote_datasource.dart';
import 'package:to_do_app/features/streak/data/models/streak_day_model.dart';

final streakRemoteDataSourceProvider = Provider<StreakRemoteDataSource>((ref) {
  return StreakRemoteDataSource(ref.watch(supabaseClientProvider));
});

final userStreakDaysProvider = StreamProvider<List<StreakDayModel>>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(streakRemoteDataSourceProvider).watchStreakDays(user.id);
});

class StreakCelebration {
  const StreakCelebration({
    required this.previousCount,
    required this.currentCount,
  });

  final int previousCount;
  final int currentCount;
}

class PendingStreakNotifier extends Notifier<StreakCelebration?> {
  @override
  StreakCelebration? build() => null;

  void show({required int previousCount, required int currentCount}) {
    state = StreakCelebration(
      previousCount: previousCount,
      currentCount: currentCount,
    );
  }

  void dismiss() => state = null;
}

final pendingStreakProvider =
    NotifierProvider<PendingStreakNotifier, StreakCelebration?>(
  PendingStreakNotifier.new,
);

int displayStreakCount(int streakCount, DateTime? lastActivityDate) {
  if (lastActivityDate == null) return 0;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final localActivity = lastActivityDate.toLocal();
  final active = DateTime(
    localActivity.year,
    localActivity.month,
    localActivity.day,
  );
  if (active.isBefore(today.subtract(const Duration(days: 1)))) return 0;
  return streakCount;
}

final showStreakOverlayProvider = StateProvider<bool>((ref) => false);

