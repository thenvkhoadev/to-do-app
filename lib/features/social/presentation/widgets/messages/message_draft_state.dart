import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/core/storage/secure_storage_service.dart';
import 'package:to_do_app/core/services/app_providers.dart';

class ConversationDraft {
  final String conversationId;
  final String draftText;
  final DateTime updatedAt;
  final int cursorPosition;
  final int selectionStart;
  final int selectionEnd;

  ConversationDraft({
    required this.conversationId,
    required this.draftText,
    required this.updatedAt,
    required this.cursorPosition,
    required this.selectionStart,
    required this.selectionEnd,
  });

  Map<String, dynamic> toJson() => {
    'conversationId': conversationId,
    'draftText': draftText,
    'updatedAt': updatedAt.toIso8601String(),
    'cursorPosition': cursorPosition,
    'selectionStart': selectionStart,
    'selectionEnd': selectionEnd,
  };

  factory ConversationDraft.fromJson(Map<String, dynamic> json) => ConversationDraft(
    conversationId: json['conversationId'] as String,
    draftText: json['draftText'] as String,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    cursorPosition: json['cursorPosition'] as int? ?? 0,
    selectionStart: json['selectionStart'] as int? ?? 0,
    selectionEnd: json['selectionEnd'] as int? ?? 0,
  );
}

abstract class DraftRepository {
  Future<void> saveDraft(ConversationDraft draft);
  Future<ConversationDraft?> getDraft(String conversationId);
  Future<void> deleteDraft(String conversationId);
  Future<List<ConversationDraft>> loadAllDrafts();
}

class LocalDraftRepository implements DraftRepository {
  final SecureStorageService _storage;
  static const String _prefix = 'draft_msg_';

  LocalDraftRepository(this._storage);

  @override
  Future<void> saveDraft(ConversationDraft draft) async {
    final key = '$_prefix${draft.conversationId}';
    final jsonStr = jsonEncode(draft.toJson());
    await _storage.write(key, jsonStr);
  }

  @override
  Future<ConversationDraft?> getDraft(String conversationId) async {
    final key = '$_prefix$conversationId';
    final jsonStr = await _storage.read(key);
    if (jsonStr == null) return null;
    try {
      return ConversationDraft.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteDraft(String conversationId) async {
    final key = '$_prefix$conversationId';
    await _storage.delete(key);
  }

  @override
  Future<List<ConversationDraft>> loadAllDrafts() async {
    final allData = await _storage.readAll();
    final List<ConversationDraft> drafts = [];
    for (final entry in allData.entries) {
      if (entry.key.startsWith(_prefix)) {
        try {
          final draft = ConversationDraft.fromJson(jsonDecode(entry.value) as Map<String, dynamic>);
          drafts.add(draft);
        } catch (_) {}
      }
    }
    return drafts;
  }
}

final draftRepositoryProvider = Provider<DraftRepository>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return LocalDraftRepository(secureStorage);
});

class MessageDraftsNotifier extends StateNotifier<Map<String, ConversationDraft>> {
  final DraftRepository _repository;

  MessageDraftsNotifier(this._repository) : super(const {}) {
    _init();
  }

  Future<void> _init() async {
    final list = await _repository.loadAllDrafts();
    final map = {for (var d in list) d.conversationId: d};
    state = map;
  }

  Future<void> saveDraft({
    required String conversationId,
    required String text,
    required int cursorPosition,
    required int selectionStart,
    required int selectionEnd,
  }) async {
    if (text.trim().isEmpty) {
      await deleteDraft(conversationId);
      return;
    }

    final draft = ConversationDraft(
      conversationId: conversationId,
      draftText: text,
      updatedAt: DateTime.now(),
      cursorPosition: cursorPosition,
      selectionStart: selectionStart,
      selectionEnd: selectionEnd,
    );

    state = {...state, conversationId: draft};
    await _repository.saveDraft(draft);
  }

  Future<void> deleteDraft(String conversationId) async {
    if (!state.containsKey(conversationId)) return;
    final newState = Map<String, ConversationDraft>.from(state)..remove(conversationId);
    state = newState;
    await _repository.deleteDraft(conversationId);
  }
}

final messageDraftsProvider = StateNotifierProvider<MessageDraftsNotifier, Map<String, ConversationDraft>>((ref) {
  final repo = ref.watch(draftRepositoryProvider);
  return MessageDraftsNotifier(repo);
});
