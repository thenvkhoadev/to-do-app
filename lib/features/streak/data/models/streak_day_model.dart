class StreakDayModel {
  const StreakDayModel({
    required this.id,
    required this.userId,
    required this.activeDate,
    required this.activityType,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final DateTime activeDate;
  final String activityType;
  final DateTime createdAt;

  factory StreakDayModel.fromJson(Map<String, dynamic> json) {
    return StreakDayModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      activeDate: DateTime.parse(json['active_date'].toString()),
      activityType: json['activity_type']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
