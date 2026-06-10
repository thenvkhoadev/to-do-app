import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/xp/data/datasource/xp_remote_datasource.dart';
import 'package:to_do_app/features/xp/data/models/xp_log_model.dart';

// ── Datasource ────────────────────────────────────────────────────────────────

final xpRemoteDataSourceProvider = Provider<XpRemoteDataSource>((ref) {
  return XpRemoteDataSource(ref.watch(supabaseClientProvider));
});

// ── Realtime xp_logs stream ───────────────────────────────────────────────────

final xpLogsProvider = StreamProvider<List<XpLogModel>>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(xpRemoteDataSourceProvider).watchXpLogs(user.id);
});

// ── Periodic stats (today / week / month) ────────────────────────────────────

final xpTodayProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return 0;
  return ref.read(xpRemoteDataSourceProvider).fetchXpToday(user.id);
});

final xpThisWeekProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return 0;
  return ref.read(xpRemoteDataSourceProvider).fetchXpThisWeek(user.id);
});

final xpThisMonthProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return 0;
  return ref.read(xpRemoteDataSourceProvider).fetchXpThisMonth(user.id);
});

// ── Notification queue state ──────────────────────────────────────────────────

class XpNotification {
  const XpNotification({
    required this.id,
    required this.xpGained,
    required this.reason,
    required this.createdAt,
    this.bonusXp = 0,
    this.priority = 'medium',
  });

  final String id;
  final int xpGained;
  final String reason;
  final DateTime createdAt;
  final int bonusXp;
  final String priority;

  bool get hasLuckyBonus => bonusXp > 0;
  bool get isEpic => priority == 'urgent';

  int get baseXp => xpGained - bonusXp;
}

class XpNotificationQueue extends Notifier<List<XpNotification>> {
  @override
  List<XpNotification> build() => [];

  void push(XpNotification n) {
    state = [...state, n];
  }

  void remove(String id) {
    state = state.where((n) => n.id != id).toList();
  }
}

final xpNotificationQueueProvider =
    NotifierProvider<XpNotificationQueue, List<XpNotification>>(
  XpNotificationQueue.new,
);

// ── Level-down pending state ──────────────────────────────────────────────────

class LevelDownNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void levelDown(int newLevel) => state = newLevel;
  void dismiss() => state = null;
}

final levelDownProvider = NotifierProvider<LevelDownNotifier, int?>(
  LevelDownNotifier.new,
);

class LevelUpNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void levelUp(int newLevel) => state = newLevel;
  void dismiss() => state = null;
}

final levelUpProvider = NotifierProvider<LevelUpNotifier, int?>(
  LevelUpNotifier.new,
);
