import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/xp/data/models/xp_log_model.dart';
import 'package:to_do_app/features/xp/presentation/providers/xp_providers.dart';

const _kSurface = Color(0xFF0E1626);
const _kBorder = Color(0xFF2A3650);
const _kPrimary = Color(0xFFB794F6);
const _kCyan = Color(0xFF67E8F9);
const _kOnSurface = Color(0xFFF5F7FF);
const _kMuted = Color(0xFFA8B2D1);

// ── XP Log Timeline ───────────────────────────────────────────────────────────

class XpLogTimeline extends ConsumerWidget {
  const XpLogTimeline({super.key, this.maxItems = 8});
  final int maxItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(xpLogsProvider);
    return _Shell(
      child: logsAsync.when(
        loading: () => const _Loading(),
        error: (_, __) => const _Error(),
        data: (logs) {
          if (logs.isEmpty) return const _Empty();
          final visible = logs.take(maxItems).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 16),
              for (final log in visible)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LogTile(log: log),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.history_rounded, color: _kPrimary, size: 18),
        SizedBox(width: 8),
        Text(
          'Recent XP Activity',
          style: TextStyle(
            color: _kOnSurface,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Log tile ─────────────────────────────────────────────────────────────────

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});
  final XpLogModel log;

  @override
  Widget build(BuildContext context) {
    final isLucky = log.hasLuckyBonus;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF18223A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder, width: 0.5),
      ),
      child: Row(
        children: [
          // XP badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLucky
                    ? const [_kCyan, _kPrimary]
                    : const [_kPrimary, Color(0xFF7B6CF6)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+${log.xpGained}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Reason
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.reason,
                  style: const TextStyle(
                    color: _kOnSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _relativeTime(log.createdAt),
                  style: const TextStyle(
                    color: _kMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (isLucky)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text('🍀', style: TextStyle(fontSize: 14)),
            ),
        ],
      ),
    );
  }
}

String _relativeTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  return '${dt.month}/${dt.day}';
}

// ── Shell / states ───────────────────────────────────────────────────────────

class _Shell extends StatelessWidget {
  const _Shell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kSurface.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2),
        ),
      );
}

class _Error extends StatelessWidget {
  const _Error();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 60,
        child: Center(
          child: Text(
            'Could not load XP activity',
            style: TextStyle(color: _kMuted, fontSize: 13),
          ),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _Header(),
        SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Complete a task to start earning XP.',
            style: TextStyle(color: _kMuted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
