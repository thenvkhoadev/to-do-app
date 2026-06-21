import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/core/config/env.dart';

class JwtInterceptor extends Interceptor {
  JwtInterceptor(this._client);

  final SupabaseClient _client;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _client.auth.currentSession?.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      options.headers['apikey'] = Env.supabaseAnonKey;
      options.headers['X-Device-Name'] = 'Flutter Client';
      options.headers['X-Device-OS'] = defaultTargetPlatform.name.toLowerCase();
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401 ||
        err.requestOptions.extra['retried'] == true) {
      handler.next(err);
      return;
    }

    try {
      await _client.auth.refreshSession();
      final token = _client.auth.currentSession?.accessToken;
      if (token == null) {
        handler.next(err);
        return;
      }

      final request = err.requestOptions;
      request.extra['retried'] = true;
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['X-Device-Name'] = 'Flutter Client';
      request.headers['X-Device-OS'] = defaultTargetPlatform.name.toLowerCase();
      final response = await Dio().fetch<dynamic>(request);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }
}
