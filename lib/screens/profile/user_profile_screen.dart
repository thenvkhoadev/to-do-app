import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/widgets/profile/profile_activity_card.dart';
import 'package:to_do_app/widgets/profile/profile_glass_container.dart';
import 'package:to_do_app/widgets/profile/profile_header.dart';
import 'package:to_do_app/widgets/profile/profile_setting_tile.dart';
import 'package:to_do_app/widgets/profile/profile_stats_card.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final username = (user?.fullName?.trim().isNotEmpty ?? false) ? user!.fullName!.trim() : user?.username ?? 'Nexus Operator';
    final email = user?.email ?? 'precision@nexus.ai';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 1024;
        final isTablet = width >= 720;
        final padding = isDesktop ? 40.0 : 16.0;

        return ColoredBox(
          color: const Color(0xFF0D1322),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(padding, isDesktop ? 30 : 20, padding, isDesktop ? 48 : 132),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfileHeader(username: username, email: email, avatarUrl: user?.avatarUrl, compact: !isDesktop),
                    const SizedBox(height: 22),
                    _StatsGrid(isDesktop: isDesktop, isTablet: isTablet),
                    const SizedBox(height: 22),
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(flex: 7, child: _ActivityColumn()),
                          const SizedBox(width: 22),
                          Expanded(flex: 5, child: _SettingsColumn(onLogout: () => ref.read(authControllerProvider.notifier).signOut())),
                        ],
                      )
                    else
                      Column(
                        children: [
                          const _ActivityColumn(),
                          const SizedBox(height: 22),
                          _SettingsColumn(onLogout: () => ref.read(authControllerProvider.notifier).signOut()),
                        ],
                      ),
                    const SizedBox(height: 22),
                    const _ProfileFooter(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.isDesktop, required this.isTablet});

  final bool isDesktop;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final columns = isDesktop ? 4 : (isTablet ? 2 : 2);

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: isDesktop ? 1.32 : 0.96,
      children: const [
        ProfileStatsCard(label: 'Tasks completed', value: '128', icon: Icons.task_alt_rounded, caption: '+18 this week', color: NexusColors.primary, progress: 0.82),
        ProfileStatsCard(label: 'Focus hours', value: '46h', icon: Icons.timer_rounded, caption: 'Deep work streak', color: NexusColors.secondary, progress: 0.68),
        ProfileStatsCard(label: 'AI usage', value: '2.4k', icon: Icons.auto_awesome_rounded, caption: 'Tokens optimized', color: NexusColors.tertiary, progress: 0.74),
        ProfileStatsCard(label: 'Productivity', value: '91%', icon: Icons.speed_rounded, caption: 'Top 8%', color: NexusColors.warning, progress: 0.91),
      ],
    );
  }
}

class _ActivityColumn extends StatelessWidget {
  const _ActivityColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ProductivityHeatmap(),
        SizedBox(height: 22),
        ProfileActivityCard(
          title: 'Workspace activity',
          icon: Icons.bolt_rounded,
          color: NexusColors.secondary,
          items: [
            ProfileActivityItem(title: 'Recent projects', subtitle: 'Design system sprint moved into focused execution.', icon: Icons.folder_open_rounded, trailing: '4 active'),
            ProfileActivityItem(title: 'AI insights', subtitle: 'Context switching is down 24% after schedule batching.', icon: Icons.psychology_rounded, trailing: 'New'),
            ProfileActivityItem(title: 'Calendar sync', subtitle: 'Three focus windows reserved for tomorrow.', icon: Icons.calendar_month_rounded, trailing: 'Synced'),
            ProfileActivityItem(title: 'Workspace activity', subtitle: 'Team handoff brief generated with Nexus AI.', icon: Icons.groups_rounded, trailing: '2m ago'),
          ],
        ),
      ],
    );
  }
}

class _ProductivityHeatmap extends StatelessWidget {
  const _ProductivityHeatmap();

  static const _values = [
    .2, .45, .8, .55, .1, .65, .3,
    .7, .35, .5, .9, .25, .4, .72,
    .18, .58, .76, .44, .88, .62, .34,
    .52, .82, .68, .21, .46, .93, .57,
    .32, .61, .74, .16, .43, .86, .66,
    .78, .48, .28, .91, .36, .59, .81,
  ];

  @override
  Widget build(BuildContext context) {
    return ProfileGlassContainer(
      glowColor: NexusColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(child: ProfileSectionLabel(label: 'Productivity rhythm', icon: Icons.grid_view_rounded, color: NexusColors.primary)),
              Text('Last 6 weeks', style: TextStyle(color: NexusColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 22),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var week = 0; week < 6; week++) ...[
                  Column(
                    children: [
                      for (var day = 0; day < 7; day++)
                        Padding(
                          padding: const EdgeInsets.all(3),
                          child: _HeatCell(value: _values[(week * 7) + day]),
                        ),
                    ],
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: const [
              Text('Less', style: TextStyle(color: NexusColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700)),
              SizedBox(width: 8),
              _LegendCell(alpha: 0.18),
              SizedBox(width: 5),
              _LegendCell(alpha: 0.38),
              SizedBox(width: 5),
              _LegendCell(alpha: 0.62),
              SizedBox(width: 5),
              _LegendCell(alpha: 0.9),
              SizedBox(width: 8),
              Text('More', style: TextStyle(color: NexusColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: NexusColors.primary.withValues(alpha: 0.10 + value * 0.55),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white.withValues(alpha: 0.045)),
      ),
    );
  }
}

class _LegendCell extends StatelessWidget {
  const _LegendCell({required this.alpha});

  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(width: 13, height: 13, decoration: BoxDecoration(color: NexusColors.primary.withValues(alpha: alpha), borderRadius: BorderRadius.circular(4)));
  }
}

class _SettingsColumn extends StatelessWidget {
  const _SettingsColumn({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileGlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ProfileSectionLabel(label: 'Settings', icon: Icons.tune_rounded, color: NexusColors.primary),
              SizedBox(height: 18),
              ProfileSettingTile(icon: Icons.person_outline_rounded, title: 'Account', subtitle: 'Profile, identity, workspace'),
              SizedBox(height: 10),
              ProfileSettingTile(icon: Icons.lock_outline_rounded, title: 'Security', subtitle: 'Passkeys and active sessions', color: NexusColors.secondary),
              SizedBox(height: 10),
              ProfileSettingTile(icon: Icons.notifications_none_rounded, title: 'Notifications', subtitle: 'Briefs, reminders, alerts', trailing: ProfileSwitchPill(enabled: true), color: NexusColors.tertiary),
              SizedBox(height: 10),
              ProfileSettingTile(icon: Icons.auto_awesome_rounded, title: 'AI Preferences', subtitle: 'Tone, memory, automations', trailing: ProfileSwitchPill(enabled: true), color: NexusColors.primary),
              SizedBox(height: 10),
              ProfileSettingTile(icon: Icons.credit_card_rounded, title: 'Billing', subtitle: 'Pro plan and invoices', color: NexusColors.warning),
              SizedBox(height: 10),
              ProfileSettingTile(icon: Icons.hub_rounded, title: 'Integrations', subtitle: 'Calendar, Slack, Linear', color: NexusColors.secondary),
            ],
          ),
        ),
        const SizedBox(height: 22),
        ProfileGlassContainer(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [NexusColors.primaryContainer.withValues(alpha: 0.72), const Color(0xFF6F00BE).withValues(alpha: 0.72)],
          ),
          glowColor: NexusColors.primaryContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 34),
              const SizedBox(height: 16),
              const Text('Pro Intelligence', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('2,420 AI actions optimized this month. Billing cycle resets in 12 days.', style: TextStyle(color: Colors.white.withValues(alpha: 0.78), height: 1.45)),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: 0.72,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 18),
              ProfileSettingTile(
                icon: Icons.logout_rounded,
                title: 'Log out',
                subtitle: 'End this secure session',
                color: NexusColors.error,
                onTap: onLogout,
                trailing: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileFooter extends StatelessWidget {
  const _ProfileFooter();

  @override
  Widget build(BuildContext context) {
    return ProfileGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      radius: 24,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 18,
        runSpacing: 10,
        children: const [
          Text('Nexus AI v1.0.0', style: TextStyle(color: NexusColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w800)),
          Text('Privacy · Terms · Support', style: TextStyle(color: NexusColors.primary, fontSize: 12, fontWeight: FontWeight.w900)),
          Text('© 2026 TaskFlow AI', style: TextStyle(color: NexusColors.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}
