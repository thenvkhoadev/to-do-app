import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/xp/data/models/xp_log_model.dart';
import 'package:to_do_app/features/xp/presentation/providers/xp_providers.dart';
import 'package:to_do_app/features/xp/presentation/widgets/level_down_modal.dart';
import 'package:to_do_app/features/xp/presentation/widgets/level_up_modal.dart';
import 'package:to_do_app/features/xp/presentation/widgets/xp_level_card.dart' show xpLevelFromTotalXp;
import 'package:to_do_app/features/xp/presentation/widgets/xp_notification_overlay.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';

/// Wraps authenticated content. Listens to [xpLogsProvider] for new inserts,
/// queues XP toast notifications, and shows the level-up modal when the user's
/// level advances. Toast shows first; modal slides up after the toast is gone
/// (5 s from the XP insert).
class XpOverlayShell extends ConsumerStatefulWidget {
  const XpOverlayShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<XpOverlayShell> createState() => _XpOverlayShellState();
}

class _XpOverlayShellState extends ConsumerState<XpOverlayShell> {
  // Track the IDs we have already processed so we don't fire twice on rebuild.
  final Set<String> _seen = {};
  int? _lastKnownLevel;
  Timer? _levelUpTimer;

  @override
  void dispose() {
    _levelUpTimer?.cancel();
    super.dispose();
  }

  void _handleNewLogs(List<XpLogModel> logs) {
    for (final log in logs) {
      if (_seen.contains(log.id)) continue;
      _seen.add(log.id);

      final age = DateTime.now().toUtc().difference(log.createdAt.toUtc());
      if (age.inSeconds > 60) continue;

      final hasLucky = log.hasLuckyBonus;
      const tierValues = [100, 50, 20, 10];
      int baseXp = 10;
      for (final t in tierValues) {
        if (log.xpGained >= t) { baseXp = t; break; }
      }
      final bonusXp = hasLucky ? (log.xpGained - baseXp).clamp(0, 15) : 0;
      final String priority;
      if (baseXp >= 100) {
        priority = 'urgent';
      } else if (baseXp >= 50) {
        priority = 'high';
      } else if (baseXp >= 20) {
        priority = 'medium';
      } else {
        priority = 'low';
      }

      final queue = ref.read(xpNotificationQueueProvider.notifier);
      if (bonusXp > 0) {
        queue.push(
          XpNotification(
            id: '${log.id}-base',
            xpGained: baseXp,
            reason: 'Task Completed',
            createdAt: log.createdAt,
            priority: priority,
          ),
        );
        queue.push(
          XpNotification(
            id: '${log.id}-bonus',
            xpGained: bonusXp,
            reason: 'Lucky Bonus',
            createdAt: log.createdAt,
            bonusXp: bonusXp,
            priority: 'bonus',
          ),
        );
      } else {
        queue.push(
          XpNotification(
            id: log.id,
            xpGained: log.xpGained,
            reason: log.reason,
            createdAt: log.createdAt,
            priority: priority,
          ),
        );
      }

      // Predict level immediately — don't wait for userProfileProvider stream.
      final currentTotalXp = ref.read(userProfileProvider).valueOrNull?.totalXp ?? 0;
      final currentLevel = _lastKnownLevel ?? ref.read(userProfileProvider).valueOrNull?.level ?? 1;
      final predictedTotalXp = currentTotalXp + log.xpGained;
      final predictedLevel = xpLevelFromTotalXp(predictedTotalXp);
      if (predictedLevel > currentLevel) {
        _levelUpTimer?.cancel();
        _levelUpTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            _lastKnownLevel = predictedLevel;
            ref.read(levelUpProvider.notifier).levelUp(predictedLevel);
          }
        });
      }
    }
  }

  void _handleLevelChange(int newLevel) {
    if (_lastKnownLevel == null) {
      _lastKnownLevel = newLevel;
      return;
    }
    if (newLevel > _lastKnownLevel!) {
      _lastKnownLevel = newLevel;
      _levelUpTimer?.cancel();
      _levelUpTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          ref.read(levelUpProvider.notifier).levelUp(newLevel);
        }
      });
    } else {
      _lastKnownLevel = newLevel;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to new xp_logs
    ref.listen(xpLogsProvider, (_, next) {
      next.whenData(_handleNewLogs);
    });

    // Listen to profile level changes
    ref.listen(userProfileProvider, (prev, next) {
      final level = next.valueOrNull?.level;
      if (level != null) _handleLevelChange(level);
    });

    final pendingLevelUp = ref.watch(levelUpProvider);
    final pendingLevelDown = ref.watch(levelDownProvider);

    return XpNotificationOverlay(
      child: Stack(
        children: [
          widget.child,
          if (pendingLevelDown != null)
            Positioned.fill(
              child: LevelDownModal(newLevel: pendingLevelDown),
            ),
          if (pendingLevelUp != null)
            Positioned.fill(
              child: LevelUpModal(newLevel: pendingLevelUp),
            ),
        ],
      ),
    );
  }
}
