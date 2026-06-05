class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    this.color,
    this.icon,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? color;
  final String? icon;
  final DateTime? createdAt;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        name: json['name']?.toString() ?? '',
        color: json['color']?.toString(),
        icon: json['icon']?.toString(),
        createdAt: json['created_at'] == null
            ? null
            : DateTime.tryParse(json['created_at'].toString()),
      );

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'name': name,
        'color': color,
        'icon': icon,
      };
}
