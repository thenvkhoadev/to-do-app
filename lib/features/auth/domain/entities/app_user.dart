class AppUser {
  const AppUser({
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
}
