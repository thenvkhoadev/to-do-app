import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:to_do_app/screens/profile/user_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showEdit = ref.watch(showEditProfileProvider);
    if (showEdit) {
      return const EditProfileScreen();
    }
    return const UserProfileScreen();
  }
}

