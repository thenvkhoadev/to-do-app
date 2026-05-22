import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/core/network/dio_api_client.dart';
import 'package:to_do_app/core/services/auth_service.dart';
import 'package:to_do_app/core/storage/secure_storage_service.dart';
import 'package:to_do_app/core/storage/session_storage.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(secureStorage);
});

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SessionStorage(ref.watch(secureStorageServiceProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider), ref.watch(sessionStorageProvider));
});

final dioProvider = Provider<Dio>((ref) {
  return createDioClient(ref.watch(supabaseClientProvider));
});
