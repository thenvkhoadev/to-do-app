import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/core/config/env.dart';
import 'package:to_do_app/core/network/jwt_interceptor.dart';

Dio createDioClient(SupabaseClient client) {
  return Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(JwtInterceptor(client));
}
