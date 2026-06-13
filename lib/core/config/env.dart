import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl => _required('SUPABASE_URL');
  static String get supabaseAnonKey => _required('SUPABASE_ANON_KEY');
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? supabaseUrl;
  static String get turnstileSiteKey => _required('TURNSTILE_SITE_KEY');
  static String get turnstileBaseUrl => dotenv.env['TURNSTILE_BASE_URL'] ?? apiBaseUrl;

  static String _required(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing $key in .env');
    }
    return value;
  }
}
