import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';

// ─────────────────────────────────────────────
// NexusColors (inline – no external dependency)
// ─────────────────────────────────────────────
abstract class NexusColors {
  static const Color primary = Color(0xFFC0C1FF);
  static const Color secondary = Color(0xFFDDB7FF);
  static const Color tertiary = Color(0xFFADC6FF);
  static const Color background = Color(0xFF0D1322);
  static const Color surface = Color(0xFF0D1322);
  static const Color surfaceContainer = Color(0xFF191F2F);
  static const Color surfaceContainerLow = Color(0xFF151B2B);
  static const Color surfaceContainerHigh = Color(0xFF242A3A);
  static const Color surfaceContainerHighest = Color(0xFF2F3445);
  static const Color surfaceVariant = Color(0xFF2F3445);
  static const Color primaryContainer = Color(0xFF8083FF);
  static const Color secondaryContainer = Color(0xFF6F00BE);
  static const Color onSurface = Color(0xFFDDE2F8);
  static const Color onSurfaceVariant = Color(0xFFC7C4D7);
  static const Color onPrimary = Color(0xFF1000A9);
  static const Color onPrimaryFixed = Color(0xFF07006C);
  static const Color error = Color(0xFFFFB4AB);
  static const Color outlineVariant = Color(0xFF464554);
  static const Color warning = Color(0xFFFFB951);
}

// ─────────────────────────────────────────────
// Main Entry
// ─────────────────────────────────────────────
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = _ProfileVM.from(ref.watch(userProfileProvider).valueOrNull);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        return isDesktop
            ? _DesktopProfileScreen(vm: vm)
            : _MobileProfileScreen(vm: vm);
      },
    );
  }
}

/// View model that merges the database [UserProfileModel] with Supabase auth
/// metadata as a fallback, so the UI never renders mock data.
class _ProfileVM {
  const _ProfileVM({
    required this.name,
    required this.username,
    required this.email,
    required this.bio,
    required this.avatarUrl,
    required this.tier,
    required this.role,
    required this.joinedLabel,
    required this.focusScore,
    required this.streakDays,
    required this.focusHours,
    required this.model,
  });

  final String name;
  final String username;
  final String email;
  final String bio;
  final String avatarUrl;
  final String tier;
  final String role;
  final String joinedLabel;
  final int focusScore;
  final int streakDays;
  final int focusHours;
  final UserProfileModel? model;

  String get initial =>
      name.trim().isEmpty ? '?' : name.characters.first.toUpperCase();

  String get tierLabel => '${tier.toUpperCase()} Member';

  String get roleLabel {
    if (role.isEmpty) return 'User';
    return role[0].toUpperCase() + role.substring(1);
  }

  /// Identity checklist used by the Profile Completion card. Driven by the
  /// resolved (database-backed) identity values that the UI actually shows.
  List<_CompletionItem> get completionItems => [
        _CompletionItem('Avatar', avatarUrl.trim().isNotEmpty),
        _CompletionItem('Full Name', name.trim().isNotEmpty && name != 'User'),
        _CompletionItem('Username', username.trim().isNotEmpty),
        _CompletionItem('Email', email.trim().isNotEmpty && email != 'No email'),
        _CompletionItem('Bio', bio.trim().isNotEmpty),
      ];

  int get completionPercent {
    final done = completionItems.where((i) => i.done).length;
    return ((done / completionItems.length) * 100).round();
  }

  // ── Analytics fields (Sections 6-13), sourced from the database model ──
  int get totalTasks => model?.totalTasks ?? 0;
  int get completedTasks => model?.completedTasks ?? 0;

  /// completionRate = (completedTasks / totalTasks) * 100.
  int get taskCompletionRate =>
      totalTasks == 0 ? 0 : ((completedTasks / totalTasks) * 100).round();

  int get deepWorkPercent => model?.deepWorkPercent ?? 0;
  int get adminPercent => model?.adminPercent ?? 0;
  int get learningPercent => model?.learningPercent ?? 0;

  /// Section 7 — Work Distribution segments sourced from the database model.
  List<_WorkSegment> get workDistribution => [
        _WorkSegment('Deep Work', deepWorkPercent, NexusColors.primary),
        _WorkSegment('Admin', adminPercent, NexusColors.secondary),
        _WorkSegment('Learning', learningPercent, NexusColors.tertiary),
      ];

  String get themeMode => (model?.themeMode ?? 'dark').trim();
  bool get isDarkMode => themeMode.toLowerCase() == 'dark';
  bool get notificationsEnabled => model?.notificationsEnabled ?? true;
  bool get privacyMode => model?.privacyMode ?? false;

  DateTime? get createdAt => model?.createdAt;
  DateTime? get updatedAt => model?.updatedAt;

  /// Stable account identifier (users.id). Surfaced in the Security Center.
  String get accountId => model?.id ?? '';

  /// Section 13 — Activity Timeline events derived from created_at/updated_at.
  List<_TimelineEvent> get activityTimeline {
    final created = createdAt;
    final updated = updatedAt;
    final events = <_TimelineEvent>[
      _TimelineEvent(
        icon: Icons.person_add_rounded,
        title: 'Account Created',
        timestamp: created,
        accent: NexusColors.primary,
      ),
      _TimelineEvent(
        icon: Icons.edit_rounded,
        title: 'Last Profile Update',
        timestamp: updated,
        accent: NexusColors.secondary,
      ),
      _TimelineEvent(
        icon: Icons.bolt_rounded,
        title: 'Recent Activity',
        timestamp: updated ?? created,
        accent: NexusColors.tertiary,
      ),
    ];
    return events;
  }

  /// Achievements derived from streak/task/focus thresholds.
  List<_Achievement> get achievements => [
        _Achievement(
          icon: Icons.local_fire_department_rounded,
          title: '7 Day Streak',
          unlocked: streakDays >= 7,
          progressLabel: '$streakDays / 7 days',
          accent: NexusColors.secondary,
        ),
        _Achievement(
          icon: Icons.whatshot_rounded,
          title: '30 Day Streak',
          unlocked: streakDays >= 30,
          progressLabel: '$streakDays / 30 days',
          accent: NexusColors.secondary,
        ),
        _Achievement(
          icon: Icons.task_alt_rounded,
          title: '100 Tasks Completed',
          unlocked: completedTasks >= 100,
          progressLabel: '$completedTasks / 100 tasks',
          accent: NexusColors.primary,
        ),
        _Achievement(
          icon: Icons.schedule_rounded,
          title: '100 Focus Hours',
          unlocked: focusHours >= 100,
          progressLabel: '${focusHours}h / 100h',
          accent: NexusColors.tertiary,
        ),
      ];

  /// Synthetic 7-point weekly focus trend derived from current focus_score,
  /// focus_hours and completed_tasks. Deterministic (seeded by the values) so
  /// the chart is stable between rebuilds.
  List<double> get weeklyFocusSeries {
    final base = focusScore.toDouble();
    if (base == 0) return List.filled(7, 0);
    final seed = focusHours + completedTasks + streakDays;
    final rng = Random(seed);
    return List.generate(7, (i) {
      final wave = sin((i + 1) / 7 * pi) * 12;
      final jitter = (rng.nextDouble() - 0.5) * 10;
      final v = base - 14 + wave + jitter + i * 1.5;
      return v.clamp(0, 100).toDouble();
    });
  }

  /// Week-over-week growth, comparing the last point to the first.
  int get weeklyGrowthPercent {
    final s = weeklyFocusSeries;
    if (s.isEmpty || s.first == 0) return 0;
    return (((s.last - s.first) / s.first) * 100).round();
  }

  /// Section 12 — insights derived from focus_score, streak_days, focus_hours,
  /// deep_work_percent and learning_percent.
  List<String> get aiInsights {
    final out = <String>[];
    if (focusScore >= 80) {
      out.add('Your focus score of $focusScore is in elite territory.');
    } else if (focusScore > 0) {
      out.add('Your focus score is $focusScore — trending upward.');
    }
    if (streakDays > 0) {
      out.add('You maintain a $streakDays-day streak.');
    }
    if (deepWorkPercent >= 50) {
      out.add('Your Deep Work ratio is above average.');
    } else if (deepWorkPercent > 0) {
      out.add('Your Deep Work ratio has room to grow.');
    }
    if (focusHours > 0) {
      out.add('You have logged ${focusHours}h of focus time.');
    }
    if (learningPercent > 0) {
      out.add('$learningPercent% of your effort goes to Learning.');
    }
    if (out.isEmpty) {
      out.add('Start completing tasks to unlock personalized insights.');
    }
    return out;
  }

  String get aiRecommendation {
    if (learningPercent < 20) {
      return 'Increase Learning Time by 10%.';
    }
    if (deepWorkPercent < 50) {
      return 'Protect more time for uninterrupted Deep Work.';
    }
    if (streakDays < 7) {
      return 'Keep your streak going to build momentum.';
    }
    return 'Great balance — maintain your current rhythm.';
  }

  factory _ProfileVM.from(UserProfileModel? m) {
    final auth = _SupabaseProfile.current();
    String pick(String? a, String b) =>
        (a != null && a.trim().isNotEmpty) ? a.trim() : b;

    final name = pick(
      m?.fullName,
      pick(m?.username, auth.name),
    );
    final joined = m?.createdAt;

    return _ProfileVM(
      name: name.isEmpty ? 'User' : name,
      username: (m?.username ?? '').trim(),
      email: pick(m?.email, auth.email),
      bio: (m?.bio ?? '').trim(),
      avatarUrl: pick(m?.avatarUrl, auth.avatarUrl),
      tier: (m?.tier ?? 'free').trim(),
      role: (m?.role ?? 'user').trim(),
      joinedLabel:
          joined == null ? 'Recently' : DateFormat('MMM yyyy').format(joined),
      focusScore: m?.focusScore ?? 0,
      streakDays: m?.streakDays ?? 0,
      focusHours: m?.focusHours ?? 0,
      model: m,
    );
  }
}

class _SupabaseProfile {
  const _SupabaseProfile({
    required this.name,
    required this.email,
    required this.avatarUrl,
  });

  final String name;
  final String email;
  final String avatarUrl;

  String get initial =>
      name.trim().isEmpty ? '?' : name.characters.first.toUpperCase();

  static _SupabaseProfile current() {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final email = (user?.email ?? '').trim();
    final name =
        (metadata['full_name'] ??
                metadata['username'] ??
                email.split('@').first)
            .toString()
            .trim();
    final avatarUrl =
        (metadata['avatar_url'] ?? metadata['avatarUrl'] ?? '')
            .toString()
            .trim();

    return _SupabaseProfile(
      name: name.isEmpty ? 'User' : name,
      email: email.isEmpty ? 'No email' : email,
      avatarUrl: avatarUrl,
    );
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({
    required this.avatarUrl,
    required this.initial,
    required this.fontSize,
  });

  final String avatarUrl;
  final String initial;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl.isNotEmpty) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) =>
                _ProfileInitial(initial: initial, fontSize: fontSize),
      );
    }

    return _ProfileInitial(initial: initial, fontSize: fontSize);
  }
}

class _ProfileInitial extends StatelessWidget {
  const _ProfileInitial({required this.initial, required this.fontSize});

  final String initial;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: NexusColors.surfaceContainerHigh,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: NexusColors.onSurface,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

Future<void> _signOut(BuildContext context) async {
  await Supabase.instance.client.auth.signOut();
  if (context.mounted) context.go('/');
}

/// Section 10 — persists a settings change to Supabase via [updateSettings].
/// The realtime stream pushes the new value back into the UI.
Future<void> _persist(
  WidgetRef ref, {
  String? themeMode,
  bool? notificationsEnabled,
  bool? privacyMode,
}) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;
  await ref.read(profileRemoteDataSourceProvider).updateSettings(
        userId,
        themeMode: themeMode,
        notificationsEnabled: notificationsEnabled,
        privacyMode: privacyMode,
      );
}

/// Section 10 — a settings row with an icon, label, subtitle and a Material 3
/// switch. Shared by the desktop Settings card and the mobile Preferences card.
class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: NexusColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: NexusColors.onSurface,
                    fontSize: 16,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: NexusColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: NexusColors.primary,
            activeTrackColor: NexusColors.primary.withValues(alpha: 0.3),
            inactiveTrackColor: NexusColors.surfaceContainer,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Small pill badge used in the mobile header (role / member-since).
class _MobileBadge extends StatelessWidget {
  const _MobileBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: NexusColors.primary, size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: NexusColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showEditProfileSheet(BuildContext context, _ProfileVM vm) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => _EditProfileDialog(vm: vm),
  );
}

/// Premium glass edit-profile dialog backed by [updateProfileInfo].
class _EditProfileDialog extends ConsumerStatefulWidget {
  const _EditProfileDialog({required this.vm});
  final _ProfileVM vm;

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  late final TextEditingController _fullName;
  late final TextEditingController _username;
  late final TextEditingController _bio;
  late final TextEditingController _avatarUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.vm.model;
    _fullName = TextEditingController(text: m?.fullName ?? widget.vm.name);
    _username = TextEditingController(text: m?.username ?? widget.vm.username);
    _bio = TextEditingController(text: m?.bio ?? widget.vm.bio);
    _avatarUrl =
        TextEditingController(text: m?.avatarUrl ?? widget.vm.avatarUrl);
  }

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _bio.dispose();
    _avatarUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileRemoteDataSourceProvider).updateProfileInfo(
            userId,
            fullName: _fullName.text.trim(),
            username: _username.text.trim(),
            bio: _bio.text.trim(),
            avatarUrl: _avatarUrl.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: _GlassPanel(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: const [
                    Icon(Icons.edit_rounded, color: NexusColors.primary),
                    SizedBox(width: 12),
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: NexusColors.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _EditField(label: 'FULL NAME', controller: _fullName),
                const SizedBox(height: 16),
                _EditField(label: 'USERNAME', controller: _username),
                const SizedBox(height: 16),
                _EditField(label: 'AVATAR URL', controller: _avatarUrl),
                const SizedBox(height: 16),
                _EditField(label: 'BIO', controller: _bio, maxLines: 3),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(color: NexusColors.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _GradientButton(
                      label: _saving ? 'SAVING…' : 'SAVE',
                      onTap: _saving ? () {} : _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.obscureText = false,
    this.keyboardType,
  });
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: NexusColors.onSurfaceVariant,
            fontSize: 10,
            letterSpacing: 1.5,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: obscureText ? 1 : maxLines,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: NexusColors.onSurface, fontSize: 16),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: NexusColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════
// DESKTOP SCREEN  (test.html)
// ══════════════════════════════════════════════
class _DesktopProfileScreen extends StatelessWidget {
  const _DesktopProfileScreen({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: _DesktopContent(vm: vm),
        ),
      ),
    );
  }
}

// ── Desktop Main Content ─────────────────────
class _DesktopContent extends StatelessWidget {
  const _DesktopContent({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DesktopHeroSection(vm: vm),
        const SizedBox(height: 24),
        _DesktopProfileCompletionCard(vm: vm),
        const SizedBox(height: 24),
        _DesktopTaskAnalyticsCard(vm: vm),
        const SizedBox(height: 24),
        _DesktopStatsRow(vm: vm),
        const SizedBox(height: 24),
        _DesktopWeeklyProductivityCard(vm: vm),
        const SizedBox(height: 24),
        _DesktopAchievementsSection(vm: vm),
        const SizedBox(height: 24),
        _DesktopBottomRow(vm: vm),
      ],
    );
  }
}

// ── Desktop Hero Section ─────────────────────
class _DesktopHeroSection extends StatelessWidget {
  const _DesktopHeroSection({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context) {
    final profile = vm;

    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: NexusColors.primary.withValues(alpha:0.2),
                      width: 4,
                    ),
                    color: NexusColors.surfaceContainer,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _ProfileImage(
                      avatarUrl: profile.avatarUrl,
                      initial: profile.initial,
                      fontSize: 48,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -8,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [NexusColors.primary, NexusColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: NexusColors.primary.withValues(alpha:0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      profile.tier.toUpperCase(),
                      style: const TextStyle(
                        color: NexusColors.onPrimaryFixed,
                        fontSize: 10,
                        letterSpacing: 1,
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(
                      color: NexusColors.onSurface,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      fontFamily: 'Geist',
                    ),
                  ),
                  if (profile.username.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${profile.username}',
                      style: const TextStyle(
                        color: NexusColors.onSurfaceVariant,
                        fontSize: 16,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _InfoChip(icon: Icons.mail_rounded, label: profile.email),
                      _InfoChip(
                        icon: Icons.workspace_premium_rounded,
                        label: profile.tierLabel,
                      ),
                      _InfoChip(
                        icon: Icons.badge_rounded,
                        label: profile.roleLabel,
                      ),
                      _InfoChip(
                        icon: Icons.calendar_today_rounded,
                        label: 'Joined ${profile.joinedLabel}',
                      ),
                    ],
                  ),
                  if (profile.bio.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      profile.bio,
                      style: const TextStyle(
                        color: NexusColors.onSurfaceVariant,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Row(
              children: [
                _GradientButton(
                  label: 'EDIT PROFILE',
                  onTap: () => _showEditProfileSheet(context, profile),
                ),
                const SizedBox(width: 16),
                _GlassButton(label: 'LOGOUT', onTap: () => _signOut(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: NexusColors.primary, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: NexusColors.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

// ── Desktop Stats Row (heatmap + productivity overview) ──
class _DesktopStatsRow extends StatelessWidget {
  const _DesktopStatsRow({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Efficiency Landscape (heatmap) – 2/3
        Expanded(
          flex: 2,
          child: _GlassPanel(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Efficiency Landscape',
                        style: TextStyle(
                          color: NexusColors.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Geist',
                        ),
                      ),
                      Row(
                        children: [
                          _LegendDot(
                            color: NexusColors.surfaceContainerHighest,
                          ),
                          const SizedBox(width: 8),
                          _LegendDot(
                            color: NexusColors.primary.withValues(alpha:0.2),
                          ),
                          const SizedBox(width: 8),
                          _LegendDot(
                            color: NexusColors.primary.withValues(alpha:0.4),
                          ),
                          const SizedBox(width: 8),
                          _LegendDot(
                            color: NexusColors.primary.withValues(alpha:0.7),
                          ),
                          const SizedBox(width: 8),
                          _LegendDot(color: NexusColors.primary),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _DesktopHeatmap(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Lacking Focus',
                        style: TextStyle(
                          color: NexusColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Deep Flow State Reached',
                        style: TextStyle(
                          color: NexusColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Productivity Overview card – 1/3
        Expanded(
          child: _GlassPanel(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Productivity Overview',
                        style: TextStyle(
                          color: NexusColors.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Geist',
                        ),
                      ),
                      Icon(Icons.bolt_rounded, color: NexusColors.primary),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _KpiRow(
                    icon: Icons.speed_rounded,
                    label: 'Focus Score',
                    value: vm.focusScore,
                  ),
                  const SizedBox(height: 12),
                  _KpiRow(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Current Streak',
                    value: vm.streakDays,
                    suffix: ' Days',
                    accent: NexusColors.secondary,
                  ),
                  const SizedBox(height: 12),
                  _KpiRow(
                    icon: Icons.schedule_rounded,
                    label: 'Focus Hours',
                    value: vm.focusHours,
                    suffix: 'h',
                    accent: NexusColors.tertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A single KPI line with an icon, label and an animated integer counter.
class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.icon,
    required this.label,
    required this.value,
    this.suffix = '',
    this.accent = NexusColors.primary,
  });

  final IconData icon;
  final String label;
  final int value;
  final String suffix;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: NexusColors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
          _AnimatedCounter(
            value: value,
            suffix: suffix,
            style: TextStyle(
              color: accent,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }
}

/// Counts up from 0 to [value] once when first built.
class _AnimatedCounter extends StatelessWidget {
  const _AnimatedCounter({
    required this.value,
    required this.style,
    this.suffix = '',
  });

  final int value;
  final String suffix;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('$v$suffix', style: style),
    );
  }
}

class _DesktopHeatmap extends StatelessWidget {
  const _DesktopHeatmap();

  @override
  Widget build(BuildContext context) {
    final rng = Random(42);
    final cols = List.generate(
      30,
      (_) => List.generate(7, (_) => rng.nextDouble()),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            cols.map((col) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Column(
                  children:
                      col.map((v) {
                        Color c;
                        if (v > 0.7) {
                          c = NexusColors.primary;
                        } else if (v > 0.4) {
                          c = NexusColors.primary.withValues(alpha:0.5);
                        } else {
                          c = NexusColors.surfaceContainerHighest;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              );
            }).toList(),
      ),
    );
  }
}

// ── Desktop Weekly Productivity (Section 8) ──
class _DesktopWeeklyProductivityCard extends StatelessWidget {
  const _DesktopWeeklyProductivityCard({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context) {
    final series = vm.weeklyFocusSeries;
    final growth = vm.weeklyGrowthPercent;
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weekly Productivity',
                  style: TextStyle(
                    color: NexusColors.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Geist',
                  ),
                ),
                _TrendIndicator(percent: growth),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 180,
              child: _ProductivityBarChart(series: series, barWidth: 28),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Desktop Achievements (Section 9) ──
class _DesktopAchievementsSection extends StatelessWidget {
  const _DesktopAchievementsSection({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context) {
    final achievements = vm.achievements;
    final unlocked = achievements.where((a) => a.unlocked).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(
                color: NexusColors.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.w500,
                fontFamily: 'Geist',
              ),
            ),
            Text(
              '$unlocked / ${achievements.length} UNLOCKED',
              style: const TextStyle(
                color: NexusColors.onSurfaceVariant,
                fontSize: 10,
                letterSpacing: 1.5,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in achievements) _AchievementChip(achievement: a),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 24.0;
            final width = (constraints.maxWidth - spacing * 3) / 4;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final a in achievements)
                  SizedBox(
                    width: width < 200 ? constraints.maxWidth : width,
                    child: _AchievementBadgeCard(achievement: a),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Section 9 — compact achievement chip (icon + title + lock state).
class _AchievementChip extends StatelessWidget {
  const _AchievementChip({required this.achievement});
  final _Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final color = a.unlocked ? a.accent : NexusColors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: a.unlocked
            ? a.accent.withValues(alpha: 0.12)
            : NexusColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: a.unlocked
              ? a.accent.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            a.unlocked ? a.icon : Icons.lock_outline_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            a.title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: a.unlocked ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section 9 — badge card built on top of the shared [_MilestoneCard].
class _AchievementBadgeCard extends StatelessWidget {
  const _AchievementBadgeCard({required this.achievement});
  final _Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    return _MilestoneCard(
      icon: a.unlocked ? a.icon : Icons.lock_outline_rounded,
      iconColor: a.unlocked ? a.accent : NexusColors.onSurfaceVariant,
      iconBg: (a.unlocked ? a.accent : NexusColors.onSurfaceVariant)
          .withValues(alpha: 0.12),
      title: a.title,
      description: a.progressLabel,
      badge: a.unlocked ? 'UNLOCKED' : 'LOCKED',
      badgeTextColor: a.unlocked ? a.accent : NexusColors.onSurfaceVariant,
      unlocked: a.unlocked,
    );
  }
}

/// Section 8 — week-over-week trend pill (▲/▼ + signed percentage).
class _TrendIndicator extends StatelessWidget {
  const _TrendIndicator({required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    final up = percent >= 0;
    final color = up ? NexusColors.primary : NexusColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            '${up ? '+' : ''}$percent%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }
}

/// Section 8 — animated 7-point bar chart for the weekly focus series.
class _ProductivityBarChart extends StatelessWidget {
  const _ProductivityBarChart({required this.series, this.barWidth = 16});
  final List<double> series;
  final double barWidth;

  static const List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) return const SizedBox.shrink();
    final maxVal = series.reduce(max).clamp(1, double.infinity);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < series.length; i++)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${(series[i] * t).round()}',
                      style: const TextStyle(
                        color: NexusColors.onSurfaceVariant,
                        fontSize: 10,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: barWidth,
                      height: (series[i] / maxVal) * 120 * t + 2,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            NexusColors.primary,
                            NexusColors.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      i < _dayLabels.length ? _dayLabels[i] : '',
                      style: const TextStyle(
                        color: NexusColors.onSurfaceVariant,
                        fontSize: 10,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.icon,
    required this.iconColor,
    this.iconBg,
    required this.title,
    required this.description,
    required this.badge,
    required this.badgeTextColor,
    required this.unlocked,
  });

  final IconData icon;
  final Color iconColor;
  final Color? iconBg;
  final String title;
  final String description;
  final String badge;
  final Color badgeTextColor;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.7,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBg ?? iconColor.withValues(alpha:0.1),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: NexusColors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Geist',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: NexusColors.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: NexusColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 10,
                    letterSpacing: 1,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Desktop Bottom Row (work distribution + settings) ──
class _DesktopBottomRow extends StatelessWidget {
  const _DesktopBottomRow({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context) {
    final segments = vm.workDistribution;
    final lead = segments.isEmpty ? null : segments.first;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Work Distribution Chart (Section 7)
        Expanded(
          child: _GlassPanel(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Work Distribution',
                    style: TextStyle(
                      color: NexusColors.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _WorkDistributionDonut(
                        segments: segments,
                        centerValue: lead?.percent ?? 0,
                        centerLabel: (lead?.label ?? '').toUpperCase(),
                        size: 192,
                      ),
                      const SizedBox(width: 48),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < segments.length; i++) ...[
                            if (i > 0) const SizedBox(height: 16),
                            _ChartLegendItem(
                              color: segments[i].color,
                              label: segments[i].label,
                              sub: '${segments[i].percent}%',
                              glow: i == 0,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  for (var i = 0; i < segments.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    _WorkSegmentBar(segment: segments[i]),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Settings panels
        Expanded(
          child: Column(
            children: [
              _DesktopSettingsCard(vm: vm),
              const SizedBox(height: 24),
              const _DesktopPersonalIdentityCard(),
              const SizedBox(height: 24),
              _DesktopSecurityCard(vm: vm),
              const SizedBox(height: 24),
              _DesktopAISummaryCard(vm: vm),
              const SizedBox(height: 24),
              _DesktopActivityTimelineCard(vm: vm),
            ],
          ),
        ),
      ],
    );
  }
}

/// Section 7 — animated donut chart driven by [_WorkSegment]s, with a
/// percentage + label rendered in the center.
class _WorkDistributionDonut extends StatelessWidget {
  const _WorkDistributionDonut({
    required this.segments,
    required this.centerValue,
    required this.centerLabel,
    this.size = 192,
  });

  final List<_WorkSegment> segments;
  final int centerValue;
  final String centerLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _WorkDonutPainter(segments: segments, progress: t),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(centerValue * t).round()}%',
                    style: TextStyle(
                      color: NexusColors.onSurface,
                      fontSize: size / 6.8,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Geist',
                    ),
                  ),
                  if (centerLabel.isNotEmpty)
                    Text(
                      centerLabel,
                      style: const TextStyle(
                        color: NexusColors.onSurfaceVariant,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkDonutPainter extends CustomPainter {
  _WorkDonutPainter({required this.segments, required this.progress});
  final List<_WorkSegment> segments;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 24.0;
    const gap = 0.04; // small gap between segments (radians)
    final rect = Rect.fromCircle(center: center, radius: radius);

    void drawArc(double start, double sweep, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
    }

    // Track.
    drawArc(0, 2 * pi, NexusColors.surfaceContainerHighest);

    final total = segments.fold<int>(0, (s, seg) => s + seg.percent);
    if (total <= 0) return;

    var start = -pi / 2;
    for (final seg in segments) {
      final fraction = seg.percent / total;
      final fullSweep = fraction * 2 * pi;
      final sweep = (fullSweep - gap).clamp(0.0, 2 * pi) * progress;
      if (sweep > 0) drawArc(start, sweep, seg.color);
      start += fullSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _WorkDonutPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.segments != segments;
}

/// Section 7 — a labeled segmented bar with an animated percentage readout.
class _WorkSegmentBar extends StatelessWidget {
  const _WorkSegmentBar({required this.segment});
  final _WorkSegment segment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              segment.label,
              style: const TextStyle(
                color: NexusColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            _AnimatedCounter(
              value: segment.percent,
              suffix: '%',
              style: TextStyle(
                color: segment.color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (segment.percent / 100).clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: NexusColors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(segment.color),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  const _ChartLegendItem({
    required this.color,
    required this.label,
    required this.sub,
    this.glow = false,
  });
  final Color color;
  final String label;
  final String sub;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow:
                glow
                    ? [BoxShadow(color: color.withValues(alpha:0.4), blurRadius: 6)]
                    : null,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: NexusColors.onSurface,
                fontSize: 16,
              ),
            ),
            Text(
              sub,
              style: const TextStyle(
                color: NexusColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Section 10 — Settings card with persisted Material 3 switches (desktop).
class _DesktopSettingsCard extends ConsumerWidget {
  const _DesktopSettingsCard({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.tune_rounded, color: NexusColors.primary),
                SizedBox(width: 12),
                Text(
                  'Settings',
                  style: TextStyle(
                    color: NexusColors.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SettingsToggleRow(
              icon: Icons.dark_mode_rounded,
              label: 'Dark Mode',
              subtitle: 'Use the dark glassmorphism theme',
              value: vm.isDarkMode,
              onChanged: (v) => _persist(ref, themeMode: v ? 'dark' : 'light'),
            ),
            const SizedBox(height: 8),
            _SettingsToggleRow(
              icon: Icons.notifications_rounded,
              label: 'Notifications',
              subtitle: 'Receive task and focus reminders',
              value: vm.notificationsEnabled,
              onChanged: (v) => _persist(ref, notificationsEnabled: v),
            ),
            const SizedBox(height: 8),
            _SettingsToggleRow(
              icon: Icons.shield_rounded,
              label: 'Privacy Mode',
              subtitle: 'Hide analytics from shared views',
              value: vm.privacyMode,
              onChanged: (v) => _persist(ref, privacyMode: v),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopPersonalIdentityCard extends ConsumerWidget {
  const _DesktopPersonalIdentityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = _ProfileVM.from(ref.watch(userProfileProvider).valueOrNull);

    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.badge_rounded, color: NexusColors.primary),
                SizedBox(width: 12),
                Text(
                  'Personal Identity',
                  style: TextStyle(
                    color: NexusColors.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _IdentityField(
                    label: 'FULL NAME',
                    value: profile.name,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _IdentityField(
                    label: 'USERNAME',
                    value: profile.username.isEmpty
                        ? '—'
                        : '@${profile.username}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _IdentityField(
                    label: 'EMAIL ADDRESS',
                    value: profile.email,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _IdentityField(
                    label: 'ROLE',
                    value: profile.roleLabel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _IdentityField(
                    label: 'MEMBER SINCE',
                    value: 'Joined ${profile.joinedLabel}',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _IdentityField(
                    label: 'BIO',
                    value: profile.bio.isEmpty ? '—' : profile.bio,
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

class _IdentityField extends StatelessWidget {
  const _IdentityField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: NexusColors.onSurfaceVariant,
            fontSize: 10,
            letterSpacing: 1.5,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: NexusColors.onSurface, fontSize: 16),
        ),
      ],
    );
  }
}

// ── Section 11 — Security Center (desktop) ──
class _DesktopSecurityCard extends StatelessWidget {
  const _DesktopSecurityCard({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.security_rounded, color: NexusColors.primary),
                SizedBox(width: 12),
                Text(
                  'Security Center',
                  style: TextStyle(
                    color: NexusColors.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SecurityActionRow(
              icon: Icons.password_rounded,
              title: 'Change Password',
              subtitle: 'Update your account password',
              onTap: () => _showChangePasswordDialog(context),
            ),
            const SizedBox(height: 8),
            _SecurityActionRow(
              icon: Icons.alternate_email_rounded,
              title: 'Change Email',
              subtitle: 'Update your sign-in email address',
              onTap: () => _showChangeEmailDialog(context, vm.email),
            ),
            const SizedBox(height: 8),
            _SecurityActionRow(
              icon: Icons.devices_rounded,
              title: 'Manage Sessions',
              subtitle: 'Sign out of this device',
              onTap: () => _showManageSessionsDialog(context),
            ),
            if (vm.accountId.isNotEmpty) ...[
              const SizedBox(height: 16),
              _AccountIdRow(accountId: vm.accountId),
            ],
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) =>
      showChangePasswordDialog(context);

  void _showChangeEmailDialog(BuildContext context, String currentEmail) =>
      showChangeEmailDialog(context, currentEmail);

  void _showManageSessionsDialog(BuildContext context) =>
      showManageSessionsDialog(context);
}

/// Section 11 — security dialog launchers, shared by desktop and mobile.
void showChangePasswordDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => const _ChangePasswordDialog(),
  );
}

void showChangeEmailDialog(BuildContext context, String currentEmail) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => _ChangeEmailDialog(currentEmail: currentEmail),
  );
}

void showManageSessionsDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => const _ManageSessionsDialog(),
  );
}

/// Section 11 — read-only display of the stable account identifier (users.id).
class _AccountIdRow extends StatelessWidget {
  const _AccountIdRow({required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.fingerprint_rounded,
            color: NexusColors.onSurfaceVariant,
            size: 18,
          ),
          const SizedBox(width: 12),
          const Text(
            'ACCOUNT ID',
            style: TextStyle(
              color: NexusColors.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 1.5,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              accountId,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: NexusColors.onSurface,
                fontSize: 12,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section 11 — a tappable security action row.
class _SecurityActionRow extends StatelessWidget {
  const _SecurityActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: NexusColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: NexusColors.onSurface),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: NexusColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: NexusColors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Section 11 — change the account password via Supabase auth.
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final password = _password.text.trim();
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (password != _confirm.text.trim()) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(password: password));
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Failed to update password: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SecurityDialogShell(
      icon: Icons.password_rounded,
      title: 'Change Password',
      error: _error,
      saving: _saving,
      onSave: _save,
      children: [
        _EditField(
          label: 'NEW PASSWORD',
          controller: _password,
          obscureText: true,
        ),
        const SizedBox(height: 16),
        _EditField(
          label: 'CONFIRM PASSWORD',
          controller: _confirm,
          obscureText: true,
        ),
      ],
    );
  }
}

/// Section 11 — change the sign-in email via Supabase auth.
class _ChangeEmailDialog extends StatefulWidget {
  const _ChangeEmailDialog({required this.currentEmail});
  final String currentEmail;

  @override
  State<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<_ChangeEmailDialog> {
  late final TextEditingController _email;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.currentEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final email = _email.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(email: email));
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check your inbox to confirm the new email.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Failed to update email: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SecurityDialogShell(
      icon: Icons.alternate_email_rounded,
      title: 'Change Email',
      error: _error,
      saving: _saving,
      onSave: _save,
      children: [
        _EditField(
          label: 'EMAIL ADDRESS',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }
}

/// Section 11 — sign out of the current device.
class _ManageSessionsDialog extends StatefulWidget {
  const _ManageSessionsDialog();

  @override
  State<_ManageSessionsDialog> createState() => _ManageSessionsDialogState();
}

class _ManageSessionsDialogState extends State<_ManageSessionsDialog> {
  bool _saving = false;

  Future<void> _signOut() async {
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pop();
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: _SolidPanel(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: const [
                    Icon(Icons.devices_rounded, color: NexusColors.primary),
                    SizedBox(width: 12),
                    Text(
                      'Manage Sessions',
                      style: TextStyle(
                        color: NexusColors.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sign out of this device. You will need to sign in again to '
                  'access your account.',
                  style: TextStyle(
                    color: NexusColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!_saving)
                      _GlassButton(
                        label: 'CANCEL',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    const SizedBox(width: 12),
                    if (_saving)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      _GradientButton(label: 'SIGN OUT', onTap: _signOut),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared shell for the password/email security dialogs.
class _SecurityDialogShell extends StatelessWidget {
  const _SecurityDialogShell({
    required this.icon,
    required this.title,
    required this.children,
    required this.saving,
    required this.onSave,
    this.error,
  });
  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool saving;
  final VoidCallback onSave;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: _SolidPanel(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(icon, color: NexusColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: NexusColors.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Geist',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ...children,
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    error!,
                    style: const TextStyle(
                      color: NexusColors.error,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!saving)
                      _GlassButton(
                        label: 'CANCEL',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    const SizedBox(width: 12),
                    if (saving)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      _GradientButton(label: 'SAVE', onTap: onSave),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section 12 — AI Productivity Summary (desktop) ──
class _DesktopAISummaryCard extends StatelessWidget {
  const _DesktopAISummaryCard({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.psychology_rounded, color: NexusColors.secondary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI Productivity Summary',
                    style: TextStyle(
                      color: NexusColors.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
                _AIBadge(),
              ],
            ),
            const SizedBox(height: 20),
            _AIInsightCard(insights: vm.aiInsights),
            const SizedBox(height: 16),
            _AIRecommendationRow(recommendation: vm.aiRecommendation),
          ],
        ),
      ),
    );
  }
}

// ── Section 13 — Activity Timeline (desktop) ──
class _DesktopActivityTimelineCard extends StatelessWidget {
  const _DesktopActivityTimelineCard({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context) {
    final events = vm.activityTimeline;
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.history_rounded, color: NexusColors.primary),
                SizedBox(width: 12),
                Text(
                  'Activity Timeline',
                  style: TextStyle(
                    color: NexusColors.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            for (var i = 0; i < events.length; i++)
              _TimelineTile(
                event: events[i],
                isLast: i == events.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

/// Section 12 — small "AI" pill badge.
class _AIBadge extends StatelessWidget {
  const _AIBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: NexusColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: NexusColors.secondary.withValues(alpha: 0.3)),
      ),
      child: const Text(
        'AI',
        style: TextStyle(
          color: NexusColors.secondary,
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
          fontFamily: 'JetBrains Mono',
        ),
      ),
    );
  }
}

/// Section 12 — bullet list of derived insights.
class _AIInsightCard extends StatelessWidget {
  const _AIInsightCard({required this.insights});
  final List<String> insights;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final insight in insights)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: NexusColors.secondary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      insight,
                      style: const TextStyle(
                        color: NexusColors.onSurface,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Section 12 — highlighted recommendation row.
class _AIRecommendationRow extends StatelessWidget {
  const _AIRecommendationRow({required this.recommendation});
  final String recommendation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            NexusColors.primary.withValues(alpha: 0.12),
            NexusColors.secondary.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NexusColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            color: NexusColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RECOMMENDATION',
                  style: TextStyle(
                    color: NexusColors.onSurfaceVariant,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation,
                  style: const TextStyle(
                    color: NexusColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section 13 — a single activity timeline entry with connector line.
class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.event, required this.isLast});
  final _TimelineEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final timestamp = event.timestamp;
    final label = timestamp == null
        ? 'Unknown'
        : DateFormat('MMM d, yyyy • h:mm a').format(timestamp);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: event.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: event.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(event.icon, color: event.accent, size: 18),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: NexusColors.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      color: NexusColors.onSurfaceVariant,
                      fontSize: 12,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// MOBILE SCREEN  (test1.html)
// ══════════════════════════════════════════════
class _MobileProfileScreen extends ConsumerWidget {
  const _MobileProfileScreen({required this.vm});
  final _ProfileVM vm;

  // Heatmap data from test1.html (9 columns × 7 rows opacity values)
  static const List<List<double>> _heatData = [
    [0.2, 0.4, 0.1, 0.6, 0.2, 0.8, 0.2],
    [0.3, 0.1, 0.4, 0.2, 0.1, 0.3, 0.1],
    [0.8, 0.9, 0.6, 1.0, 0.8, 0.9, 0.7],
    [0.2, 0.1, 0.3, 0.2, 0.1, 0.2, 0.1],
    [0.4, 0.3, 0.5, 0.4, 0.2, 0.5, 0.3],
    [0.1, 0.2, 0.1, 0.3, 0.1, 0.2, 0.1],
    [0.8, 0.7, 0.9, 0.8, 0.6, 1.0, 0.8],
    [0.2, 0.4, 0.1, 0.6, 0.2, 0.8, 0.2],
    [0.3, 0.1, 0.4, 0.2, 0.1, 0.3, 0.1],
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = vm;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 132),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Header
          Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [NexusColors.primary, NexusColors.secondary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: NexusColors.primary.withValues(alpha:0.2),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(
                      child: _ProfileImage(
                        avatarUrl: profile.avatarUrl,
                        initial: profile.initial,
                        fontSize: 38,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: NexusColors.primary,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: NexusColors.primary.withValues(alpha:0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          '${profile.tier.toUpperCase()} Plan',
                          style: const TextStyle(
                            color: NexusColors.onPrimary,
                            fontSize: 10,
                            letterSpacing: 2,
                            fontFamily: 'JetBrains Mono',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                profile.name,
                style: const TextStyle(
                  color: NexusColors.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Geist',
                ),
              ),
              if (profile.username.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '@${profile.username}',
                  style: const TextStyle(
                    color: NexusColors.onSurfaceVariant,
                    fontSize: 13,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                profile.email,
                style: const TextStyle(
                  color: NexusColors.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  _MobileBadge(
                    icon: Icons.badge_rounded,
                    label: profile.roleLabel,
                  ),
                  _MobileBadge(
                    icon: Icons.calendar_today_rounded,
                    label: 'Joined ${profile.joinedLabel}',
                  ),
                ],
              ),
              if (profile.bio.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  profile.bio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: NexusColors.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Stats Bento
          Column(
            children: [
              _MobileGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Deep Work Streak',
                        style: TextStyle(
                          color: NexusColors.primary,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _AnimatedCounter(
                            value: profile.streakDays,
                            suffix: ' Days',
                            style: const TextStyle(
                              color: NexusColors.onSurface,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Geist',
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.local_fire_department,
                            color: NexusColors.secondary,
                            size: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MobileGlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FOCUS SCORE',
                              style: TextStyle(
                                color: NexusColors.onSurfaceVariant,
                                fontSize: 10,
                                letterSpacing: 1.5,
                                fontFamily: 'JetBrains Mono',
                              ),
                            ),
                            const SizedBox(height: 4),
                            _AnimatedCounter(
                              value: profile.focusScore,
                              style: const TextStyle(
                                color: NexusColors.onSurface,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MobileGlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FOCUS HOURS',
                              style: TextStyle(
                                color: NexusColors.onSurfaceVariant,
                                fontSize: 10,
                                letterSpacing: 1.5,
                                fontFamily: 'JetBrains Mono',
                              ),
                            ),
                            const SizedBox(height: 4),
                            _AnimatedCounter(
                              value: profile.focusHours,
                              suffix: 'h',
                              style: const TextStyle(
                                color: NexusColors.onSurface,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Geist',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Profile Completion
          _MobileProfileCompletionCard(vm: profile),
          const SizedBox(height: 16),

          // Task Analytics
          _MobileTaskAnalyticsCard(vm: profile),
          const SizedBox(height: 16),

          // Productivity Heatmap
          _MobileGlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Productivity Heatmap',
                        style: TextStyle(
                          color: NexusColors.onSurface,
                          fontSize: 14,
                          fontFamily: 'Geist',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Last 90 Days',
                        style: TextStyle(
                          color: NexusColors.onSurfaceVariant,
                          fontSize: 10,
                          letterSpacing: 1,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:
                          _heatData.map((col) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 3),
                              child: Column(
                                children:
                                    col.map((v) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 3,
                                        ),
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: NexusColors.primary
                                                .withValues(alpha:v),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Work Distribution (Section 7)
          _MobileWorkDistributionCard(vm: profile),
          const SizedBox(height: 16),

          // Weekly Productivity (Section 8)
          _MobileWeeklyProductivityCard(vm: profile),
          const SizedBox(height: 16),

          // Achievements (Section 9)
          _MobileAchievementsCard(vm: profile),
          const SizedBox(height: 16),

          // Personal Identity
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  'PERSONAL IDENTITY',
                  style: TextStyle(
                    color: NexusColors.onSurfaceVariant,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
              _MobileGlassCard(
                child: Column(
                  children: [
                    _MobileIdentityField(
                      label: 'FULL NAME',
                      value: profile.name,
                    ),
                    Divider(color: Colors.white.withValues(alpha:0.05), height: 1),
                    _MobileIdentityField(
                      label: 'USERNAME',
                      value: profile.username.isEmpty
                          ? '—'
                          : '@${profile.username}',
                    ),
                    Divider(color: Colors.white.withValues(alpha:0.05), height: 1),
                    _MobileIdentityField(
                      label: 'EMAIL ADDRESS',
                      value: profile.email,
                    ),
                    Divider(color: Colors.white.withValues(alpha:0.05), height: 1),
                    _MobileIdentityField(
                      label: 'BIO',
                      value: profile.bio.isEmpty ? '—' : profile.bio,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preferences
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  'SETTINGS',
                  style: TextStyle(
                    color: NexusColors.onSurfaceVariant,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
              _MobileGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      _SettingsToggleRow(
                        icon: Icons.dark_mode_rounded,
                        label: 'Dark Mode',
                        value: profile.isDarkMode,
                        onChanged: (v) =>
                            _persist(ref, themeMode: v ? 'dark' : 'light'),
                      ),
                      const SizedBox(height: 8),
                      _SettingsToggleRow(
                        icon: Icons.notifications_rounded,
                        label: 'Notifications',
                        value: profile.notificationsEnabled,
                        onChanged: (v) =>
                            _persist(ref, notificationsEnabled: v),
                      ),
                      const SizedBox(height: 8),
                      _SettingsToggleRow(
                        icon: Icons.shield_rounded,
                        label: 'Privacy Mode',
                        value: profile.privacyMode,
                        onChanged: (v) => _persist(ref, privacyMode: v),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Security Center (Section 11)
          _MobileSecurityCard(vm: profile),
          const SizedBox(height: 16),

          // AI Productivity Summary (Section 12)
          _MobileAISummaryCard(vm: profile),
          const SizedBox(height: 16),

          // Activity Timeline (Section 13)
          _MobileActivityTimelineCard(vm: profile),
          const SizedBox(height: 16),

          // Go Premium Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  NexusColors.primaryContainer.withValues(alpha:0.8),
                  NexusColors.secondaryContainer.withValues(alpha:0.8),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha:0.1)),
              boxShadow: [
                BoxShadow(
                  color: NexusColors.primary.withValues(alpha:0.15),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Go Premium',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Geist',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Unlock advanced AI deep work analysis.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0DBFF),
                    foregroundColor: const Color(0xFF2C0051),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Upgrade Now',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileGlassCard extends StatelessWidget {
  const _MobileGlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha:0.08)),
      ),
      child: child,
    );
  }
}

/// Section 11 — Security Center (mobile). Reuses [_SecurityActionRow] and
/// [_AccountIdRow] inside the mobile glass card.
class _MobileSecurityCard extends StatelessWidget {
  const _MobileSecurityCard({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            'SECURITY CENTER',
            style: TextStyle(
              color: NexusColors.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 2,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ),
        _MobileGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _SecurityActionRow(
                  icon: Icons.password_rounded,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  onTap: () => showChangePasswordDialog(context),
                ),
                const SizedBox(height: 8),
                _SecurityActionRow(
                  icon: Icons.alternate_email_rounded,
                  title: 'Change Email',
                  subtitle: 'Update your sign-in email address',
                  onTap: () => showChangeEmailDialog(context, vm.email),
                ),
                const SizedBox(height: 8),
                _SecurityActionRow(
                  icon: Icons.devices_rounded,
                  title: 'Manage Sessions',
                  subtitle: 'Sign out of this device',
                  onTap: () => showManageSessionsDialog(context),
                ),
                if (vm.accountId.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _AccountIdRow(accountId: vm.accountId),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Section 12 — AI Productivity Summary (mobile). Reuses [_AIBadge],
/// [_AIInsightCard] and [_AIRecommendationRow].
class _MobileAISummaryCard extends StatelessWidget {
  const _MobileAISummaryCard({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context) {
    return _MobileGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.psychology_rounded,
                  color: NexusColors.secondary,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI Productivity Summary',
                    style: TextStyle(
                      color: NexusColors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
                _AIBadge(),
              ],
            ),
            const SizedBox(height: 16),
            _AIInsightCard(insights: vm.aiInsights),
            const SizedBox(height: 12),
            _AIRecommendationRow(recommendation: vm.aiRecommendation),
          ],
        ),
      ),
    );
  }
}

/// Section 13 — Activity Timeline (mobile). Reuses [_TimelineTile].
class _MobileActivityTimelineCard extends StatelessWidget {
  const _MobileActivityTimelineCard({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context) {
    final events = vm.activityTimeline;
    return _MobileGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.history_rounded,
                  color: NexusColors.primary,
                  size: 20,
                ),
                SizedBox(width: 10),
                Text(
                  'Activity Timeline',
                  style: TextStyle(
                    color: NexusColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Geist',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < events.length; i++)
              _TimelineTile(
                event: events[i],
                isLast: i == events.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileIdentityField extends StatelessWidget {
  const _MobileIdentityField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: NexusColors.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 1.5,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: NexusColors.onSurface, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════

/// Section 7 — Work Distribution (mobile). Donut + segmented bars.
class _MobileWorkDistributionCard extends StatelessWidget {
  const _MobileWorkDistributionCard({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context) {
    final segments = vm.workDistribution;
    final lead = segments.isEmpty ? null : segments.first;
    return _MobileGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Work Distribution',
              style: TextStyle(
                color: NexusColors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _WorkDistributionDonut(
                  segments: segments,
                  centerValue: lead?.percent ?? 0,
                  centerLabel: (lead?.label ?? '').toUpperCase(),
                  size: 96,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      for (var i = 0; i < segments.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _WorkSegmentBar(segment: segments[i]),
                      ],
                    ],
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

/// Section 8 — Weekly Productivity (mobile). Bar chart + trend indicator.
class _MobileWeeklyProductivityCard extends StatelessWidget {
  const _MobileWeeklyProductivityCard({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context) {
    return _MobileGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weekly Productivity',
                  style: TextStyle(
                    color: NexusColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Geist',
                  ),
                ),
                _TrendIndicator(percent: vm.weeklyGrowthPercent),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: _ProductivityBarChart(series: vm.weeklyFocusSeries),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section 9 — Achievements (mobile). Chips + stacked badge cards.
class _MobileAchievementsCard extends StatelessWidget {
  const _MobileAchievementsCard({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context) {
    final achievements = vm.achievements;
    final unlocked = achievements.where((a) => a.unlocked).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACHIEVEMENTS',
                style: TextStyle(
                  color: NexusColors.onSurfaceVariant,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
              Text(
                '$unlocked / ${achievements.length}',
                style: const TextStyle(
                  color: NexusColors.onSurfaceVariant,
                  fontSize: 10,
                  letterSpacing: 1,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
        ),
        _MobileGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final a in achievements)
                      _AchievementChip(achievement: a),
                  ],
                ),
                for (final a in achievements) ...[
                  const SizedBox(height: 12),
                  _MobileAchievementRow(achievement: a),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Section 9 — a single compact achievement row (mobile badge card).
class _MobileAchievementRow extends StatelessWidget {
  const _MobileAchievementRow({required this.achievement});
  final _Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final color = a.unlocked ? a.accent : NexusColors.onSurfaceVariant;
    return Opacity(
      opacity: a.unlocked ? 1.0 : 0.7,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(
                a.unlocked ? a.icon : Icons.lock_outline_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
                    style: const TextStyle(
                      color: NexusColors.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    a.progressLabel,
                    style: const TextStyle(
                      color: NexusColors.onSurfaceVariant,
                      fontSize: 12,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              a.unlocked
                  ? Icons.check_circle_rounded
                  : Icons.lock_outline_rounded,
              color: color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// A single identity completion check (label + whether it is filled in).
class _CompletionItem {
  const _CompletionItem(this.label, this.done);
  final String label;
  final bool done;
}

/// A single Work Distribution segment (Section 7). Data only.
class _WorkSegment {
  const _WorkSegment(this.label, this.percent, this.color);
  final String label;
  final int percent;
  final Color color;
}

/// A single Activity Timeline event (Section 13). Data only.
class _TimelineEvent {
  const _TimelineEvent({
    required this.icon,
    required this.title,
    required this.timestamp,
    required this.accent,
  });
  final IconData icon;
  final String title;
  final DateTime? timestamp;
  final Color accent;
}

/// A derived achievement (Section 9). Data only — rendered later.
class _Achievement {
  const _Achievement({
    required this.icon,
    required this.title,
    required this.unlocked,
    required this.progressLabel,
    required this.accent,
  });
  final IconData icon;
  final String title;
  final bool unlocked;
  final String progressLabel;
  final Color accent;
}

/// Section 6 — Task Analytics (desktop). Progress ring + KPI cards.
class _DesktopTaskAnalyticsCard extends StatelessWidget {
  const _DesktopTaskAnalyticsCard({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Task Statistics',
                  style: TextStyle(
                    color: NexusColors.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Geist',
                  ),
                ),
                Icon(Icons.checklist_rounded, color: NexusColors.primary),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    _CompletionRing(percent: vm.taskCompletionRate, size: 120),
                    const SizedBox(height: 8),
                    const Text(
                      'COMPLETION RATE',
                      style: TextStyle(
                        color: NexusColors.onSurfaceVariant,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    children: [
                      _KpiRow(
                        icon: Icons.list_alt_rounded,
                        label: 'Total Tasks',
                        value: vm.totalTasks,
                      ),
                      const SizedBox(height: 12),
                      _KpiRow(
                        icon: Icons.task_alt_rounded,
                        label: 'Completed Tasks',
                        value: vm.completedTasks,
                        accent: NexusColors.tertiary,
                      ),
                    ],
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

/// Section 6 — Task Analytics (mobile). Progress ring + stacked KPI cards.
class _MobileTaskAnalyticsCard extends StatelessWidget {
  const _MobileTaskAnalyticsCard({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context) {
    return _MobileGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Statistics',
              style: TextStyle(
                color: NexusColors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Geist',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _CompletionRing(percent: vm.taskCompletionRate, size: 72),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _MobileMiniStat(
                        label: 'TOTAL TASKS',
                        value: vm.totalTasks,
                      ),
                      const SizedBox(height: 10),
                      _MobileMiniStat(
                        label: 'COMPLETED',
                        value: vm.completedTasks,
                      ),
                    ],
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

/// Compact label + animated counter row used in mobile analytics cards.
class _MobileMiniStat extends StatelessWidget {
  const _MobileMiniStat({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: NexusColors.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 1.5,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          _AnimatedCounter(
            value: value,
            style: const TextStyle(
              color: NexusColors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'Geist',
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated circular progress ring showing [percent] (0-100) in the center.
class _CompletionRing extends StatelessWidget {
  const _CompletionRing({required this.percent, this.size = 96});
  final int percent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _CompletionRingPainter(value),
              ),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  color: NexusColors.onSurface,
                  fontSize: size / 4,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Geist',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompletionRingPainter extends CustomPainter {
  _CompletionRingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 8.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = NexusColors.surfaceContainerHighest
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..shader = const LinearGradient(
        colors: [NexusColors.primary, NexusColors.secondary],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(covariant _CompletionRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CompletionChecklistItem extends StatelessWidget {
  const _CompletionChecklistItem({required this.item});
  final _CompletionItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          item.done
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: item.done ? NexusColors.primary : NexusColors.onSurfaceVariant,
          size: 18,
        ),
        const SizedBox(width: 10),
        Text(
          item.label,
          style: TextStyle(
            color:
                item.done ? NexusColors.onSurface : NexusColors.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _DesktopProfileCompletionCard extends StatelessWidget {
  const _DesktopProfileCompletionCard({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context) {
    final items = vm.completionItems;
    return _GlassPanel(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _CompletionRing(percent: vm.completionPercent, size: 120),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile Completion',
                    style: TextStyle(
                      color: NexusColors.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vm.completionPercent == 100
                        ? 'Your profile is fully set up.'
                        : 'Complete your profile to get the most out of TaskFlow.',
                    style: const TextStyle(
                      color: NexusColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 32,
                    runSpacing: 12,
                    children: [
                      for (final item in items)
                        SizedBox(
                          width: 180,
                          child: _CompletionChecklistItem(item: item),
                        ),
                    ],
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

class _MobileProfileCompletionCard extends StatelessWidget {
  const _MobileProfileCompletionCard({required this.vm});
  final _ProfileVM vm;

  @override
  Widget build(BuildContext context) {
    final items = vm.completionItems;
    return _MobileGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CompletionRing(percent: vm.completionPercent, size: 72),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile Completion',
                        style: TextStyle(
                          color: NexusColors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Geist',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vm.completionPercent == 100
                            ? 'All set'
                            : '${items.where((i) => i.done).length} of ${items.length} complete',
                        style: const TextStyle(
                          color: NexusColors.onSurfaceVariant,
                          fontSize: 12,
                          fontFamily: 'JetBrains Mono',
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _CompletionChecklistItem(item: items[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha:0.08)),
        boxShadow: [
          BoxShadow(
            color: NexusColors.primary.withValues(alpha:0.05),
            blurRadius: 30,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Opaque panel used for dialogs that need a solid (non-glass) surface.
class _SolidPanel extends StatelessWidget {
  const _SolidPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NexusColors.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              NexusColors.primaryContainer,
              NexusColors.secondaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: NexusColors.primary.withValues(alpha:0.15),
              blurRadius: 12,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            letterSpacing: 2,
            fontFamily: 'JetBrains Mono',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: NexusColors.error.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: NexusColors.error.withValues(alpha: 0.28)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: NexusColors.error,
            fontSize: 10,
            letterSpacing: 2,
            fontFamily: 'JetBrains Mono',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
