import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/profile/data/datasource/profile_remote_datasource.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((
  ref,
) {
  return ProfileRemoteDataSource(ref.watch(supabaseClientProvider));
});

final userProfileProvider = StreamProvider<UserProfileModel?>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(profileRemoteDataSourceProvider).watchProfile(user.id);
});
