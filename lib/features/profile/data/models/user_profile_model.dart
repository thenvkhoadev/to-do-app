class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.email,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.tier = 'free',
    this.role = 'user',
    this.focusScore = 82,
    this.streakDays = 7,
    this.totalTasks = 32,
    this.completedTasks = 18,
    this.focusHours = 24,
    this.deepWorkPercent = 62,
    this.adminPercent = 18,
    this.learningPercent = 20,
    this.themeMode = 'dark',
    this.notificationsEnabled = true,
    this.privacyMode = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final String tier;
  final String role;
  final int focusScore;
  final int streakDays;
  final int totalTasks;
  final int completedTasks;
  final int focusHours;
  final int deepWorkPercent;
  final int adminPercent;
  final int learningPercent;
  final String themeMode;
  final bool notificationsEnabled;
  final bool privacyMode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'].toString(),
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString(),
      fullName: json['full_name']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      bio: json['bio']?.toString(),
      tier: json['tier']?.toString() ?? 'free',
      role: json['role']?.toString() ?? 'user',
      focusScore: json['focus_score'] as int? ?? 82,
      streakDays: json['streak_days'] as int? ?? 7,
      totalTasks: json['total_tasks'] as int? ?? 32,
      completedTasks: json['completed_tasks'] as int? ?? 18,
      focusHours: json['focus_hours'] as int? ?? 24,
      deepWorkPercent: json['deep_work_percent'] as int? ?? 62,
      adminPercent: json['admin_percent'] as int? ?? 18,
      learningPercent: json['learning_percent'] as int? ?? 20,
      themeMode: json['theme_mode']?.toString() ?? 'dark',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      privacyMode: json['privacy_mode'] as bool? ?? false,
      createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at'].toString()),
      updatedAt: json['updated_at'] == null ? null : DateTime.tryParse(json['updated_at'].toString()),
    );
  }
}
