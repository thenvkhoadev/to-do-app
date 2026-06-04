import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/edit_profile/edit_profile_shared.dart';
import '../widgets/edit_profile/profile_header_card.dart';
import '../widgets/edit_profile/profile_completion_card.dart';
import '../widgets/edit_profile/personal_information_card.dart';
import '../widgets/edit_profile/productivity_stats_card.dart';
import '../widgets/edit_profile/work_distribution_card.dart';
import '../widgets/edit_profile/account_settings_card.dart';
import '../widgets/edit_profile/connected_accounts_card.dart';
import '../widgets/edit_profile/security_center_card.dart';
import '../widgets/edit_profile/active_devices_card.dart';
import '../widgets/edit_profile/ai_profile_insights_card.dart';
import '../widgets/edit_profile/achievements_card.dart';
import '../widgets/edit_profile/export_center_card.dart';
import '../widgets/edit_profile/danger_zone_card.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _locationController = TextEditingController();

  bool _initialized = false;
  bool _isSaving = false;

  // Local settings states
  String _themeMode = 'dark';
  bool _notificationsEnabled = true;
  bool _privacyMode = false;
  bool _aiCopilotEnabled = true;
  String _preferredTimezone = '(UTC+07:00) Bangkok, Hanoi, Jakarta';
  String _occupation = 'Focus Architect';

  List<String> _skills = ['Flutter', 'Dart', 'AI Engineering', 'Supabase'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      // 1. Save profile text fields
      await ref.read(profileRemoteDataSourceProvider).updateProfileInfo(
            userId,
            fullName: _fullNameController.text.trim(),
            username: _usernameController.text.trim(),
            bio: _bioController.text.trim(),
            occupation: _occupation,
            avatarUrl: _avatarUrlController.text.trim(),
            coreTech: _skills,
            locationNode: _locationController.text.trim(),
            preferredTimezone: _preferredTimezone,
          );

      // 2. Save settings preferences
      await ref.read(profileRemoteDataSourceProvider).updateSettings(
            userId,
            themeMode: _themeMode,
            notificationsEnabled: _notificationsEnabled,
            privacyMode: _privacyMode,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: EditProfileColors.success,
          ),
        );
        // Switch back to view mode
        ref.read(showEditProfileProvider.notifier).state = false;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: EditProfileColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _discardChanges() {
    ref.read(showEditProfileProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsyncValue = ref.watch(userProfileProvider);

    return profileAsyncValue.when(
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            backgroundColor: EditProfileColors.background,
            body: Center(
              child: Text(
                'No profile data found in database.',
                style: TextStyle(color: EditProfileColors.textPrimary),
              ),
            ),
          );
        }

        if (!_initialized) {
          _fullNameController.text = profile.fullName ?? '';
          _usernameController.text = profile.username ?? '';
          _bioController.text = profile.bio ?? '';
          _avatarUrlController.text = profile.avatarUrl ?? '';
          _themeMode = profile.themeMode;
          _notificationsEnabled = profile.notificationsEnabled;
          _privacyMode = profile.privacyMode;

          if (profile.coreTech.isNotEmpty) {
            _skills = List<String>.from(profile.coreTech);
          }
          if (profile.locationNode != null) {
            _locationController.text = profile.locationNode!;
          }
          if (profile.preferredTimezone != null) {
            _preferredTimezone = profile.preferredTimezone!;
          }
          if (profile.occupation != null) {
            _occupation = profile.occupation!;
          }

          _initialized = true;
        }

        final createdAtLabel = profile.createdAt == null
            ? 'Recently'
            : DateFormat('MMM yyyy').format(profile.createdAt!);

        return Scaffold(
          backgroundColor: EditProfileColors.background,
          body: Stack(
            children: [
              // Ambient backgrounds
              Positioned.fill(
                child: Container(
                  color: EditProfileColors.background,
                ),
              ),
              Positioned(
                top: -200,
                left: -200,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EditProfileColors.primary.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -200,
                right: -200,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EditProfileColors.secondary.withValues(alpha: 0.05),
                  ),
                ),
              ),

              // Content Scroll View
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Header Card (Hero)
                          ProfileHeaderCard(
                            email: profile.email,
                            tier: profile.tier,
                            role: profile.role,
                            fullNameController: _fullNameController,
                            usernameController: _usernameController,
                            avatarUrlController: _avatarUrlController,
                            onDiscard: _discardChanges,
                            onSave: _saveChanges,
                            isSaving: _isSaving,
                          ),
                          const SizedBox(height: 24),

                          // Responsive grid for sections
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isDesktop = constraints.maxWidth >= 1200;

                              if (isDesktop) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left Column: Forms, settings, integrations, security, devices, danger
                                    Expanded(
                                      flex: 8,
                                      child: Column(
                                        children: [
                                          PersonalInformationCard(
                                            fullNameController: _fullNameController,
                                            usernameController: _usernameController,
                                            bioController: _bioController,
                                            locationController: _locationController,
                                            selectedTimezone: _preferredTimezone,
                                            onTimezoneChanged: (val) {
                                              setState(() => _preferredTimezone = val);
                                            },
                                            selectedOccupation: _occupation,
                                            onOccupationChanged: (val) {
                                              setState(() => _occupation = val);
                                            },
                                            email: profile.email,
                                            createdAtLabel: createdAtLabel,
                                            avatarUrlLabel: profile.avatarUrl ?? 'None',
                                            skills: _skills,
                                            onSkillsChanged: (skills) {
                                              setState(() => _skills = skills);
                                            },
                                          ),
                                          const SizedBox(height: 24),
                                          AccountSettingsCard(
                                            themeMode: _themeMode,
                                            onThemeModeChanged: (mode) {
                                              setState(() => _themeMode = mode);
                                            },
                                            notificationsEnabled: _notificationsEnabled,
                                            onNotificationsEnabledChanged: (val) {
                                              setState(() => _notificationsEnabled = val);
                                            },
                                            privacyMode: _privacyMode,
                                            onPrivacyModeChanged: (val) {
                                              setState(() => _privacyMode = val);
                                            },
                                            aiCopilotEnabled: _aiCopilotEnabled,
                                            onAiCopilotEnabledChanged: (val) {
                                              setState(() => _aiCopilotEnabled = val);
                                            },
                                          ),
                                          const SizedBox(height: 24),
                                          const ConnectedAccountsCard(),
                                          const SizedBox(height: 24),
                                          SecurityCenterCard(
                                            twoFactorEnabled: true,
                                            onResetPassword: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Password reset link sent!')),
                                              );
                                            },
                                            onTwoFactorToggled: (val) {},
                                          ),
                                          const SizedBox(height: 24),
                                          const ActiveDevicesCard(),
                                          const SizedBox(height: 24),
                                          DangerZoneCard(
                                            onDeleteAccount: () {},
                                            onWipeData: () {},
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),

                                    // Right Column: completion, stats, distribution, insights, achievements, export
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        children: [
                                          ProfileCompletionCard(
                                            avatarUrlController: _avatarUrlController,
                                            usernameController: _usernameController,
                                            fullNameController: _fullNameController,
                                            bioController: _bioController,
                                          ),
                                          const SizedBox(height: 24),
                                          AiProfileInsightsCard(
                                            onApplySuggestions: () {
                                              setState(() {
                                                if (!_skills.contains('Cloud Architecture')) {
                                                  _skills.add('Cloud Architecture');
                                                }
                                              });
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Added Cloud Architecture to Skills!')),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 24),
                                          ProductivityStatsCard(
                                            focusScore: profile.focusScore,
                                            streakDays: profile.streakDays,
                                            focusHours: profile.focusHours,
                                            completedTasks: profile.completedTasks,
                                            totalTasks: profile.totalTasks,
                                          ),
                                          const SizedBox(height: 24),
                                          WorkDistributionCard(
                                            deepWorkPercent: profile.deepWorkPercent,
                                            adminPercent: profile.adminPercent,
                                            learningPercent: profile.learningPercent,
                                          ),
                                          const SizedBox(height: 24),
                                          const AchievementsCard(),
                                          const SizedBox(height: 24),
                                          ExportCenterCard(
                                            onExportJson: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('JSON export triggered!')),
                                              );
                                            },
                                            onExportCsv: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('CSV export triggered!')),
                                              );
                                            },
                                            onExportPdf: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('PDF export triggered!')),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                // Tablet & Mobile stacked layout
                                return Column(
                                  children: [
                                    ProfileCompletionCard(
                                      avatarUrlController: _avatarUrlController,
                                      usernameController: _usernameController,
                                      fullNameController: _fullNameController,
                                      bioController: _bioController,
                                    ),
                                    const SizedBox(height: 24),
                                    AiProfileInsightsCard(
                                      onApplySuggestions: () {
                                        setState(() {
                                          if (!_skills.contains('Cloud Architecture')) {
                                            _skills.add('Cloud Architecture');
                                          }
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Added Cloud Architecture to Skills!')),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    ProductivityStatsCard(
                                      focusScore: profile.focusScore,
                                      streakDays: profile.streakDays,
                                      focusHours: profile.focusHours,
                                      completedTasks: profile.completedTasks,
                                      totalTasks: profile.totalTasks,
                                    ),
                                    const SizedBox(height: 24),
                                    PersonalInformationCard(
                                      fullNameController: _fullNameController,
                                      usernameController: _usernameController,
                                      bioController: _bioController,
                                      locationController: _locationController,
                                      selectedTimezone: _preferredTimezone,
                                      onTimezoneChanged: (val) {
                                        setState(() => _preferredTimezone = val);
                                      },
                                      selectedOccupation: _occupation,
                                      onOccupationChanged: (val) {
                                        setState(() => _occupation = val);
                                      },
                                      email: profile.email,
                                      createdAtLabel: createdAtLabel,
                                      avatarUrlLabel: profile.avatarUrl ?? 'None',
                                      skills: _skills,
                                      onSkillsChanged: (skills) {
                                        setState(() => _skills = skills);
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    WorkDistributionCard(
                                      deepWorkPercent: profile.deepWorkPercent,
                                      adminPercent: profile.adminPercent,
                                      learningPercent: profile.learningPercent,
                                    ),
                                    const SizedBox(height: 24),
                                    AccountSettingsCard(
                                      themeMode: _themeMode,
                                      onThemeModeChanged: (mode) {
                                        setState(() => _themeMode = mode);
                                      },
                                      notificationsEnabled: _notificationsEnabled,
                                      onNotificationsEnabledChanged: (val) {
                                        setState(() => _notificationsEnabled = val);
                                      },
                                      privacyMode: _privacyMode,
                                      onPrivacyModeChanged: (val) {
                                        setState(() => _privacyMode = val);
                                      },
                                      aiCopilotEnabled: _aiCopilotEnabled,
                                      onAiCopilotEnabledChanged: (val) {
                                        setState(() => _aiCopilotEnabled = val);
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    const ConnectedAccountsCard(),
                                    const SizedBox(height: 24),
                                    SecurityCenterCard(
                                      twoFactorEnabled: true,
                                      onResetPassword: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Password reset link sent!')),
                                        );
                                      },
                                      onTwoFactorToggled: (val) {},
                                    ),
                                    const SizedBox(height: 24),
                                    const ActiveDevicesCard(),
                                    const SizedBox(height: 24),
                                    const AchievementsCard(),
                                    const SizedBox(height: 24),
                                    ExportCenterCard(
                                      onExportJson: () {},
                                      onExportCsv: () {},
                                      onExportPdf: () {},
                                    ),
                                    const SizedBox(height: 24),
                                    DangerZoneCard(
                                      onDeleteAccount: () {},
                                      onWipeData: () {},
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: EditProfileColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: EditProfileColors.primary,
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: EditProfileColors.background,
        body: Center(
          child: Text(
            'Error loading profile: $e',
            style: const TextStyle(color: EditProfileColors.error),
          ),
        ),
      ),
    );
  }
}
