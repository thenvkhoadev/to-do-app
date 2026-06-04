import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/core/services/app_providers.dart';

class UserStatusState {
  final String status; // 'online' | 'idle' | 'dnd' | 'invisible'
  final String duration; // '1m' | '15m' | '1h' | '8h' | '24h' | '3d' | 'permanent'
  final DateTime? expiresAt;

  UserStatusState({
    required this.status,
    required this.duration,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
    'status': status,
    'duration': duration,
    'expiresAt': expiresAt?.toIso8601String(),
  };

  factory UserStatusState.fromJson(Map<String, dynamic> json) {
    return UserStatusState(
      status: json['status'] ?? 'online',
      duration: json['duration'] ?? 'permanent',
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt']) : null,
    );
  }

  UserStatusState copyWith({
    String? status,
    String? duration,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
  }) {
    return UserStatusState(
      status: status ?? this.status,
      duration: duration ?? this.duration,
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
    );
  }
}

class UserStatusNotifier extends StateNotifier<UserStatusState> {
  UserStatusNotifier(this._ref) : super(UserStatusState(status: 'online', duration: 'permanent')) {
    _loadStatus();
  }

  final Ref _ref;
  Timer? _expirationTimer;
  static const _storageKey = 'user_active_status';

  Future<void> _loadStatus() async {
    try {
      final storage = _ref.read(secureStorageServiceProvider);
      final raw = await storage.read(_storageKey);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final loaded = UserStatusState.fromJson(json);
        
        // Check if expired
        if (loaded.expiresAt != null && DateTime.now().isAfter(loaded.expiresAt!)) {
          // Revert to online
          state = UserStatusState(status: 'online', duration: 'permanent');
          await _saveStatus();
        } else {
          state = loaded;
          if (state.expiresAt != null) {
            _scheduleExpiration(state.expiresAt!);
          }
        }
      }
    } catch (_) {
      // Fallback is default online state
    }
  }

  Future<void> setStatus(String status, String duration) async {
    _expirationTimer?.cancel();
    
    DateTime? expiresAt;
    if (duration != 'permanent') {
      final now = DateTime.now();
      switch (duration) {
        case '1m':
          expiresAt = now.add(const Duration(minutes: 1));
          break;
        case '15m':
          expiresAt = now.add(const Duration(minutes: 15));
          break;
        case '1h':
          expiresAt = now.add(const Duration(hours: 1));
          break;
        case '8h':
          expiresAt = now.add(const Duration(hours: 8));
          break;
        case '24h':
          expiresAt = now.add(const Duration(hours: 24));
          break;
        case '3d':
          expiresAt = now.add(const Duration(days: 3));
          break;
      }
    }

    state = UserStatusState(
      status: status,
      duration: duration,
      expiresAt: expiresAt,
    );

    await _saveStatus();

    if (expiresAt != null) {
      _scheduleExpiration(expiresAt);
    }
  }

  void _scheduleExpiration(DateTime time) {
    _expirationTimer?.cancel();
    final difference = time.difference(DateTime.now());
    if (difference.isNegative) {
      _handleExpiration();
    } else {
      _expirationTimer = Timer(difference, _handleExpiration);
    }
  }

  Future<void> _handleExpiration() async {
    state = UserStatusState(status: 'online', duration: 'permanent');
    await _saveStatus();
  }

  Future<void> checkExpiration() async {
    if (state.expiresAt != null && DateTime.now().isAfter(state.expiresAt!)) {
      await _handleExpiration();
    }
  }

  Future<void> _saveStatus() async {
    try {
      final storage = _ref.read(secureStorageServiceProvider);
      final raw = jsonEncode(state.toJson());
      await storage.write(_storageKey, raw);
    } catch (_) {}
  }

  @override
  void dispose() {
    _expirationTimer?.cancel();
    super.dispose();
  }
}

final userStatusProvider = StateNotifierProvider<UserStatusNotifier, UserStatusState>((ref) {
  return UserStatusNotifier(ref);
});
