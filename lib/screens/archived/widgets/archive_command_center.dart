import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/tasks/data/models/category_model.dart';
import 'package:to_do_app/features/tasks/data/models/tag_model.dart';
import 'package:to_do_app/screens/archived/models/archived_task_model.dart';
import 'package:to_do_app/screens/archived/providers/restore_activity_provider.dart';
import 'package:to_do_app/screens/archived/widgets/archive_shared_widgets.dart';
import 'package:to_do_app/screens/archived/widgets/assignee_avatar_group.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class ArchiveCommandCenter extends StatelessWidget {
  const ArchiveCommandCenter({
    required this.tasks,
    required this.categories,
    required this.users,
    required this.tags,
    super.key,
  });

  final List<ArchivedTask> tasks;
  final List<CategoryModel> categories;
  final List<UserProfileModel> users;
  final List<TagModel> tags;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CcTitle('AI Archive Intelligence Center'),
        const SizedBox(height: 16),
        _IntelligenceRow(tasks: tasks, categories: categories, users: users),
        const SizedBox(height: 32),
        _CcTitle('Trends & Analytics'),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _TrendsWidget()),
            const SizedBox(width: 24),
            Expanded(flex: 1, child: _ProductivityScore(tasks: tasks)),
          ],
        ),
        const SizedBox(height: 24),
        _ActivityHeatmap(tasks: tasks),
        const SizedBox(height: 32),
        _CcTitle('Team & Organization'),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _AssigneeLeaderboard(tasks: tasks, users: users)),
            const SizedBox(width: 24),
            Expanded(child: _CategoryRanking(tasks: tasks, categories: categories)),
            const SizedBox(width: 24),
            Expanded(child: _TagCloud(tasks: tasks, tags: tags)),
          ],
        ),
        const SizedBox(height: 32),
        _CcTitle('AI Recommendations & Insights'),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _AiRecs()),
            const SizedBox(width: 24),
            Expanded(child: _KnowledgeBase()),
            const SizedBox(width: 24),
            Expanded(child: _FutureInsights(tasks: tasks)),
          ],
        ),
        const SizedBox(height: 32),
        _CcTitle('Audit & Activity'),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _RestoreFeed(tasks: tasks, users: users)),
            const SizedBox(width: 24),
            Expanded(child: _AuditLog(tasks: tasks, users: users)),
            const SizedBox(width: 24),
            Expanded(child: _StorageDashboard(tasks: tasks)),
          ],
        ),
      ],
    );
  }
}

class _CcTitle extends StatelessWidget {
  const _CcTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(color: DashboardColors.onSurface, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      );
}

// ── Intelligence Row ──────────────────────────────────────────────────────────

class _IntelligenceRow extends StatelessWidget {
  const _IntelligenceRow({required this.tasks, required this.categories, required this.users});
  final List<ArchivedTask> tasks;
  final List<CategoryModel> categories;
  final List<UserProfileModel> users;

  @override
  Widget build(BuildContext context) {
    final catCounts = <String, int>{};
    for (final t in tasks) {
      if (t.categoryId != null) catCounts[t.categoryId!] = (catCounts[t.categoryId!] ?? 0) + 1;
    }
    String topCat = 'None';
    int topCatN = 0;
    if (catCounts.isNotEmpty) {
      final top = catCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      topCat = categories.where((c) => c.id == top.key).firstOrNull?.name ?? 'Unknown';
      topCatN = top.value;
    }

    final uCounts = <String, int>{};
    for (final t in tasks) {
      for (final a in t.assigneeIds) { uCounts[a] = (uCounts[a] ?? 0) + 1; }
    }
    String topUser = 'None';
    int topUserN = 0;
    if (uCounts.isNotEmpty) {
      final top = uCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      final u = users.where((u) => u.id == top.key).firstOrNull;
      topUser = u?.fullName ?? u?.username ?? 'Unknown';
      topUserN = top.value;
    }

    int totalH = 0, doneN = 0;
    for (final t in tasks) {
      if (t.completedAt != null && t.createdAt != null) {
        totalH += t.completedAt!.difference(t.createdAt!).inHours;
        doneN++;
      }
    }
    final avg = doneN > 0 ? '${(totalH / doneN / 24).toStringAsFixed(1)} d' : '—';
    final score = tasks.isEmpty ? 0 : (tasks.where((t) => t.status == 'done').length / tasks.length * 100).round();

    return Row(
      children: [
        Expanded(child: _ICard(label: 'Top Category', value: topCat, sub: '$topCatN tasks', icon: Icons.folder_special_rounded, color: DashboardColors.primary)),
        const SizedBox(width: 16),
        Expanded(child: _ICard(label: 'Top Assignee', value: topUser, sub: '$topUserN tasks', icon: Icons.person_rounded, color: DashboardColors.secondary)),
        const SizedBox(width: 16),
        Expanded(child: _ICard(label: 'Avg Completion', value: avg, sub: 'per task', icon: Icons.timer_rounded, color: DashboardColors.success)),
        const SizedBox(width: 16),
        Expanded(child: _ICard(label: 'Efficiency', value: '$score%', sub: 'done before archive', icon: Icons.speed_rounded, color: const Color(0xFFFFB020))),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ArchiveGlassCard(
            padding: const EdgeInsets.all(18),
            radius: 16,
            glowColor: DashboardColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: const [
                  Icon(Icons.psychology_rounded, color: DashboardColors.primary, size: 15),
                  SizedBox(width: 7),
                  Text('AI Insight', style: TextStyle(color: DashboardColors.primary, fontSize: 11, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 8),
                const Text(
                  'Most archived tasks are recurring work items. Consider setting up automation rules.',
                  style: TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w600, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ICard extends StatelessWidget {
  const _ICard({required this.label, required this.value, required this.sub, required this.icon, required this.color});
  final String label, value, sub;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => ArchiveGlassCard(
        padding: const EdgeInsets.all(18),
        radius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 15),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(label, maxLines: 2, style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 14),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(sub, style: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: .8), fontSize: 11)),
          ],
        ),
      );
}

// ── Trends ────────────────────────────────────────────────────────────────────

class _TrendsWidget extends StatefulWidget {
  @override
  State<_TrendsWidget> createState() => _TrendsWidgetState();
}

class _TrendsWidgetState extends State<_TrendsWidget> {
  String _range = '7 Days';
  final _ranges = ['7 Days', '30 Days', '90 Days', '1 Year'];

  @override
  Widget build(BuildContext context) {
    return ArchiveGlassCard(
      padding: const EdgeInsets.all(20),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: DashboardColors.primary, size: 15),
              const SizedBox(width: 7),
              const Text('Archive Trends', style: TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
              const Spacer(),
              ...(_ranges.map((r) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: GestureDetector(
                  onTap: () => setState(() => _range = r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _range == r ? DashboardColors.primary.withValues(alpha: .15) : Colors.white.withValues(alpha: .04),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _range == r ? DashboardColors.primary.withValues(alpha: .35) : Colors.white.withValues(alpha: .08)),
                    ),
                    child: Text(r, style: TextStyle(color: _range == r ? DashboardColors.primary : DashboardColors.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
              ))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(14, (i) {
                const heights = [30.0, 50.0, 40.0, 70.0, 60.0, 90.0, 55.0, 45.0, 65.0, 80.0, 50.0, 35.0, 75.0, 100.0];
                final h = heights[i % heights.length];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300 + i * 30),
                          height: h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [DashboardColors.primary, DashboardColors.primary.withValues(alpha: .4)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Text('Archive activity for $_range', style: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: .6), fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Productivity Score ────────────────────────────────────────────────────────

class _ProductivityScore extends StatelessWidget {
  const _ProductivityScore({required this.tasks});
  final List<ArchivedTask> tasks;

  @override
  Widget build(BuildContext context) {
    final done = tasks.where((t) => t.status == 'done').length;
    final score = tasks.isEmpty ? 0 : (done / tasks.length * 100).round();
    final badge = score >= 90 ? 'Elite Performer' : score >= 70 ? 'High Achiever' : 'Good Progress';
    final badgeColor = score >= 90 ? DashboardColors.success : score >= 70 ? DashboardColors.primary : const Color(0xFFFFB020);

    return ArchiveGlassCard(
      padding: const EdgeInsets.all(20),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.emoji_events_rounded, color: Color(0xFFFFB020), size: 15),
            SizedBox(width: 7),
            Text('Productivity Score', style: TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 20),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90, height: 90,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withValues(alpha: .08),
                    valueColor: AlwaysStoppedAnimation(badgeColor),
                  ),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$score%', style: TextStyle(color: badgeColor, fontSize: 22, fontWeight: FontWeight.w900)),
                  Text('Score', style: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: .7), fontSize: 10)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: badgeColor.withValues(alpha: .3)),
              ),
              child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Assignee Leaderboard ──────────────────────────────────────────────────────

class _AssigneeLeaderboard extends StatelessWidget {
  const _AssigneeLeaderboard({required this.tasks, required this.users});
  final List<ArchivedTask> tasks;
  final List<UserProfileModel> users;

  @override
  Widget build(BuildContext context) {
    final counts = <String, (int, int)>{};
    for (final t in tasks) {
      for (final id in t.assigneeIds) {
        final cur = counts[id] ?? (0, 0);
        counts[id] = (cur.$1 + 1, cur.$2 + (t.status == 'done' ? 1 : 0));
      }
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.$1.compareTo(a.value.$1));
    final top = sorted.take(5).toList();

    return ArchiveGlassCard(
      padding: const EdgeInsets.all(18),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.leaderboard_rounded, color: DashboardColors.primary, size: 15),
            SizedBox(width: 7),
            Text('Top Contributors', style: TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          if (top.isEmpty)
            Text('No assignee data', style: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: .8), fontSize: 12))
          else
            ...top.asMap().entries.map((e) {
              final u = users.where((u) => u.id == e.value.key).firstOrNull;
              final total = e.value.value.$1;
              final done = e.value.value.$2;
              final eff = total > 0 ? (done / total * 100).round() : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(
                    width: 20, height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: e.key == 0 ? const Color(0xFFFFB020).withValues(alpha: .2) : Colors.white.withValues(alpha: .04),
                      border: Border.all(color: e.key == 0 ? const Color(0xFFFFB020) : Colors.white.withValues(alpha: .1)),
                    ),
                    child: Text('${e.key + 1}', style: TextStyle(color: e.key == 0 ? const Color(0xFFFFB020) : DashboardColors.onSurfaceVariant, fontSize: 9, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 8),
                  if (u != null) ...[AssigneeAvatarGroup(assignees: [u], avatarSize: 22, maxVisible: 1), const SizedBox(width: 6)],
                  Expanded(child: Text(u?.fullName ?? u?.username ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 12, fontWeight: FontWeight.w600))),
                  Text('$total', style: const TextStyle(color: DashboardColors.primary, fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: DashboardColors.success.withValues(alpha: .12), borderRadius: BorderRadius.circular(4)),
                    child: Text('$eff%', style: const TextStyle(color: DashboardColors.success, fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ]),
              );
            }),
        ],
      ),
    );
  }
}

// ── Category Ranking ──────────────────────────────────────────────────────────

class _CategoryRanking extends StatelessWidget {
  const _CategoryRanking({required this.tasks, required this.categories});
  final List<ArchivedTask> tasks;
  final List<CategoryModel> categories;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final t in tasks) {
      if (t.categoryId != null) counts[t.categoryId!] = (counts[t.categoryId!] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final max = top.isEmpty ? 1 : top.first.value;

    return ArchiveGlassCard(
      padding: const EdgeInsets.all(18),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.folder_special_rounded, color: DashboardColors.secondary, size: 15),
            SizedBox(width: 7),
            Text('Top Categories', style: TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          if (top.isEmpty)
            Text('No data', style: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: .8), fontSize: 12))
          else
            ...top.map((e) {
              final c = categories.where((c) => c.id == e.key).firstOrNull;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(c?.name ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 12, fontWeight: FontWeight.w600))),
                      Text('${e.value}', style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Stack(children: [
                        Container(height: 5, color: Colors.white.withValues(alpha: .06)),
                        FractionallySizedBox(
                          widthFactor: e.value / max,
                          child: Container(height: 5, decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), gradient: LinearGradient(colors: [DashboardColors.secondary.withValues(alpha: .5), DashboardColors.secondary]))),
                        ),
                      ]),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── AI Recommendations ────────────────────────────────────────────────────────

class _AiRecs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const recs = [
      (Icons.restore_rounded, 'Restore 4 active tasks', 'High priority items archived in error', DashboardColors.primary),
      (Icons.merge_type_rounded, 'Merge 3 duplicate tasks', 'Identical titles in Work category', DashboardColors.secondary),
      (Icons.delete_outline_rounded, 'Delete 12 old archives', 'Tasks older than 1 year', DashboardColors.error),
    ];
    return ArchiveGlassCard(
      padding: const EdgeInsets.all(18),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [DashboardColors.primary, DashboardColors.secondary]), borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 12),
            ),
            const SizedBox(width: 8),
            const Text('AI Recommendations', style: TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          ...recs.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: r.$4.withValues(alpha: .08), borderRadius: BorderRadius.circular(10), border: Border.all(color: r.$4.withValues(alpha: .2))),
              child: Row(children: [
                Icon(r.$1, color: r.$4, size: 16),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.$2, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 12, fontWeight: FontWeight.w700)),
                  Text(r.$3, style: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: .8), fontSize: 11)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: r.$4.withValues(alpha: .15), borderRadius: BorderRadius.circular(6)),
                  child: Text('Review', style: TextStyle(color: r.$4, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          )),
        ],
      ),
    );
  }
}

// ── Knowledge Base ────────────────────────────────────────────────────────────

class _KnowledgeBase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ArchiveGlassCard(
      padding: const EdgeInsets.all(18),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.library_books_rounded, color: DashboardColors.primary, size: 15),
            SizedBox(width: 7),
            Text('Archive Knowledge Base', style: TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          Text(
            'This month archived tasks mainly focused on:\n\n'
            '• Flutter UI\n'
            '• Backend Refactor\n'
            '• AI Features\n'
            '• Database Migration',
            style: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: .9), fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .04), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withValues(alpha: .08))),
            child: const Text('Generate Full Summary', style: TextStyle(color: DashboardColors.onSurface, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Future Insights ───────────────────────────────────────────────────────────

class _FutureInsights extends StatelessWidget {
  const _FutureInsights({required this.tasks});
  final List<ArchivedTask> tasks;

  @override
  Widget build(BuildContext context) {
    final recent = tasks.where((t) => t.archivedAt != null && DateTime.now().difference(t.archivedAt!).inDays <= 7).length;
    final estimated = (recent * 1.2).round();

    return ArchiveGlassCard(
      padding: const EdgeInsets.all(18),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.online_prediction_rounded, color: DashboardColors.secondary, size: 15),
            SizedBox(width: 7),
            Text('Future Insights', style: TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          _FiRow(label: 'Est. Archives Next Week', value: '$estimated Tasks', color: DashboardColors.secondary),
          const SizedBox(height: 10),
          const _FiRow(label: 'Likely Restores', value: '6 Tasks', color: DashboardColors.primary),
          const SizedBox(height: 10),
          const _FiRow(label: 'Potential Duplicates', value: '3 Tasks', color: Color(0xFFFFB020)),
        ],
      ),
    );
  }
}

class _FiRow extends StatelessWidget {
  const _FiRow({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12))),
        Text(value, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 12, fontWeight: FontWeight.w700)),
      ]);
}

// ── Tag Cloud ─────────────────────────────────────────────────────────────────

class _TagCloud extends StatelessWidget {
  const _TagCloud({required this.tasks, required this.tags});
  final List<ArchivedTask> tasks;
  final List<TagModel> tags;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final t in tasks) {
      for (final id in t.tagIds) { counts[id] = (counts[id] ?? 0) + 1; }
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(15).toList();
    final maxC = top.isEmpty ? 1 : top.first.value;

    return ArchiveGlassCard(
      padding: const EdgeInsets.all(18),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.label_rounded, color: Color(0xFF06B6D4), size: 15),
            SizedBox(width: 7),
            Text('Tag Cloud', style: TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          if (top.isEmpty)
            Text('No tags', style: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: .8), fontSize: 12))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: top.map((e) {
                final tag = tags.where((t) => t.id == e.key).firstOrNull;
                final name = tag?.name ?? 'Unknown';
                final size = 10.0 + (e.value / maxC) * 7.0;
                final alpha = 0.5 + (e.value / maxC) * 0.5;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withValues(alpha: alpha * 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: alpha * 0.28)),
                  ),
                  child: Text('#$name', style: TextStyle(color: const Color(0xFF06B6D4).withValues(alpha: alpha), fontSize: size, fontWeight: FontWeight.w700)),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ── Restore Feed ──────────────────────────────────────────────────────────────

class _RestoreFeed extends ConsumerWidget {
  const _RestoreFeed({required this.tasks, required this.users});
  final List<ArchivedTask> tasks;
  final List<UserProfileModel> users;

  String _ago(DateTime? d) {
    if (d == null) return '—';
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(restoreActivityProvider);
    final top = events.take(5).toList();

    return ArchiveGlassCard(
      padding: const EdgeInsets.all(18),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.restore_rounded, color: DashboardColors.primary, size: 15),
            SizedBox(width: 7),
            Text('Restore Activity', style: TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          if (top.isEmpty)
            Text('No restore activity yet', style: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: .8), fontSize: 12))
          else
            ...top.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: DashboardColors.success.withValues(alpha: .6)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(color: DashboardColors.onSurface, fontSize: 12),
                      children: [
                        TextSpan(text: e.userName, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const TextSpan(text: ' restored '),
                        TextSpan(text: e.taskTitle, style: const TextStyle(color: DashboardColors.success, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Text(_ago(e.timestamp), style: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: .7), fontSize: 11)),
                ])),
              ]),
            )),
        ],
      ),
    );
  }
}

// ── Audit Log ─────────────────────────────────────────────────────────────────

class _AuditLog extends StatelessWidget {
  const _AuditLog({required this.tasks, required this.users});
  final List<ArchivedTask> tasks;
  final List<UserProfileModel> users;

  String _ago(DateTime? d) {
    if (d == null) return '—';
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  String _ownerName(String? userId) {
    if (userId == null) return 'Unknown';
    final u = users.where((u) => u.id == userId).firstOrNull;
    return u?.fullName ?? u?.username ?? 'User';
  }

  @override
  Widget build(BuildContext context) {
    // Build audit entries from real task events: archived, completed, deleted
    final entries = <(IconData, String, String, DateTime, Color)>[];

    for (final t in tasks) {
      if (t.archivedAt != null) {
        entries.add((Icons.archive_rounded, 'Archived "${t.title}"', _ownerName(t.userId), t.archivedAt!, DashboardColors.primary));
      }
      if (t.completedAt != null) {
        entries.add((Icons.check_circle_outline_rounded, 'Completed "${t.title}"', _ownerName(t.userId), t.completedAt!, DashboardColors.success));
      }
      if (t.deletedAt != null) {
        entries.add((Icons.delete_outline_rounded, 'Deleted "${t.title}"', _ownerName(t.userId), t.deletedAt!, DashboardColors.error));
      }
    }
    entries.sort((a, b) => b.$4.compareTo(a.$4));
    final top = entries.take(6).toList();

    return ArchiveGlassCard(
      padding: const EdgeInsets.all(18),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.receipt_long_rounded, color: Color(0xFFFFB020), size: 15),
            SizedBox(width: 7),
            Text('Audit Log', style: TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          if (top.isEmpty)
            Text('No audit entries', style: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: .8), fontSize: 12))
          else
            ...top.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(
                  width: 28, height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: e.$5.withValues(alpha: .12), borderRadius: BorderRadius.circular(6)),
                  child: Icon(e.$1, color: e.$5, size: 14),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('${e.$3} · ${_ago(e.$4)}', style: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: .7), fontSize: 10)),
                ])),
              ]),
            )),
        ],
      ),
    );
  }
}

// ── Storage Dashboard ─────────────────────────────────────────────────────────

class _StorageDashboard extends StatelessWidget {
  const _StorageDashboard({required this.tasks});
  final List<ArchivedTask> tasks;

  @override
  Widget build(BuildContext context) {
    final total = tasks.length;
    final withDesc = tasks.where((t) => (t.description ?? '').isNotEmpty).length;

    return ArchiveGlassCard(
      padding: const EdgeInsets.all(18),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.storage_rounded, color: DashboardColors.success, size: 15),
            SizedBox(width: 7),
            Text('Storage Dashboard', style: TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          _StRow(label: 'Archived Tasks', value: '$total'),
          const SizedBox(height: 8),
          _StRow(label: 'Storage Used', value: '${(total * 0.12).toStringAsFixed(1)} MB'),
          const SizedBox(height: 8),
          _StRow(label: 'Avg Task Size', value: '0.12 KB'),
          const SizedBox(height: 8),
          _StRow(label: 'With Description', value: '$withDesc'),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (total * 0.12 / 100).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: .06),
              valueColor: const AlwaysStoppedAnimation(DashboardColors.success),
            ),
          ),
          const SizedBox(height: 6),
          Text('${(100 - total * 0.12).toStringAsFixed(0)} MB remaining of 100 MB', style: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: .7), fontSize: 10)),
        ],
      ),
    );
  }
}

class _StRow extends StatelessWidget {
  const _StRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12))),
        Text(value, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 12, fontWeight: FontWeight.w700)),
      ]);
}

// ── Activity Heatmap ──────────────────────────────────────────────────────────

class _ActivityHeatmap extends StatelessWidget {
  const _ActivityHeatmap({required this.tasks});
  final List<ArchivedTask> tasks;

  @override
  Widget build(BuildContext context) {
    final counts = <int, int>{};
    final now = DateTime.now();
    for (final t in tasks) {
      if (t.archivedAt != null) {
        final d = now.difference(t.archivedAt!).inDays;
        if (d < 91) counts[d] = (counts[d] ?? 0) + 1;
      }
    }
    final maxC = counts.values.fold(0, (a, b) => a > b ? a : b);

    return ArchiveGlassCard(
      padding: const EdgeInsets.all(20),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF6B6B), size: 15),
            SizedBox(width: 7),
            Text('Archive Activity Heatmap', style: TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
            Spacer(),
            Text('Last 13 weeks', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 11)),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            height: 88,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 3, crossAxisSpacing: 3),
              itemCount: 91,
              itemBuilder: (_, i) {
                final c = counts[i] ?? 0;
                final intensity = maxC == 0 ? 0.0 : (c / maxC).clamp(0.0, 1.0);
                return Tooltip(
                  message: c == 0 ? 'No activity' : '$c archived',
                  child: Container(
                    decoration: BoxDecoration(
                      color: c == 0 ? Colors.white.withValues(alpha: .04) : DashboardColors.primary.withValues(alpha: 0.2 + intensity * 0.8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            const Text('Less', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 10)),
            const SizedBox(width: 6),
            ...[.2, .4, .6, .8, 1.0].map((v) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(width: 10, height: 10, decoration: BoxDecoration(color: DashboardColors.primary.withValues(alpha: v), borderRadius: BorderRadius.circular(2))),
            )),
            const SizedBox(width: 6),
            const Text('More', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 10)),
          ]),
        ],
      ),
    );
  }
}
