import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/tasks/domain/entities/task_board_item.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/tasks/data/models/task_attachment_model.dart';
import 'package:to_do_app/features/tasks/data/models/task_subtask_model.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskDetailsDesktopContent extends StatelessWidget {
  const TaskDetailsDesktopContent({
    required this.item,
    required this.onBack,
    super.key,
  });

  final TaskBoardItem item;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _AmbientGlows(),
        Column(
          children: [
            _TaskDetailsHeader(item: item, onBack: onBack),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 1100;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 110),
                    child:
                        wide
                            ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: _LeftColumn(item: item),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  flex: 5,
                                  child: _RightColumn(item: item),
                                ),
                              ],
                            )
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _LeftColumn(item: item),
                                const SizedBox(height: 32),
                                _RightColumn(item: item),
                              ],
                            ),
                  );
                },
              ),
            ),
          ],
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 28,
          child: _AiSuggestionDock(),
        ),
        const Positioned(right: 32, bottom: 32, child: _FloatingDetailsFab()),
        const Positioned(
          right: 104,
          bottom: 34,
          child: _CommandPaletteButton(),
        ),
      ],
    );
  }
}

class _TaskDetailsHeader extends StatelessWidget {
  const _TaskDetailsHeader({required this.item, required this.onBack});

  final TaskBoardItem item;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: DashboardColors.surface.withValues(alpha: .42),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: .08)),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: DashboardColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              _Pill(
                label: item.tags.isNotEmpty ? item.tags.first.toUpperCase() : 'GENERAL',
                color: item.priorityColor,
              ),
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DashboardColors.outlineVariant.withValues(alpha: .45),
                ),
              ),
              Text(
                'TASK-${item.id.length > 5 ? item.id.substring(0, 5).toUpperCase() : item.id.toUpperCase()}',
                style: const TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const _DeepWorkButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeftColumn extends StatelessWidget {
  const _LeftColumn({required this.item});
  final TaskBoardItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TaskHero(item: item),
        const SizedBox(height: 24),
        _TaskMetadataCards(item: item),
        const SizedBox(height: 16),
        const _TeamPresenceRow(),
        const SizedBox(height: 24),
        _SmartTabsSection(taskId: item.id),
        const SizedBox(height: 24),
        const _FocusHistoryChart(),
        const SizedBox(height: 24),
        _ContextualIntelligenceSection(taskId: item.id),
        const SizedBox(height: 24),
        const _ProductivityEnhancements(),
      ],
    );
  }
}

class _RightColumn extends StatelessWidget {
  const _RightColumn({required this.item});
  final TaskBoardItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AiAtomicExecutionPanel(progress: item.progress),
        const SizedBox(height: 16),
        const _SmartPriorityHeatmap(),
        const SizedBox(height: 16),
        const _LiveActivityTimeline(),
        const SizedBox(height: 24),
        const _StrategyVisualizationCard(),
      ],
    );
  }
}

class _TaskHero extends StatelessWidget {
  const _TaskHero({required this.item});
  final TaskBoardItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 34,
                  height: 1.16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.4,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const _FocusTimerWidget(),
          ],
        ),
        const SizedBox(height: 14),
        _AiInsightsCard(aiSuggestion: item.aiSuggestion),
        const SizedBox(height: 16),
        Text(
          item.description,
          style: const TextStyle(
            color: DashboardColors.onSurfaceVariant,
            fontSize: 18,
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        _ExpandableSubtasksSection(taskId: item.id),
      ],
    );
  }
}

class _TaskMetadataCards extends StatelessWidget {
  const _TaskMetadataCards({required this.item});
  final TaskBoardItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetadataCard(
            label: 'PRIORITY',
            value: item.priorityLabel,
            icon: Icons.error_rounded,
            color: item.priorityColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetadataCard(
            label: 'ESTIMATE',
            value: item.estimate.isNotEmpty ? item.estimate : 'No estimate',
            icon: Icons.timer_rounded,
            color: DashboardColors.onSurface,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetadataCard(
            label: 'STATUS',
            value: item.status.name.toUpperCase(),
            icon: Icons.info_outline_rounded,
            color: DashboardColors.tertiary,
          ),
        ),
      ],
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _HoverScale(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DashboardColors.surfaceHigh.withValues(alpha: .34),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusHistoryChart extends StatelessWidget {
  const _FocusHistoryChart();

  @override
  Widget build(BuildContext context) {
    const bars = [.40, .60, .30, .90, .55, .75, .45, .85, .25, .95];
    return _GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Focus History',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _LegendDot(color: DashboardColors.primary.withValues(alpha: .40)),
              const SizedBox(width: 8),
              const _LegendDot(color: DashboardColors.primary),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                bars.length,
                (index) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _ChartBar(
                      value: bars[index],
                      active: index == bars.length - 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Text(
                '14 Oct',
                style: TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              Spacer(),
              Text(
                'Today',
                style: TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  const _ChartBar({required this.value, required this.active});
  final double value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: Duration(milliseconds: active ? 900 : 650),
      curve: Curves.easeOutCubic,
      builder:
          (context, animated, _) => Tooltip(
            message:
                active ? '4.8h' : '${(animated * 4.8).toStringAsFixed(1)}h',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 150 * animated,
              decoration: BoxDecoration(
                color:
                    active
                        ? DashboardColors.primary
                        : DashboardColors.primary.withValues(alpha: .20),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                boxShadow:
                    active
                        ? [
                          BoxShadow(
                            color: DashboardColors.primary.withValues(
                              alpha: .28,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, -5),
                          ),
                        ]
                        : null,
              ),
            ),
          ),
    );
  }
}

class _ContextualIntelligenceSection extends ConsumerWidget {
  const _ContextualIntelligenceSection({required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentsAsync = ref.watch(taskAttachmentsProvider(taskId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(Icons.hub_rounded, color: DashboardColors.secondary, size: 20),
            SizedBox(width: 8),
            Text(
              'Contextual Intelligence',
              style: TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _KnowledgeGraphPreview(),
        const SizedBox(height: 14),
        const _ContextInsightCard(
          icon: Icons.mail_rounded,
          color: DashboardColors.primary,
          title: 'Fwd: AI Infrastructure Updates',
          subtitle:
              'From CTO - Contains critical cost metrics for next quarter...',
        ),
        const SizedBox(height: 12),
        const _ContextInsightCard(
          icon: Icons.description_rounded,
          color: DashboardColors.secondary,
          title: 'Q3 Competitive Landscape.pdf',
          subtitle: "AI-extracted summary: 12 references to 'NEXUS AI'...",
        ),
        const SizedBox(height: 12),
        attachmentsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (err, stack) => Text(
            'Error loading attachments: $err',
            style: const TextStyle(color: DashboardColors.error, fontSize: 12),
          ),
          data: (attachments) {
            if (attachments.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              children: [
                for (var i = 0; i < attachments.length; i += 2) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildAssetCard(attachments[i]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: i + 1 < attachments.length
                            ? _buildAssetCard(attachments[i + 1])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  if (i + 2 < attachments.length) const SizedBox(height: 12),
                ],
                const SizedBox(height: 12),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAssetCard(TaskAttachmentModel att) {
    final isImage = att.mimeType.startsWith('image/');
    final isPdf = att.mimeType == 'application/pdf';
    return _AssetCard(
      icon: isImage
          ? Icons.image_rounded
          : isPdf
              ? Icons.picture_as_pdf_rounded
              : Icons.insert_drive_file_rounded,
      title: att.fileName,
      color: isImage
          ? DashboardColors.primary
          : isPdf
              ? DashboardColors.secondary
              : DashboardColors.tertiary,
      imageUrl: isImage ? att.fileUrl : null,
    );
  }
}

class _ContextInsightCard extends StatelessWidget {
  const _ContextInsightCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => _HoverScale(
    child: _GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DashboardColors.surfaceHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.open_in_new_rounded,
            color: DashboardColors.onSurfaceVariant,
            size: 18,
          ),
        ],
      ),
    ),
  );
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({
    required this.icon,
    required this.title,
    required this.color,
    this.imageUrl,
  });
  final IconData icon;
  final String title;
  final Color color;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return _HoverScale(
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.all(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        color: Colors.black87,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: InteractiveViewer(
                        child: CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => Container(
                            padding: const EdgeInsets.all(24),
                            color: DashboardColors.surfaceLow,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, color: color, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: DashboardColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.black45,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: _GlassPanel(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 120,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Center(
                      child: Icon(icon, color: color, size: 36),
                    ),
                    placeholder: (_, __) => const Center(
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DashboardColors.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.open_in_new_rounded,
                        color: DashboardColors.onSurfaceVariant,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _HoverScale(
      child: _GlassPanel(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
              ),
              clipBehavior: Clip.antiAlias,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.open_in_new_rounded,
              color: DashboardColors.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductivityEnhancements extends StatelessWidget {
  const _ProductivityEnhancements();

  @override
  Widget build(BuildContext context) => Row(
    children: const [
      Expanded(
        child: _MiniStat(
          label: 'Session',
          value: '2h 30m',
          icon: Icons.timer_rounded,
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: _MiniStat(
          label: 'Team',
          value: '4 live',
          icon: Icons.groups_rounded,
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: _MiniStat(
          label: 'AI Score',
          value: '94%',
          icon: Icons.auto_graph_rounded,
        ),
      ),
    ],
  );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _GlassPanel(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Icon(icon, color: DashboardColors.tertiary, size: 20),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AiAtomicExecutionPanel extends StatelessWidget {
  const _AiAtomicExecutionPanel({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return _AiGlowContainer(
      child: Stack(
        children: [
          Positioned.fill(child: IgnorePointer(child: _ShimmerOverlay())),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DashboardColors.primary.withValues(alpha: .18),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: DashboardColors.primary,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Atomic Execution',
                      style: TextStyle(
                        color: DashboardColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _Pill(
                    label: 'AI GENERATED',
                    color: DashboardColors.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const _ExecutionProgressItem(
                label: 'Market Gap Analysis',
                value: 1,
              ),
              const _ExecutionProgressItem(
                label: 'Roadmap Delta Calculation',
                value: .75,
              ),
              const _ExecutionProgressItem(
                label: 'Resource Allocation Audit',
                value: .40,
                color: DashboardColors.secondary,
              ),
              const _ExecutionProgressItem(
                label: 'Technical Feasibility Check',
                value: 0,
              ),
              const _ExecutionProgressItem(
                label: 'Final Strategy Compilation',
                value: 0,
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.white.withValues(alpha: .08)),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Regenerate Execution Plan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExecutionProgressItem extends StatelessWidget {
  const _ExecutionProgressItem({
    required this.label,
    required this.value,
    this.color = DashboardColors.primary,
  });
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                color: value == 0 ? DashboardColors.onSurfaceVariant : color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder:
                (context, animated, _) => LinearProgressIndicator(
                  value: animated,
                  minHeight: 6,
                  backgroundColor: DashboardColors.surfaceHighest,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
          ),
        ),
      ],
    ),
  );
}

class _StrategyVisualizationCard extends StatelessWidget {
  const _StrategyVisualizationCard();

  @override
  Widget build(BuildContext context) {
    return _HoverScale(
      child: Container(
        height: 192,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.2,
            colors: [
              DashboardColors.tertiary.withValues(alpha: .22),
              DashboardColors.secondary.withValues(alpha: .10),
              DashboardColors.surfaceLowest,
            ],
          ),
        ),
        child: Stack(
          children: [
            for (var i = 0; i < 9; i++)
              Positioned(
                left: 32.0 + i * 42,
                top: 32.0 + (i.isEven ? 18 : 72),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DashboardColors.primary.withValues(alpha: .75),
                    boxShadow: [
                      BoxShadow(
                        color: DashboardColors.primary.withValues(alpha: .32),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
            const Positioned(
              left: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROJECT VISUALIZATION',
                    style: TextStyle(
                      color: DashboardColors.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Market Trend Synthesis',
                    style: TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeepWorkButton extends StatelessWidget {
  const _DeepWorkButton();

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: .55, end: 1),
    duration: const Duration(milliseconds: 1200),
    curve: Curves.easeOutCubic,
    builder:
        (context, value, child) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: DashboardColors.primary.withValues(
                  alpha: .14 + value * .08,
                ),
                blurRadius: 28,
              ),
            ],
          ),
          child: child,
        ),
    child: FilledButton.icon(
      onPressed:
          () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deep Work Mode activated')),
          ),
      icon: const Icon(Icons.track_changes_rounded),
      label: const Text('Enter Deep Work Mode'),
    ),
  );
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .03),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: child,
      ),
    ),
  );
}

class _AiGlowContainer extends StatelessWidget {
  const _AiGlowContainer({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(32),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .035),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: DashboardColors.primary.withValues(alpha: .22),
          ),
          boxShadow: [
            BoxShadow(
              color: DashboardColors.primary.withValues(alpha: .15),
              blurRadius: 34,
            ),
          ],
        ),
        child: child,
      ),
    ),
  );
}

class _HoverScale extends StatefulWidget {
  const _HoverScale({required this.child});
  final Widget child;
  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedScale(
      scale: _hovered ? 1.012 : 1,
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeOutCubic,
      child: widget.child,
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: .18)),
    ),
    child: Text(
      label.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    ),
  );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _ShimmerOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: -1, end: 1),
    duration: const Duration(seconds: 2),
    curve: Curves.easeInOut,
    builder:
        (context, value, _) => FractionalTranslation(
          translation: Offset(value, 0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: .04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
  );
}

class _AiInsightsCard extends StatelessWidget {
  const _AiInsightsCard({this.aiSuggestion});
  final String? aiSuggestion;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: .4, end: 1),
    duration: const Duration(milliseconds: 1000),
    curve: Curves.easeOutCubic,
    builder:
        (context, value, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                DashboardColors.primary.withValues(alpha: .18 * value),
                DashboardColors.secondary.withValues(alpha: .14),
                Colors.white.withValues(alpha: .03),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: DashboardColors.primary.withValues(alpha: .10 * value),
                blurRadius: 28,
              ),
            ],
          ),
          child: child,
        ),
    child: _GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: DashboardColors.tertiary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'AI Insights',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (aiSuggestion != null) ...[
            _InsightLine(aiSuggestion!),
            const SizedBox(height: 6),
          ],
          const _InsightLine('82% roadmap alignment'),
          const _InsightLine('Market volatility risk detected'),
          const _InsightLine('Suggested release window: Q1'),
          const _InsightLine('Resource allocation imbalance found'),
        ],
      ),
    ),
  );
}

class _InsightLine extends StatelessWidget {
  const _InsightLine(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: DashboardColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 13,
              height: 1.25,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TeamPresenceRow extends StatelessWidget {
  const _TeamPresenceRow();

  @override
  Widget build(BuildContext context) => _GlassPanel(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: const [
        _PresenceAvatar(label: 'A', color: DashboardColors.primary),
        _OverlapAvatar(label: 'M', color: DashboardColors.secondary),
        _OverlapAvatar(label: 'K', color: DashboardColors.tertiary),
        SizedBox(width: 14),
        Expanded(
          child: Text(
            '3 collaborators active • Alex is typing • 12 live viewers',
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _PulseDot(),
      ],
    ),
  );
}

class _PresenceAvatar extends StatelessWidget {
  const _PresenceAvatar({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      CircleAvatar(
        radius: 15,
        backgroundColor: color.withValues(alpha: .18),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const Positioned(right: -1, bottom: -1, child: _OnlineDot()),
    ],
  );
}

class _OverlapAvatar extends StatelessWidget {
  const _OverlapAvatar({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: const Offset(-8, 0),
    child: _PresenceAvatar(label: label, color: color),
  );
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();
  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF7CFFB2),
      border: Border.all(color: DashboardColors.background, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF7CFFB2).withValues(alpha: .35),
          blurRadius: 8,
        ),
      ],
    ),
  );
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: .4, end: 1),
    duration: const Duration(milliseconds: 900),
    curve: Curves.easeOutCubic,
    builder:
        (context, value, _) => Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DashboardColors.primary.withValues(alpha: value),
            boxShadow: [
              BoxShadow(
                color: DashboardColors.primary.withValues(alpha: .35 * value),
                blurRadius: 14,
              ),
            ],
          ),
        ),
  );
}class _SmartTabsSection extends ConsumerWidget {
  const _SmartTabsSection({required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 5,
      child: _GlassPanel(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TabBar(
              isScrollable: true,
              dividerColor: Colors.transparent,
              splashBorderRadius: BorderRadius.all(Radius.circular(999)),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 6,
              ),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(999)),
                color: Color(0x2E8083FF),
                border: Border.fromBorderSide(
                  BorderSide(color: DashboardColors.primary),
                ),
              ),
              labelColor: DashboardColors.primary,
              unselectedLabelColor: DashboardColors.onSurfaceVariant,
              labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Notes'),
                Tab(text: 'Activity'),
                Tab(text: 'Files'),
                Tab(text: 'AI'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 88,
              child: TabBarView(
                children: [
                  const _TabCopy(
                    'Roadmap context, key blockers, and active execution plan are synced.',
                  ),
                  const _TabCopy(
                    'AI notes updated from meeting summary and linked documents.',
                  ),
                  const _TabCopy('4 updates in the last 30 minutes.'),
                  _FilesTab(taskId: taskId),
                  const _TabCopy('AI recommends splitting into 4 milestones.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilesTab extends ConsumerWidget {
  const _FilesTab({required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentsAsync = ref.watch(taskAttachmentsProvider(taskId));

    return attachmentsAsync.when(
      loading: () => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (err, stack) => Text('Error: $err', style: const TextStyle(fontSize: 12, color: DashboardColors.error)),
      data: (attachments) {
        if (attachments.isEmpty) {
          return const Center(
            child: Text(
              'No files attached',
              style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 13),
            ),
          );
        }
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: attachments.length,
          itemBuilder: (context, index) {
            final att = attachments[index];
            final isImage = att.mimeType.startsWith('image/');
            final isPdf = att.mimeType == 'application/pdf';
            final ext = att.fileName.split('.').last.toUpperCase();
            final sizeStr = '$ext Document';

            if (isImage) {
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.all(16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              color: Colors.black87,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: InteractiveViewer(
                              child: CachedNetworkImage(
                                imageUrl: att.fileUrl,
                                fit: BoxFit.contain,
                                errorWidget: (_, __, ___) => Container(
                                  padding: const EdgeInsets.all(24),
                                  color: DashboardColors.surfaceLow,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.image_rounded,
                                        color: DashboardColors.primary,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        att.fileName,
                                        style: const TextStyle(
                                          color: DashboardColors.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: CircleAvatar(
                              backgroundColor: Colors.black45,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .06),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 68,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: att.fileUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.image_rounded,
                                color: DashboardColors.primary,
                                size: 24,
                              ),
                            ),
                            placeholder: (_, __) => const Center(
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              att.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: DashboardColors.onSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              sizeStr,
                              style: const TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Container(
              margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .06),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (isPdf
                              ? DashboardColors.secondary
                              : DashboardColors.tertiary)
                          .withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isPdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.insert_drive_file_rounded,
                      color: isPdf
                          ? DashboardColors.secondary
                          : DashboardColors.tertiary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        att.fileName,
                        style: const TextStyle(
                          color: DashboardColors.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        sizeStr,
                        style: const TextStyle(
                          color: DashboardColors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TabCopy extends StatelessWidget {
  const _TabCopy(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: DashboardColors.onSurfaceVariant,
        height: 1.4,
      ),
    ),
  );
}

class _ExpandableSubtasksSection extends ConsumerStatefulWidget {
  const _ExpandableSubtasksSection({required this.taskId});
  final String taskId;

  @override
  ConsumerState<_ExpandableSubtasksSection> createState() => _ExpandableSubtasksSectionState();
}

class _ExpandableSubtasksSectionState extends ConsumerState<_ExpandableSubtasksSection> {
  final _textController = TextEditingController();
  bool _isAdding = false;
  bool _isGenerating = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _addSubtask(String title) async {
    if (title.trim().isEmpty) return;
    try {
      final subtask = TaskSubtaskModel(
        id: '',
        taskId: widget.taskId,
        title: title.trim(),
        isDone: false,
      );
      await ref.read(subtaskDataSourceProvider).createSubtask(subtask);
      ref.invalidate(taskSubtasksProvider(widget.taskId));
      _textController.clear();
      setState(() {
        _isAdding = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add subtask: $e')),
      );
    }
  }

  Future<void> _toggleSubtask(TaskSubtaskModel subtask, bool value) async {
    try {
      await ref
          .read(subtaskDataSourceProvider)
          .updateSubtask(subtask.id, {'is_done': value});
      ref.invalidate(taskSubtasksProvider(widget.taskId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update subtask: $e')),
      );
    }
  }

  Future<void> _deleteSubtask(String id) async {
    try {
      await ref.read(subtaskDataSourceProvider).deleteSubtask(id);
      ref.invalidate(taskSubtasksProvider(widget.taskId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete subtask: $e')),
      );
    }
  }

  Future<void> _generateWithAi() async {
    setState(() {
      _isGenerating = true;
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    try {
      final suggested = [
        'Review architecture guidelines',
        'Write integration test suite',
        'Verify schema compatibility',
      ];
      final datasource = ref.read(subtaskDataSourceProvider);
      final subtasks = suggested
          .map((t) => TaskSubtaskModel(
                id: '',
                taskId: widget.taskId,
                title: t,
                isDone: false,
              ))
          .toList();
      await datasource.insertMultipleSubtasks(subtasks);
      ref.invalidate(taskSubtasksProvider(widget.taskId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate subtasks: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtasksAsync = ref.watch(taskSubtasksProvider(widget.taskId));

    return _GlassPanel(
      padding: const EdgeInsets.all(20),
      child: subtasksAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
        error: (err, stack) => Text(
          'Error loading subtasks: $err',
          style: const TextStyle(color: DashboardColors.error, fontSize: 13),
        ),
        data: (subtasks) {
          final doneCount = subtasks.where((s) => s.isDone).length;
          final totalCount = subtasks.length;
          final progress = totalCount > 0 ? doneCount / totalCount : 0.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'SUBTASKS',
                    style: TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Spacer(),
                  if (totalCount > 0) ...[
                    Text(
                      '$doneCount of $totalCount completed (${(progress * 100).round()}%)',
                      style: const TextStyle(
                        color: DashboardColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (_isGenerating)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  else
                    TextButton.icon(
                      onPressed: _generateWithAi,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 14, color: DashboardColors.primary),
                      label: const Text(
                        'Generate with AI',
                        style: TextStyle(
                          color: DashboardColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (totalCount > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: DashboardColors.surfaceHighest,
                    valueColor: const AlwaysStoppedAnimation(
                      DashboardColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (subtasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No subtasks',
                    style: TextStyle(
                      color: DashboardColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: subtasks.length,
                  itemBuilder: (context, index) {
                    final item = subtasks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _toggleSubtask(item, !item.isDone),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: item.isDone
                                      ? DashboardColors.primary.withValues(alpha: .14)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: item.isDone ? DashboardColors.primary : DashboardColors.outline,
                                  ),
                                ),
                                child: item.isDone
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: DashboardColors.primary,
                                        size: 14,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                color: item.isDone
                                    ? DashboardColors.onSurfaceVariant
                                    : DashboardColors.onSurface,
                                decoration: item.isDone ? TextDecoration.lineThrough : null,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            color: DashboardColors.outline.withValues(alpha: .5),
                            onPressed: () => _deleteSubtask(item.id),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 4),
              if (_isAdding)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        autofocus: true,
                        style: const TextStyle(fontSize: 14, color: DashboardColors.onSurface),
                        decoration: const InputDecoration(
                          hintText: 'Enter subtask...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: DashboardColors.outline),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                        onSubmitted: _addSubtask,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_rounded, color: DashboardColors.primary, size: 18),
                      onPressed: () => _addSubtask(_textController.text),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: DashboardColors.error, size: 18),
                      onPressed: () {
                        setState(() {
                          _isAdding = false;
                          _textController.clear();
                        });
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isAdding = true;
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Row(
                      children: const [
                        Icon(Icons.add_rounded, color: DashboardColors.outline, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Add another subtask...',
                          style: TextStyle(
                            color: DashboardColors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _KnowledgeGraphPreview extends StatelessWidget {
  const _KnowledgeGraphPreview();
  @override
  Widget build(BuildContext context) => _GlassPanel(
    padding: const EdgeInsets.all(16),
    child: SizedBox(
      height: 118,
      child: Stack(
        children: const [
          _GraphLine(left: 46, top: 34, width: 130),
          _GraphLine(left: 164, top: 66, width: 110),
          _GraphNode(
            left: 18,
            top: 40,
            label: 'Docs',
            color: DashboardColors.primary,
          ),
          _GraphNode(
            left: 142,
            top: 18,
            label: 'Tasks',
            color: DashboardColors.secondary,
          ),
          _GraphNode(
            left: 246,
            top: 72,
            label: 'Q4',
            color: DashboardColors.tertiary,
          ),
          Positioned(
            left: 12,
            bottom: 0,
            child: Text(
              'AI mapped 9 relationships across docs, tasks, and roadmap risks.',
              style: TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _GraphNode extends StatelessWidget {
  const _GraphNode({
    required this.left,
    required this.top,
    required this.label,
    required this.color,
  });
  final double left;
  final double top;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .22)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .18), blurRadius: 18),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _GraphLine extends StatelessWidget {
  const _GraphLine({
    required this.left,
    required this.top,
    required this.width,
  });
  final double left;
  final double top;
  final double width;
  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    child: Container(
      width: width,
      height: 1.2,
      color: DashboardColors.primary.withValues(alpha: .18),
    ),
  );
}

class _SmartPriorityHeatmap extends StatelessWidget {
  const _SmartPriorityHeatmap();
  @override
  Widget build(BuildContext context) => _GlassPanel(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Priority Heatmap',
          style: TextStyle(
            color: DashboardColors.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 12),
        _HeatRow(label: 'High', value: .82, color: DashboardColors.error),
        _HeatRow(label: 'Medium', value: .58, color: DashboardColors.secondary),
        _HeatRow(label: 'Low', value: .28, color: DashboardColors.tertiary),
      ],
    ),
  );
}

class _HeatRow extends StatelessWidget {
  const _HeatRow({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: const TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: const Duration(milliseconds: 700),
                builder:
                    (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      backgroundColor: DashboardColors.surfaceHighest,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveActivityTimeline extends StatelessWidget {
  const _LiveActivityTimeline();
  @override
  Widget build(BuildContext context) => _GlassPanel(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Live Activity',
          style: TextStyle(
            color: DashboardColors.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 14),
        _ActivityLine('Alex updated roadmap'),
        _ActivityLine('AI summarized PDF'),
        _ActivityLine('Deadline modified'),
        _ActivityLine('New document attached'),
      ],
    ),
  );
}

class _ActivityLine extends StatelessWidget {
  const _ActivityLine(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        const _PulseDot(),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _FocusTimerWidget extends StatelessWidget {
  const _FocusTimerWidget();
  @override
  Widget build(BuildContext context) => _GlassPanel(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(
            value: .68,
            strokeWidth: 3,
            color: DashboardColors.primary,
            backgroundColor: DashboardColors.surfaceHighest,
          ),
        ),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '45:22 Focus Session',
              style: TextStyle(
                color: DashboardColors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Streak 6 • Score 94',
              style: TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _AiSuggestionDock extends StatelessWidget {
  const _AiSuggestionDock();
  @override
  Widget build(BuildContext context) => Center(
    child: _GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: DashboardColors.secondary,
            size: 18,
          ),
          const SizedBox(width: 10),
          const Text(
            'AI Suggestion: ',
            style: TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Text(
            'Split strategy review into 4 milestones',
            style: TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 14),
          TextButton(onPressed: () {}, child: const Text('Apply')),
          TextButton(onPressed: () {}, child: const Text('Dismiss')),
        ],
      ),
    ),
  );
}

class _CommandPaletteButton extends StatelessWidget {
  const _CommandPaletteButton();
  @override
  Widget build(BuildContext context) => _GlassPanel(
    padding: EdgeInsets.zero,
    child: SizedBox(
      width: 52,
      height: 52,
      child: Center(
        child: Text(
          '⌘K',
          style: TextStyle(
            color: DashboardColors.primary,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: DashboardColors.primary.withValues(alpha: .45),
                blurRadius: 16,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FloatingDetailsFab extends StatelessWidget {
  const _FloatingDetailsFab();
  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: DashboardColors.primary,
      boxShadow: [
        BoxShadow(
          color: DashboardColors.primary.withValues(alpha: .24),
          blurRadius: 28,
        ),
      ],
    ),
    child: const Icon(
      Icons.add_rounded,
      color: DashboardColors.onPrimaryContainer,
    ),
  );
}

class _AmbientGlows extends StatelessWidget {
  const _AmbientGlows();
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        top: 120,
        right: -100,
        child: _Glow(color: DashboardColors.primary.withValues(alpha: .11)),
      ),
      Positioned(
        bottom: 120,
        left: -120,
        child: _Glow(color: DashboardColors.secondary.withValues(alpha: .10)),
      ),
    ],
  );
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 280,
    height: 280,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: 110, spreadRadius: 50)],
    ),
  );
}
