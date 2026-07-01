import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/core/services/app_providers.dart';

enum Workspace { task, social }

final activeWorkspaceProvider = NotifierProvider<ActiveWorkspaceNotifier, Workspace>(ActiveWorkspaceNotifier.new);

class ActiveWorkspaceNotifier extends Notifier<Workspace> {
  @override
  Workspace build() {
    _load();
    return Workspace.task;
  }

  static const _key = 'active_workspace';

  Future<void> _load() async {
    try {
      final storage = ref.read(secureStorageServiceProvider);
      final saved = await storage.read(_key);
      if (saved == 'social' && state != Workspace.social) {
        state = Workspace.social;
      }
    } catch (_) {}
  }

  Future<void> setWorkspace(Workspace ws) async {
    if (state == ws) return;
    state = ws;
    try {
      final storage = ref.read(secureStorageServiceProvider);
      await storage.write(_key, ws.name);
    } catch (_) {}
  }
}
