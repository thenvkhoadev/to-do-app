class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.email,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.occupation,
    this.tier = 'free',
    this.role = 'user',
    this.focusScore = 82,
    this.streakDays = 7,
    this.streakCount = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.totalTasks = 32,
    this.completedTasks = 18,
    this.focusHours = 24,
    this.deepWorkPercent = 62,
    this.adminPercent = 18,
    this.learningPercent = 20,
    this.themeMode = 'dark',
    this.notificationsEnabled = true,
    this.privacyMode = false,
    this.coreTech = const [],
    this.locationNode,
    this.preferredTimezone,
    this.createdAt,
    this.updatedAt,
    this.level = 1,
    this.currentXp = 0,
    this.totalXp = 0,
    this.nextLevelXp = 50,
    this.rankName = 'Rookie',
    this.rankDivision = 'V',
    this.rankTitle = 'Rookie V',
  });

  final String id;
  final String email;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final String? occupation;
  final String tier;
  final String role;
  final int focusScore;
  final int streakDays;
  final int streakCount;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final int totalTasks;
  final int completedTasks;
  final int focusHours;
  final int deepWorkPercent;
  final int adminPercent;
  final int learningPercent;
  final String themeMode;
  final bool notificationsEnabled;
  final bool privacyMode;
  final List<String> coreTech;
  final String? locationNode;
  final String? preferredTimezone;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int level;
  final int currentXp;
  final int totalXp;
  final int nextLevelXp;
  final String rankName;
  final String rankDivision;
  final String rankTitle;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'].toString(),
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString(),
      fullName: json['full_name']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      bio: json['bio']?.toString(),
      occupation: json['occupation']?.toString(),
      tier: json['tier']?.toString() ?? 'free',
      role: json['role']?.toString() ?? 'user',
      focusScore: json['focus_score'] as int? ?? 82,
      streakDays: json['streak_days'] as int? ?? json['streak_count'] as int? ?? 7,
      streakCount: json['streak_count'] as int? ?? json['streak_days'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastActivityDate:
          json['last_activity_date'] == null
              ? null
              : DateTime.tryParse(json['last_activity_date'].toString()),
      totalTasks: json['total_tasks'] as int? ?? 32,
      completedTasks: json['completed_tasks'] as int? ?? 18,
      focusHours: json['focus_hours'] as int? ?? 24,
      deepWorkPercent: json['deep_work_percent'] as int? ?? 62,
      adminPercent: json['admin_percent'] as int? ?? 18,
      learningPercent: json['learning_percent'] as int? ?? 20,
      themeMode: json['theme_mode']?.toString() ?? 'dark',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      privacyMode: json['privacy_mode'] as bool? ?? false,
      coreTech: List<String>.from(json['core_tech'] ?? []),
      locationNode: json['user_preferences']?['location_node']?.toString(),
      preferredTimezone:
          json['user_preferences']?['preferred_timezone']?.toString(),
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.tryParse(json['created_at'].toString()),
      updatedAt:
          json['updated_at'] == null
              ? null
              : DateTime.tryParse(json['updated_at'].toString()),
      level: (json['level'] as int? ?? json['llevel'] as int? ?? 1),
      currentXp: json['current_xp'] as int? ?? 0,
      totalXp: json['total_xp'] as int? ?? 0,
      nextLevelXp: json['next_level_xp'] as int? ?? 50,
      rankName: json['rank_name']?.toString() ?? 'Rookie',
      rankDivision: json['rank_division']?.toString() ?? 'V',
      rankTitle: json['rank_title']?.toString() ?? 'Rookie V',
    );
  }

  int get completionRate =>
      totalTasks == 0 ? 0 : ((completedTasks / totalTasks) * 100).round();

  /// Percentage (0-100) of identity fields that are filled in.
  int get profileCompletion {
    final checks = <bool>[
      (avatarUrl ?? '').trim().isNotEmpty,
      (username ?? '').trim().isNotEmpty,
      (fullName ?? '').trim().isNotEmpty,
      (bio ?? '').trim().isNotEmpty,
      email.trim().isNotEmpty,
    ];
    final filled = checks.where((c) => c).length;
    return ((filled / checks.length) * 100).round();
  }

  bool get isDarkMode => themeMode.toLowerCase() == 'dark';
}
