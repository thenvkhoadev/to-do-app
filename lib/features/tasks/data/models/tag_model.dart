class TagModel {
  const TagModel({
    required this.id,
    required this.userId,
    required this.name,
    this.color,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? color;
  final DateTime? createdAt;

  factory TagModel.fromJson(Map<String, dynamic> json) => TagModel(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        name: json['name']?.toString() ?? '',
        color: json['color']?.toString(),
        createdAt: json['created_at'] == null
            ? null
            : DateTime.tryParse(json['created_at'].toString()),
      );

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'name': name,
        'color': color,
      };
}
