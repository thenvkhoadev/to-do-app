import 'package:flutter/foundation.dart';

@immutable
class XpLogModel {
  const XpLogModel({
    required this.id,
    required this.userId,
    this.taskId,
    required this.xpGained,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? taskId;
  final int xpGained;
  final String reason;
  final DateTime createdAt;

  factory XpLogModel.fromJson(Map<String, dynamic> json) {
    return XpLogModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      taskId: json['task_id']?.toString(),
      xpGained: json['xp_gained'] as int? ?? 0,
      reason: json['reason']?.toString() ?? '',
      createdAt: json['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['created_at'].toString()),
    );
  }

  /// Whether this log entry contains a lucky bonus (reason contains "Lucky").
  bool get hasLuckyBonus => reason.contains('Lucky');

  /// Base XP without the bonus — derived from priority XP tiers.
  /// We can't recover exact base from the reason alone, so expose full xpGained.
  int get baseXp {
    if (!hasLuckyBonus) return xpGained;
    // Lucky bonus values are 5, 10, or 15 — subtract smallest possible.
    // The exact split is shown in notification separately via the reason.
    return xpGained;
  }
}
