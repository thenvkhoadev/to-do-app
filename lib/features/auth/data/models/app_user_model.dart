import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/auth/domain/entities/app_user.dart';

class AppUserModel {
  const AppUserModel({
    required this.id,
    required this.email,
    this.username,
    this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String? username;
  final String? fullName;
  final String? avatarUrl;

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      id: json['id'].toString(),
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString(),
      fullName: json['full_name']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
    );
  }

  factory AppUserModel.fromSupabaseUser(User user) {
    return AppUserModel(
      id: user.id,
      email: user.email ?? '',
      username: user.userMetadata?['username']?.toString(),
      fullName: user.userMetadata?['full_name']?.toString(),
      avatarUrl: user.userMetadata?['avatar_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
    };
  }

  AppUser toEntity() {
    return AppUser(
      id: id,
      email: email,
      username: username,
      fullName: fullName,
      avatarUrl: avatarUrl,
    );
  }
}
