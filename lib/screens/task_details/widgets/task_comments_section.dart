import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';


class AttachmentModel {
  final String name;
  final bool isImage;
  final String? localPath;
  final Uint8List? bytes;

  AttachmentModel({
    required this.name,
    required this.isImage,
    this.localPath,
    this.bytes,
  });
}

class VoiceNoteModel {
  final int durationSeconds;
  final List<double> waveData;
  final String audioUrl;

  VoiceNoteModel({
    required this.durationSeconds,
    required this.waveData,
    required this.audioUrl,
  });
}

class ReplyModel {
  final String id;
  final String authorInitials;
  final String authorName;
  final String? authorAvatarUrl;
  final String text;
  final DateTime timestamp;
  final AttachmentModel? attachment;
  final VoiceNoteModel? voiceNote;
  final Map<String, int> reactions;
  final List<String> reactedEmojis;
  final List<ReplyModel> replies;
  final bool isTaskCreator;

  ReplyModel({
    required this.id,
    required this.authorInitials,
    required this.authorName,
    this.authorAvatarUrl,
    required this.text,
    required this.timestamp,
    this.attachment,
    this.voiceNote,
    required this.reactions,
    required this.reactedEmojis,
    required this.replies,
    this.isTaskCreator = false,
  });
}

class CommentModel {
  final String id;
  final String authorInitials;
  final String authorName;
  final String? authorAvatarUrl;
  final String text;
  final DateTime timestamp;
  final AttachmentModel? attachment;
  final VoiceNoteModel? voiceNote;
  final Map<String, int> reactions;
  final List<String> reactedEmojis;
  final List<ReplyModel> replies;
  final bool isTaskCreator;

  CommentModel({
    required this.id,
    required this.authorInitials,
    required this.authorName,
    this.authorAvatarUrl,
    required this.text,
    required this.timestamp,
    this.attachment,
    this.voiceNote,
    required this.reactions,
    required this.reactedEmojis,
    required this.replies,
    this.isTaskCreator = false,
  });
}

class TaskCommentsNotifier extends FamilyNotifier<List<CommentModel>, String> {
  final Map<String, Future<void>> _locks = {};

  @override
  List<CommentModel> build(String arg) {
    _loadComments(arg);
    return [];
  }

  Future<void> _loadComments(String taskId) async {
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;

      // 1. Fetch task details to identify task creator
      final taskData = await supabase
          .from('tasks')
          .select('user_id')
          .eq('id', taskId)
          .maybeSingle();
      final taskCreatorId = taskData != null ? taskData['user_id'] as String? : null;

      // 2. Fetch all comments for this task
      final List<dynamic> rawComments = await supabase
          .from('comments')
          .select('*, users:user_id(id, email, username, full_name, avatar_url), comment_reactions(*), comment_attachments(*)')
          .eq('task_id', taskId)
          .order('created_at', ascending: true);

      final mainComments = <CommentModel>[];
      final visualRepliesMap = <String, List<ReplyModel>>{};
      final visualParentIdMap = <String, String>{};
      final authorIdMap = <String, String>{};

      for (final raw in rawComments) {
        final id = raw['id'] as String;
        final userId = raw['user_id'] as String;
        final parentId = raw['parent_comment_id'] as String?;
        final isTaskCreator = taskCreatorId != null && userId == taskCreatorId;

        final userMap = raw['users'] as Map<String, dynamic>? ?? {};
        final authorName = userMap['full_name'] as String? ?? 
            userMap['username'] as String? ?? 
            userMap['email'] as String? ?? 
            'User';
        final authorAvatarUrl = userMap['avatar_url'] as String?;

        final names = authorName.trim().split(' ');
        String initials = 'U';
        if (names.isNotEmpty) {
          if (names.length >= 2 && names[0].isNotEmpty && names[1].isNotEmpty) {
            initials = '${names[0][0]}${names[1][0]}'.toUpperCase();
          } else if (names[0].isNotEmpty) {
            initials = names[0][0].toUpperCase();
          }
        }

        // Reactions
        final reactionsMap = <String, int>{};
        final reactedEmojis = <String>[];
        final List<dynamic> rawReactions = raw['comment_reactions'] as List<dynamic>? ?? [];
        for (final rx in rawReactions) {
          final emoji = rx['reaction'] as String;
          reactionsMap[emoji] = (reactionsMap[emoji] ?? 0) + 1;
          if (rx['user_id'] == currentUserId && !reactedEmojis.contains(emoji)) {
            reactedEmojis.add(emoji);
          }
        }

        // Attachments
        AttachmentModel? attachment;
        VoiceNoteModel? voiceNote;
        final List<dynamic> rawAtts = raw['comment_attachments'] as List<dynamic>? ?? [];
        if (rawAtts.isNotEmpty) {
          final att = rawAtts.first;
          final url = att['file_url'] as String;
          final name = att['file_name'] as String;
          final mime = att['mime_type'] as String?;
          if (mime == 'audio/wav' || mime == 'audio/m4a' || url.startsWith('voice://') || url.contains('.wav') || url.contains('.m4a')) {
            int duration = 5;
            List<double> waves = [0.4, 0.6, 0.3, 0.7];
            try {
              final uri = Uri.parse(url);
              final durParam = uri.queryParameters['duration'];
              if (durParam != null) {
                duration = int.tryParse(durParam) ?? 5;
              }
              final wavesStr = uri.queryParameters['waves'] ?? '';
              if (wavesStr.isNotEmpty) {
                waves = wavesStr.split(',').map((w) => double.tryParse(w) ?? 0.5).toList();
              }
            } catch (_) {}
            voiceNote = VoiceNoteModel(
              durationSeconds: duration,
              waveData: waves,
              audioUrl: url,
            );
          } else {
            final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(name.split('.').last.toLowerCase());
            attachment = AttachmentModel(name: name, isImage: isImage);
          }
        }

        if (parentId == null) {
          // Main comment
          final replies = visualRepliesMap.putIfAbsent(id, () => []);
          final comment = CommentModel(
            id: id,
            authorInitials: initials,
            authorName: authorName,
            authorAvatarUrl: authorAvatarUrl,
            text: raw['content'] as String? ?? '',
            timestamp: DateTime.tryParse(raw['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
            attachment: attachment,
            voiceNote: voiceNote,
            reactions: reactionsMap,
            reactedEmojis: reactedEmojis,
            replies: replies,
            isTaskCreator: isTaskCreator,
          );
          mainComments.add(comment);
          authorIdMap[id] = userId;
        } else {
          // Reply
          final dbParentId = parentId;
          String visualParentId = dbParentId;

          // Determine visualParentId:
          // If the DB parent is not a main comment (its ID is not in mainComments ID set) and is a reply:
          final isDbParentMainComment = authorIdMap.containsKey(dbParentId) && !visualParentIdMap.containsKey(dbParentId);
          if (!isDbParentMainComment) {
            // DB parent is a reply
            final parentAuthorId = authorIdMap[dbParentId];
            if (userId == parentAuthorId) {
              // Same author, so visual parent is the visual parent of the DB parent
              visualParentId = visualParentIdMap[dbParentId] ?? dbParentId;
            } else {
              // Different author, so visual parent is the DB parent (indented)
              visualParentId = dbParentId;
            }
          }

          final replies = visualRepliesMap.putIfAbsent(id, () => []);
          final reply = ReplyModel(
            id: id,
            authorInitials: initials,
            authorName: authorName,
            authorAvatarUrl: authorAvatarUrl,
            text: raw['content'] as String? ?? '',
            timestamp: DateTime.tryParse(raw['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
            attachment: attachment,
            voiceNote: voiceNote,
            reactions: reactionsMap,
            reactedEmojis: reactedEmojis,
            replies: replies,
            isTaskCreator: isTaskCreator,
          );

          visualRepliesMap.putIfAbsent(visualParentId, () => []).add(reply);
          visualParentIdMap[id] = visualParentId;
          authorIdMap[id] = userId;
        }
      }

      state = mainComments;
    } catch (e) {
      debugPrint('Error loading comments: $e');
    }
  }

  Future<String> _uploadAttachment(String userId, AttachmentModel attachment) async {
    final supabase = Supabase.instance.client;
    String fileUrl = 'https://mock.storage/files/${attachment.name}';
    if (attachment.bytes != null) {
      try {
        final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_${attachment.name}';
        await supabase.storage.from('comment-attachments').uploadBinary(
          path,
          attachment.bytes!,
          fileOptions: const FileOptions(upsert: true),
        );
        fileUrl = supabase.storage.from('comment-attachments').getPublicUrl(path);
      } catch (e) {
        debugPrint('Error uploading comment attachment to Supabase: $e');
      }
    }
    return fileUrl;
  }

  Future<String> _uploadVoiceNote(String userId, VoiceNoteModel voiceNote) async {
    final supabase = Supabase.instance.client;
    final file = File(voiceNote.audioUrl);
    if (!await file.exists()) {
      debugPrint('Voice note file not found at ${voiceNote.audioUrl}');
      return '';
    }
    
    try {
      final bytes = await file.readAsBytes();
      final ext = voiceNote.audioUrl.split('.').last.toLowerCase();
      final mimeType = ext == 'wav' ? 'audio/wav' : 'audio/m4a';
      final fileName = 'VoiceNote_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = '$userId/$fileName';

      await supabase.storage.from('comment-attachments').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: mimeType, upsert: true),
      );
      final publicUrl = supabase.storage.from('comment-attachments').getPublicUrl(path);
      return '$publicUrl?duration=${voiceNote.durationSeconds}&waves=${voiceNote.waveData.join(',')}';
    } catch (e) {
      debugPrint('Error uploading comment voice to Supabase: $e');
      return '';
    }
  }

  CommentModel _appendReplyToComment(CommentModel comment, String parentId, ReplyModel newReply) {
    if (comment.id == parentId) {
      return CommentModel(
        id: comment.id,
        authorInitials: comment.authorInitials,
        authorName: comment.authorName,
        authorAvatarUrl: comment.authorAvatarUrl,
        text: comment.text,
        timestamp: comment.timestamp,
        attachment: comment.attachment,
        voiceNote: comment.voiceNote,
        reactions: comment.reactions,
        reactedEmojis: comment.reactedEmojis,
        replies: [...comment.replies, newReply],
        isTaskCreator: comment.isTaskCreator,
      );
    }
    
    bool found = false;
    final updatedReplies = comment.replies.map((r) {
      final updated = _appendReplyToReply(r, parentId, newReply);
      if (updated != r) found = true;
      return updated;
    }).toList();
    
    if (found) {
      return CommentModel(
        id: comment.id,
        authorInitials: comment.authorInitials,
        authorName: comment.authorName,
        authorAvatarUrl: comment.authorAvatarUrl,
        text: comment.text,
        timestamp: comment.timestamp,
        attachment: comment.attachment,
        voiceNote: comment.voiceNote,
        reactions: comment.reactions,
        reactedEmojis: comment.reactedEmojis,
        replies: updatedReplies,
        isTaskCreator: comment.isTaskCreator,
      );
    }
    
    return comment;
  }

  ReplyModel _appendReplyToReply(ReplyModel reply, String parentId, ReplyModel newReply) {
    if (reply.id == parentId) {
      return ReplyModel(
        id: reply.id,
        authorInitials: reply.authorInitials,
        authorName: reply.authorName,
        authorAvatarUrl: reply.authorAvatarUrl,
        text: reply.text,
        timestamp: reply.timestamp,
        attachment: reply.attachment,
        voiceNote: reply.voiceNote,
        reactions: reply.reactions,
        reactedEmojis: reply.reactedEmojis,
        replies: [...reply.replies, newReply],
      );
    }
    
    bool found = false;
    final updatedReplies = reply.replies.map((r) {
      final updated = _appendReplyToReply(r, parentId, newReply);
      if (updated != r) found = true;
      return updated;
    }).toList();
    
    if (found) {
      return ReplyModel(
        id: reply.id,
        authorInitials: reply.authorInitials,
        authorName: reply.authorName,
        authorAvatarUrl: reply.authorAvatarUrl,
        text: reply.text,
        timestamp: reply.timestamp,
        attachment: reply.attachment,
        voiceNote: reply.voiceNote,
        reactions: reply.reactions,
        reactedEmojis: reply.reactedEmojis,
        replies: updatedReplies,
      );
    }
    
    return reply;
  }

  Future<void> addComment({
    required String authorName,
    required String text,
    AttachmentModel? attachment,
    VoiceNoteModel? voiceNote,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Optimistic update for voice notes
      if (voiceNote != null) {
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final tempVoice = VoiceNoteModel(
          durationSeconds: voiceNote.durationSeconds,
          waveData: voiceNote.waveData,
          audioUrl: 'temp_uploading',
        );
        final tempComment = CommentModel(
          id: tempId,
          authorInitials: authorName.isNotEmpty ? authorName.substring(0, 1).toUpperCase() : 'U',
          authorName: authorName,
          authorAvatarUrl: null,
          text: text,
          timestamp: DateTime.now(),
          voiceNote: tempVoice,
          reactions: {},
          reactedEmojis: [],
          replies: [],
        );
        state = [...state, tempComment];
      }

      final insertedComment = await supabase.from('comments').insert({
        'task_id': arg,
        'user_id': currentUserId,
        'content': text,
      }).select().single();

      final newCommentId = insertedComment['id'] as String;

      if (attachment != null) {
        final fileUrl = await _uploadAttachment(currentUserId, attachment);
        await supabase.from('comment_attachments').insert({
          'comment_id': newCommentId,
          'file_name': attachment.name,
          'file_url': fileUrl,
          'mime_type': attachment.isImage ? 'image/png' : 'application/pdf',
        });
      } else if (voiceNote != null) {
        final fileUrl = await _uploadVoiceNote(currentUserId, voiceNote);
        await supabase.from('comment_attachments').insert({
          'comment_id': newCommentId,
          'file_name': 'VoiceNote_${voiceNote.durationSeconds}s.wav',
          'file_url': fileUrl,
          'mime_type': 'audio/wav',
        });
      }

      await _loadComments(arg);
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  Future<void> addReply({
    required String commentId,
    required String authorName,
    required String text,
    AttachmentModel? attachment,
    VoiceNoteModel? voiceNote,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Optimistic update for voice notes
      if (voiceNote != null) {
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final tempVoice = VoiceNoteModel(
          durationSeconds: voiceNote.durationSeconds,
          waveData: voiceNote.waveData,
          audioUrl: 'temp_uploading',
        );
        final tempReply = ReplyModel(
          id: tempId,
          authorInitials: authorName.isNotEmpty ? authorName.substring(0, 1).toUpperCase() : 'U',
          authorName: authorName,
          authorAvatarUrl: null,
          text: text,
          timestamp: DateTime.now(),
          voiceNote: tempVoice,
          reactions: {},
          reactedEmojis: [],
          replies: [],
        );
        state = state.map((c) => _appendReplyToComment(c, commentId, tempReply)).toList();
      }

      final insertedReply = await supabase.from('comments').insert({
        'task_id': arg,
        'user_id': currentUserId,
        'parent_comment_id': commentId,
        'content': text,
      }).select().single();

      final newReplyId = insertedReply['id'] as String;

      if (attachment != null) {
        final fileUrl = await _uploadAttachment(currentUserId, attachment);
        await supabase.from('comment_attachments').insert({
          'comment_id': newReplyId,
          'file_name': attachment.name,
          'file_url': fileUrl,
          'mime_type': attachment.isImage ? 'image/png' : 'application/pdf',
        });
      } else if (voiceNote != null) {
        final fileUrl = await _uploadVoiceNote(currentUserId, voiceNote);
        await supabase.from('comment_attachments').insert({
          'comment_id': newReplyId,
          'file_name': 'VoiceNote_${voiceNote.durationSeconds}s.wav',
          'file_url': fileUrl,
          'mime_type': 'audio/wav',
        });
      }

      await _loadComments(arg);
    } catch (e) {
      debugPrint('Error adding reply: $e');
    }
  }

  Future<void> toggleReaction(String commentId, String emoji) async {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    // 1. Optimistic update
    state = _mutateReactionInState(state, commentId, emoji);

    // 2. Queue DB operation
    final currentLock = _locks[commentId] ?? Future.value();
    _locks[commentId] = currentLock.then((_) async {
      try {
        final existing = await supabase
            .from('comment_reactions')
            .select()
            .eq('comment_id', commentId)
            .eq('user_id', currentUserId)
            .eq('reaction', emoji)
            .maybeSingle();

        if (existing != null) {
          await supabase
              .from('comment_reactions')
              .delete()
              .eq('comment_id', commentId)
              .eq('user_id', currentUserId)
              .eq('reaction', emoji);
        } else {
          await supabase.from('comment_reactions').insert({
            'comment_id': commentId,
            'user_id': currentUserId,
            'reaction': emoji,
          });
        }
      } catch (e) {
        debugPrint('Error toggling reaction: $e');
        await _loadComments(arg);
      }
    });
  }

  List<CommentModel> _mutateReactionInState(List<CommentModel> list, String targetId, String emoji) {
    return list.map((comment) {
      if (comment.id == targetId) {
        final reacted = List<String>.from(comment.reactedEmojis);
        final reacts = Map<String, int>.from(comment.reactions);
        if (reacted.contains(emoji)) {
          reacted.remove(emoji);
          if (reacts.containsKey(emoji)) {
            reacts[emoji] = reacts[emoji]! - 1;
            if (reacts[emoji]! <= 0) {
              reacts.remove(emoji);
            }
          }
        } else {
          reacted.add(emoji);
          reacts[emoji] = (reacts[emoji] ?? 0) + 1;
        }
        return CommentModel(
          id: comment.id,
          authorInitials: comment.authorInitials,
          authorName: comment.authorName,
          authorAvatarUrl: comment.authorAvatarUrl,
          text: comment.text,
          timestamp: comment.timestamp,
          attachment: comment.attachment,
          voiceNote: comment.voiceNote,
          reactions: reacts,
          reactedEmojis: reacted,
          replies: comment.replies,
          isTaskCreator: comment.isTaskCreator,
        );
      } else {
        final updatedReplies = _mutateReactionInReplies(comment.replies, targetId, emoji);
        return CommentModel(
          id: comment.id,
          authorInitials: comment.authorInitials,
          authorName: comment.authorName,
          authorAvatarUrl: comment.authorAvatarUrl,
          text: comment.text,
          timestamp: comment.timestamp,
          attachment: comment.attachment,
          voiceNote: comment.voiceNote,
          reactions: comment.reactions,
          reactedEmojis: comment.reactedEmojis,
          replies: updatedReplies,
          isTaskCreator: comment.isTaskCreator,
        );
      }
    }).toList();
  }

  List<ReplyModel> _mutateReactionInReplies(List<ReplyModel> list, String targetId, String emoji) {
    return list.map((reply) {
      if (reply.id == targetId) {
        final reacted = List<String>.from(reply.reactedEmojis);
        final reacts = Map<String, int>.from(reply.reactions);
        if (reacted.contains(emoji)) {
          reacted.remove(emoji);
          if (reacts.containsKey(emoji)) {
            reacts[emoji] = reacts[emoji]! - 1;
            if (reacts[emoji]! <= 0) {
              reacts.remove(emoji);
            }
          }
        } else {
          reacted.add(emoji);
          reacts[emoji] = (reacts[emoji] ?? 0) + 1;
        }
        return ReplyModel(
          id: reply.id,
          authorInitials: reply.authorInitials,
          authorName: reply.authorName,
          authorAvatarUrl: reply.authorAvatarUrl,
          text: reply.text,
          timestamp: reply.timestamp,
          attachment: reply.attachment,
          voiceNote: reply.voiceNote,
          reactions: reacts,
          reactedEmojis: reacted,
          replies: reply.replies,
          isTaskCreator: reply.isTaskCreator,
        );
      } else {
        final updatedReplies = _mutateReactionInReplies(reply.replies, targetId, emoji);
        return ReplyModel(
          id: reply.id,
          authorInitials: reply.authorInitials,
          authorName: reply.authorName,
          authorAvatarUrl: reply.authorAvatarUrl,
          text: reply.text,
          timestamp: reply.timestamp,
          attachment: reply.attachment,
          voiceNote: reply.voiceNote,
          reactions: reply.reactions,
          reactedEmojis: reply.reactedEmojis,
          replies: updatedReplies,
          isTaskCreator: reply.isTaskCreator,
        );
      }
    }).toList();
  }
}

final taskCommentsProvider = NotifierProviderFamily<TaskCommentsNotifier, List<CommentModel>, String>(
  TaskCommentsNotifier.new,
);

class TaskCommentsSection extends ConsumerStatefulWidget {
  const TaskCommentsSection({required this.taskId, this.isPanel = false, super.key});
  
  final String taskId;
  final bool isPanel;

  @override
  ConsumerState<TaskCommentsSection> createState() => _TaskCommentsSectionState();
}

class _TaskCommentsSectionState extends ConsumerState<TaskCommentsSection> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _audioRecorder = AudioRecorder();
  
  String? _replyingToCommentId;
  String? _replyingToAuthorName;
  
  AttachmentModel? _pendingAttachment;
  VoiceNoteModel? _pendingVoiceNote;
  
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  bool _showMentions = false;
  String _mentionSearch = '';
  int _mentionIndex = -1;

  String? _activeEmojiPickerCommentId;
  String? _justClickedCommentId;
  bool _isReactionCapsuleExpanded = false;
  bool _isSubmitting = false;

  bool _showEmojiPicker = false;

  void _insertEmoji(String emoji) {
    final text = _controller.text;
    final selection = _controller.selection;
    final cursorPosition = selection.isValid ? selection.baseOffset : text.length;
    
    final newText = text.substring(0, cursorPosition) + emoji + text.substring(cursorPosition);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorPosition + emoji.length),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _audioRecorder.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    final val = _controller.value;
    final selection = val.selection;
    if (selection.isValid && selection.isCollapsed) {
      final cursorPosition = selection.baseOffset;
      final textBeforeCursor = text.substring(0, cursorPosition);
      final lastAtIndex = textBeforeCursor.lastIndexOf('@');
      if (lastAtIndex != -1) {
        final textAfterAt = textBeforeCursor.substring(lastAtIndex + 1);
        if (!textAfterAt.contains(' ')) {
          setState(() {
            _showMentions = true;
            _mentionSearch = textAfterAt;
            _mentionIndex = lastAtIndex;
          });
          return;
        }
      }
    }
    if (_showMentions) {
      setState(() {
        _showMentions = false;
      });
    }
  }

  void _insertMention(String name) {
    if (_mentionIndex != -1) {
      final text = _controller.text;
      final before = text.substring(0, _mentionIndex);
      final selection = _controller.value.selection;
      final cursor = selection.isValid ? selection.baseOffset : text.length;
      final after = text.substring(cursor);
      
      _controller.text = '$before@$name $after';
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _mentionIndex + name.length + 2),
      );
      setState(() {
        _showMentions = false;
      });
      _focusNode.requestFocus();
    }
  }

  void _postComment(String actorName) async {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingAttachment == null && _pendingVoiceNote == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_replyingToCommentId != null) {
        await ref.read(taskCommentsProvider(widget.taskId).notifier).addReply(
          commentId: _replyingToCommentId!,
          authorName: actorName,
          text: text,
          attachment: _pendingAttachment,
          voiceNote: _pendingVoiceNote,
        );
      } else {
        await ref.read(taskCommentsProvider(widget.taskId).notifier).addComment(
          authorName: actorName,
          text: text,
          attachment: _pendingAttachment,
          voiceNote: _pendingVoiceNote,
        );
      }
      _controller.clear();
      setState(() {
        _replyingToCommentId = null;
        _replyingToAuthorName = null;
        _pendingAttachment = null;
        _pendingVoiceNote = null;
      });
    } catch (e) {
      debugPrint('Error posting comment: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _recordingSeconds = 0;
        });

        _recordingTimer?.cancel();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingSeconds++;
          });
        });
      } else {
        debugPrint('Microphone permission denied');
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  void _stopRecording(bool save) async {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    try {
      final path = await _audioRecorder.stop();
      if (save && _recordingSeconds > 0 && path != null) {
        final random = math.Random();
        final finalWaves = List.generate(24, (_) => 0.1 + random.nextDouble() * 0.8);
        setState(() {
          _pendingVoiceNote = VoiceNoteModel(
            durationSeconds: _recordingSeconds,
            waveData: finalWaves,
            audioUrl: path,
          );
          _isRecording = false;
        });
      } else {
        setState(() {
          _isRecording = false;
        });
        if (path != null) {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  void _showMockFilePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final mockFiles = [
          AttachmentModel(name: 'Architecture_Layout.png', isImage: true),
          AttachmentModel(name: 'Database_Specs.pdf', isImage: false),
          AttachmentModel(name: 'API_Ref_Sheet.pdf', isImage: false),
          AttachmentModel(name: 'Mockup_v2.jpg', isImage: true),
        ];

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select File to Attach',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...mockFiles.map((file) {
                  return ListTile(
                    leading: Icon(
                      file.isImage ? Icons.image_rounded : Icons.insert_drive_file_rounded,
                      color: DashboardColors.primary,
                    ),
                    title: Text(file.name, style: const TextStyle(color: Colors.white70)),
                    onTap: () {
                      setState(() {
                        _pendingAttachment = file;
                      });
                      Navigator.of(context).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDeviceFile() async {
    try {
      final result = await FilePicker.pickFiles(withData: true);
      if (result != null) {
        final file = result.files.single;
        final name = file.name;
        final ext = file.extension?.toLowerCase() ?? '';
        final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
        setState(() {
          _pendingAttachment = AttachmentModel(
            name: name,
            isImage: isImage,
            bytes: file.bytes,
            localPath: file.path,
          );
        });
      }
    } catch (e) {
      _showMockFilePicker();
    }
  }

  Widget _buildSmartCommentChips() {
    final templates = [
      '✨ Looks great!',
      '⚠️ Reviewing blockers',
      '💬 Needs design sync',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: templates.map((t) {
        return InkWell(
          onTap: () {
            _controller.text = t;
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: DashboardColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: DashboardColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              t,
              style: const TextStyle(
                color: DashboardColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  static String _ago(DateTime dt) {
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.isNegative) return 'Just now';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildReplyItem(
    CommentModel mainComment,
    ReplyModel reply, {
    required bool isLast,
    required String actorName,
    required double startX,
  }) {
    final rAgo = _ago(reply.timestamp);
    final isReactionPickerActive = _activeEmojiPickerCommentId == reply.id;

    return CustomPaint(
      painter: _ReplyConnectionPainter(
        isLast: isLast,
        lineColor: Colors.white.withValues(alpha: 0.15),
        startX: startX,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          DashboardColors.secondary,
                          DashboardColors.outline,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(1.2),
                    child: ClipOval(
                      child: reply.authorAvatarUrl != null && reply.authorAvatarUrl!.isNotEmpty
                          ? Image.network(
                              reply.authorAvatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.black38,
                                child: Center(
                                  child: Text(
                                    reply.authorInitials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.black38,
                              child: Center(
                                child: Text(
                                  reply.authorInitials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  if (reply.replies.isNotEmpty)
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 1.5,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MouseRegion(
                      onExit: (_) {
                        if (_activeEmojiPickerCommentId == reply.id) {
                          setState(() {
                            _activeEmojiPickerCommentId = null;
                            _isReactionCapsuleExpanded = false;
                          });
                        }
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        reply.authorName,
                                        style: const TextStyle(
                                          color: DashboardColors.onSurface,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (reply.isTaskCreator) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: DashboardColors.primary.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: DashboardColors.primary.withValues(alpha: 0.3), width: 0.5),
                                          ),
                                          child: const Text(
                                            'Author',
                                            style: TextStyle(
                                              color: DashboardColors.primary,
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    rAgo,
                                    style: const TextStyle(
                                      color: DashboardColors.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              _buildFormattedCommentText(reply.text),
                              if (reply.attachment != null) ...[
                                const SizedBox(height: 6),
                                _buildAttachmentCard(reply.attachment!),
                              ],
                              if (reply.voiceNote != null) ...[
                                const SizedBox(height: 6),
                                _VoicePlayer(voiceNote: reply.voiceNote!),
                              ],
                              const SizedBox(height: 6),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 16,
                                runSpacing: 4,
                                children: [
                                  MouseRegion(
                                    onEnter: (event) {
                                      if (event.kind == PointerDeviceKind.touch) return;
                                      if (_justClickedCommentId != reply.id) {
                                        setState(() {
                                          _activeEmojiPickerCommentId = reply.id;
                                        });
                                      }
                                    },
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _justClickedCommentId = reply.id;
                                          _activeEmojiPickerCommentId = null;
                                        });
                                        Future.delayed(const Duration(milliseconds: 2000), () {
                                          if (mounted) {
                                            setState(() {
                                              _justClickedCommentId = null;
                                            });
                                          }
                                        });
 
                                        final notifier = ref.read(taskCommentsProvider(widget.taskId).notifier);
                                        if (reply.reactedEmojis.isNotEmpty) {
                                          for (final emoji in reply.reactedEmojis) {
                                            notifier.toggleReaction(reply.id, emoji);
                                          }
                                        } else {
                                          notifier.toggleReaction(reply.id, '👍');
                                        }
                                      },
                                      onLongPress: () {
                                        setState(() {
                                          _activeEmojiPickerCommentId = (_activeEmojiPickerCommentId == reply.id) ? null : reply.id;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                        child: Icon(
                                          Icons.thumb_up_outlined,
                                          color: reply.reactedEmojis.isNotEmpty
                                              ? DashboardColors.primary
                                              : (isReactionPickerActive ? DashboardColors.primary : DashboardColors.onSurfaceVariant),
                                          size: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _replyingToCommentId = reply.id;
                                        _replyingToAuthorName = reply.authorName;
                                        final isSelf = reply.authorName == actorName;
                                        if (!isSelf) {
                                          final mentionString = '@${reply.authorName} ';
                                          if (!_controller.text.startsWith(mentionString)) {
                                            _controller.text = '$mentionString${_controller.text}';
                                          }
                                        }
                                        _controller.selection = TextSelection.fromPosition(
                                          TextPosition(offset: _controller.text.length),
                                        );
                                      });
                                      _focusNode.requestFocus();
                                    },
                                    child: const Text(
                                      'Reply',
                                      style: TextStyle(
                                        color: DashboardColors.onSurfaceVariant,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  _buildReactionsBadgeList(
                                    commentId: reply.id,
                                    reactions: reply.reactions,
                                    reactedEmojis: reply.reactedEmojis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (isReactionPickerActive)
                            Positioned(
                              left: 0,
                              bottom: 24,
                              child: TapRegion(
                                onTapOutside: (event) {
                                  setState(() {
                                    _activeEmojiPickerCommentId = null;
                                    _isReactionCapsuleExpanded = false;
                                  });
                                },
                                child: _buildFloatingReactionCapsule(reply.id),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (reply.replies.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.only(left: 30),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          clipBehavior: Clip.none,
                          itemCount: reply.replies.length,
                          itemBuilder: (context, rIdx) {
                            return _buildReplyItem(
                              mainComment,
                              reply.replies[rIdx],
                              isLast: rIdx == reply.replies.length - 1,
                              actorName: actorName,
                              startX: -53.0,
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(taskCommentsProvider(widget.taskId));
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final actorName = userProfile?.fullName ?? userProfile?.username ?? userProfile?.email ?? 'You';
    final allUsers = ref.watch(allUsersProvider).valueOrNull ?? [];

    int countReplies(ReplyModel reply) {
      int count = 1;
      for (final r in reply.replies) {
        count += countReplies(r);
      }
      return count;
    }

    int totalCommentsCount = 0;
    for (final c in comments) {
      totalCommentsCount += 1;
      for (final r in c.replies) {
        totalCommentsCount += countReplies(r);
      }
    }

    final matchingUsers = allUsers.where((u) {
      final name = (u.fullName ?? u.username ?? u.email).toLowerCase();
      return name.contains(_mentionSearch.toLowerCase());
    }).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Comments',
                    style: TextStyle(
                      color: DashboardColors.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.01,
                      height: 1.3,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: DashboardColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DashboardColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '$totalCommentsCount ${totalCommentsCount == 1 ? 'comment' : 'comments'}',
                      style: const TextStyle(
                        color: DashboardColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (comments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No comments yet.',
                    style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 13),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  clipBehavior: Clip.none,
                  itemCount: comments.length,
                  itemBuilder: (context, idx) {
                    final comment = comments[idx];
                    final agoStr = _ago(comment.timestamp);
                    final isReactionPickerActive = _activeEmojiPickerCommentId == comment.id;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: comment.replies.isEmpty ? 12 : 0),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            DashboardColors.primary,
                                            DashboardColors.secondary,
                                          ],
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(1.5),
                                      child: ClipOval(
                                        child: comment.authorAvatarUrl != null && comment.authorAvatarUrl!.isNotEmpty
                                            ? Image.network(
                                                comment.authorAvatarUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  color: Colors.black38,
                                                  child: Center(
                                                    child: Text(
                                                      comment.authorInitials,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w900,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                color: Colors.black38,
                                                child: Center(
                                                  child: Text(
                                                    comment.authorInitials,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                    if (comment.replies.isNotEmpty) ...[
                                      Expanded(
                                        child: Center(
                                          child: Container(
                                            width: 1.5,
                                            color: Colors.white.withValues(alpha: 0.15),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(width: 12),
                              Expanded(
                                child: MouseRegion(
                                  onExit: (_) {
                                    if (_activeEmojiPickerCommentId == comment.id) {
                                      setState(() {
                                        _activeEmojiPickerCommentId = null;
                                        _isReactionCapsuleExpanded = false;
                                      });
                                    }
                                  },
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    comment.authorName,
                                                    style: const TextStyle(
                                                      color: DashboardColors.onSurface,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (comment.isTaskCreator) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                      decoration: BoxDecoration(
                                                        color: DashboardColors.primary.withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: DashboardColors.primary.withValues(alpha: 0.3), width: 0.5),
                                                      ),
                                                      child: const Text(
                                                        'Author',
                                                        style: TextStyle(
                                                          color: DashboardColors.primary,
                                                          fontSize: 8.5,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              Text(
                                                agoStr,
                                                style: const TextStyle(
                                                  color: DashboardColors.onSurfaceVariant,
                                                  fontSize: 10.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          if (comment.text.isNotEmpty)
                                            _buildFormattedCommentText(comment.text),
                                          if (comment.attachment != null) ...[
                                            const SizedBox(height: 8),
                                            _buildAttachmentCard(comment.attachment!),
                                          ],
                                          if (comment.voiceNote != null) ...[
                                            const SizedBox(height: 8),
                                            _VoicePlayer(voiceNote: comment.voiceNote!),
                                          ],
                                          const SizedBox(height: 8),
                                          Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 16,
                                            runSpacing: 4,
                                            children: [
                                              MouseRegion(
                                                onEnter: (event) {
                                                  if (event.kind == PointerDeviceKind.touch) return;
                                                  if (_justClickedCommentId != comment.id) {
                                                    setState(() {
                                                      _activeEmojiPickerCommentId = comment.id;
                                                    });
                                                  }
                                                },
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _justClickedCommentId = comment.id;
                                                      _activeEmojiPickerCommentId = null;
                                                    });
                                                    Future.delayed(const Duration(milliseconds: 2000), () {
                                                      if (mounted) {
                                                        setState(() {
                                                          _justClickedCommentId = null;
                                                        });
                                                      }
                                                    });

                                                    final notifier = ref.read(taskCommentsProvider(widget.taskId).notifier);
                                                    if (comment.reactedEmojis.isNotEmpty) {
                                                      for (final emoji in comment.reactedEmojis) {
                                                        notifier.toggleReaction(comment.id, emoji);
                                                      }
                                                    } else {
                                                      notifier.toggleReaction(comment.id, '👍');
                                                    }
                                                  },
                                                  onLongPress: () {
                                                    setState(() {
                                                      _activeEmojiPickerCommentId = isReactionPickerActive ? null : comment.id;
                                                    });
                                                  },
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                                    child: Icon(
                                                      Icons.thumb_up_outlined,
                                                      color: comment.reactedEmojis.isNotEmpty
                                                          ? DashboardColors.primary
                                                          : (isReactionPickerActive ? DashboardColors.primary : DashboardColors.onSurfaceVariant),
                                                      size: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _replyingToCommentId = comment.id;
                                                    _replyingToAuthorName = comment.authorName;
                                                    final isSelf = comment.authorName == actorName;
                                                    if (!isSelf) {
                                                      final mentionString = '@${comment.authorName} ';
                                                      if (!_controller.text.startsWith(mentionString)) {
                                                        _controller.text = '$mentionString${_controller.text}';
                                                      }
                                                    }
                                                    _controller.selection = TextSelection.fromPosition(
                                                      TextPosition(offset: _controller.text.length),
                                                    );
                                                  });
                                                  _focusNode.requestFocus();
                                                },
                                                child: const Text(
                                                  'Reply',
                                                  style: TextStyle(
                                                    color: DashboardColors.onSurfaceVariant,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              _buildReactionsBadgeList(
                                                commentId: comment.id,
                                                reactions: comment.reactions,
                                                reactedEmojis: comment.reactedEmojis,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (isReactionPickerActive)
                                        Positioned(
                                          left: 0,
                                          bottom: 26,
                                          child: TapRegion(
                                            onTapOutside: (event) {
                                              setState(() {
                                                _activeEmojiPickerCommentId = null;
                                                _isReactionCapsuleExpanded = false;
                                              });
                                            },
                                            child: _buildFloatingReactionCapsule(comment.id),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                        // Render Indented Replies
                        if (comment.replies.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 18, bottom: 12),
                            padding: const EdgeInsets.only(left: 30),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              clipBehavior: Clip.none,
                              itemCount: comment.replies.length,
                              itemBuilder: (context, rIdx) {
                                return _buildReplyItem(
                                  comment,
                                  comment.replies[rIdx],
                                  isLast: rIdx == comment.replies.length - 1,
                                  actorName: actorName,
                                  startX: -30.0,
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 16),
              _buildSmartCommentChips(),
              const SizedBox(height: 20),
              
              // Mentions dropdown suggestion overlay
              if (_showMentions && matchingUsers.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: matchingUsers.length,
                    itemBuilder: (context, idx) {
                      final u = matchingUsers[idx];
                      final name = u.fullName ?? u.username ?? u.email;
                      return ListTile(
                        dense: true,
                        title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        onTap: () => _insertMention(name),
                      );
                    },
                  ),
                ),

              // Replying indicator
              if (_replyingToCommentId != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: DashboardColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DashboardColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Replying to $_replyingToAuthorName',
                        style: const TextStyle(color: DashboardColors.primary, fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _replyingToCommentId = null;
                            _replyingToAuthorName = null;
                          });
                        },
                        child: const Icon(Icons.close_rounded, color: DashboardColors.primary, size: 14),
                      ),
                    ],
                  ),
                ),

              // Pending file preview
              if (_pendingAttachment != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _pendingAttachment!.isImage ? Icons.image_rounded : Icons.insert_drive_file_rounded,
                        color: DashboardColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _pendingAttachment!.name,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _pendingAttachment = null),
                        child: const Icon(Icons.close_rounded, color: Colors.white38, size: 16),
                      ),
                    ],
                  ),
                ),

              // Pending Voice Note preview
              if (_pendingVoiceNote != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mic_rounded, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Voice Comment (${_pendingVoiceNote!.durationSeconds}s) ready',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _pendingVoiceNote = null),
                        child: const Icon(Icons.close_rounded, color: Colors.white38, size: 16),
                      ),
                    ],
                  ),
                ),

              // Main Input Row
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _isRecording
                    ? _buildRecordingPillWidget(actorName)
                    : Row(
                        key: const ValueKey('text_input_row'),
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                style: const TextStyle(color: DashboardColors.onSurface, fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'Write a comment (use @ to mention)...',
                                  hintStyle: TextStyle(color: DashboardColors.onSurfaceVariant),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onTap: () {
                                  if (_showEmojiPicker) {
                                    setState(() {
                                      _showEmojiPicker = false;
                                    });
                                  }
                                },
                                onSubmitted: (val) => _postComment(actorName),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.folder_open_rounded, color: DashboardColors.onSurfaceVariant, size: 20),
                            onPressed: _pickDeviceFile,
                            tooltip: 'Attach file from device',
                          ),
                          IconButton(
                            icon: Icon(
                              _showEmojiPicker ? Icons.keyboard_rounded : Icons.sentiment_satisfied_alt_rounded,
                              color: _showEmojiPicker ? DashboardColors.primary : DashboardColors.onSurfaceVariant,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _showEmojiPicker = !_showEmojiPicker;
                                if (_showEmojiPicker) {
                                  _focusNode.unfocus();
                                } else {
                                  _focusNode.requestFocus();
                                }
                              });
                            },
                            tooltip: 'Insert emoji',
                          ),
                          IconButton(
                            icon: const Icon(Icons.mic_none_rounded, color: DashboardColors.onSurfaceVariant, size: 20),
                            onPressed: _startRecording,
                            tooltip: 'Record audio comment',
                          ),
                          _isSubmitting
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: DashboardColors.primary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.send_rounded, color: DashboardColors.primary, size: 20),
                                  onPressed: () => _postComment(actorName),
                                ),
                        ],
                      ),
              ),
                if (_showEmojiPicker) ...[
                  const SizedBox(height: 12),
                  _buildEmojiPickerPanel(),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingPillWidget(String actorName) {
    final curSec = _recordingSeconds;
    final timeStr = '0:${curSec.toString().padLeft(2, '0')}';

    return Center(
      key: const ValueKey('recording_pill'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1F22), // Dark pill background
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Left: Blue circle containing pulsing red recording dot (resembles the blue play button from image)
            GestureDetector(
              onTap: () => _stopRecording(true), // Stop and save preview
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF5865F2), // Discord blue
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const _PulsingRecordDot(),
              ),
            ),
            const SizedBox(width: 12),
            // Middle: Live Messenger-style animated waveform
            const SizedBox(
              width: 70,
              height: 16,
              child: _LiveRecordingWaveform(),
            ),
            const SizedBox(width: 10),
            // Timer matching elapsed time layout
            Text(
              timeStr,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 10),
            // Cancel button styled exactly like the "1X" badge
            GestureDetector(
              onTap: () => _stopRecording(false), // Cancel recording
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white70,
                      size: 11,
                    ),
                    SizedBox(width: 2),
                    Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Right: Send button replacing the speaker icon (borderless, matching color)
            GestureDetector(
              onTap: () {
                _stopRecording(true);
                Future.delayed(const Duration(milliseconds: 100), () {
                  _postComment(actorName);
                });
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPickerPanel() {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: EmojiPicker(
          onEmojiSelected: (category, emoji) {
            _insertEmoji(emoji.emoji);
          },
          config: Config(
            height: 260,
            checkPlatformCompatibility: true,
            emojiViewConfig: EmojiViewConfig(
              columns: 8,
              emojiSizeMax: 28,
              backgroundColor: Colors.transparent,
              verticalSpacing: 4,
              horizontalSpacing: 4,
              gridPadding: const EdgeInsets.all(8),
            ),
            categoryViewConfig: CategoryViewConfig(
              backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.6),
              indicatorColor: DashboardColors.primary,
              iconColor: Colors.white54,
              iconColorSelected: DashboardColors.primary,
              backspaceColor: DashboardColors.primary,
              tabBarHeight: 40,
            ),
            bottomActionBarConfig: const BottomActionBarConfig(
              backgroundColor: Colors.transparent,
              buttonColor: Colors.transparent,
              buttonIconColor: Colors.white54,
            ),
            searchViewConfig: SearchViewConfig(
              backgroundColor: const Color(0xFF0F172A),
              buttonIconColor: Colors.white54,
              hintText: 'Search emoji...',
              hintTextStyle: const TextStyle(color: Colors.white30, fontSize: 13),
              inputTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormattedCommentText(String text) {
    final List<InlineSpan> spans = [];

    // Gather all known user names in system
    final Set<String> names = {};
    final allUsers = ref.read(allUsersProvider).valueOrNull ?? [];
    for (final u in allUsers) {
      final name = u.fullName ?? u.username ?? u.email;
      if (name.trim().isNotEmpty) {
        names.add(name.trim());
      }
    }

    // Also gather from loaded comments
    final comments = ref.read(taskCommentsProvider(widget.taskId));
    for (final c in comments) {
      if (c.authorName.trim().isNotEmpty) names.add(c.authorName.trim());
      for (final r in c.replies) {
        if (r.authorName.trim().isNotEmpty) names.add(r.authorName.trim());
      }
    }

    final sortedNames = names.toList()..sort((a, b) => b.length.compareTo(a.length));
    final escapedNames = sortedNames.map((name) => RegExp.escape(name)).toList();

    // Match any known user name, or any fallback username format (starting with @ up to whitespace)
    final patternString = escapedNames.isNotEmpty
        ? '(@(?:${escapedNames.join('|')})|@[^\\s@]+)'
        : '(@[^\\s@]+)';
    final pattern = RegExp(patternString, unicode: true);

    int lastPos = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastPos) {
        spans.add(TextSpan(text: text.substring(lastPos, match.start)));
      }
      final matchedText = match.group(0)!;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: DashboardColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: DashboardColors.primary.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Text(
              matchedText,
              style: const TextStyle(
                color: DashboardColors.primary,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
      lastPos = match.end;
    }
    if (lastPos < text.length) {
      spans.add(TextSpan(text: text.substring(lastPos)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 13, height: 1.4),
        children: spans,
      ),
    );
  }

  Widget _buildAttachmentCard(AttachmentModel attachment) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (attachment.isImage) ...[
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.white.withValues(alpha: 0.05),
                child: const Center(
                  child: Icon(Icons.image_rounded, color: Colors.white30, size: 36),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(
                  attachment.isImage ? Icons.image_rounded : Icons.insert_drive_file_rounded,
                  color: DashboardColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    attachment.name,
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.download_rounded, color: Colors.white38, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingReactionCapsule(String commentId) {
    final commonEmojis = ['👍', '❤️', '🔥', '🚀', '👏'];
    final otherEmojis = ['🎉', '😆', '😮', '😢', '😡', '🥰'];

    final List<Widget> children = [];

    if (widget.isPanel) {
      final list = _isReactionCapsuleExpanded ? [...commonEmojis, ...otherEmojis] : commonEmojis;
      for (final e in list) {
        children.add(
          TaskReactionPickerItem(
            emoji: e,
            onTap: () {
              setState(() {
                _justClickedCommentId = commentId;
                _activeEmojiPickerCommentId = null;
              });
              Future.delayed(const Duration(milliseconds: 2000), () {
                if (mounted) {
                  setState(() {
                    _justClickedCommentId = null;
                  });
                }
              });
              ref.read(taskCommentsProvider(widget.taskId).notifier).toggleReaction(commentId, e);
            },
          ),
        );
      }

      if (!_isReactionCapsuleExpanded) {
        children.add(
          GestureDetector(
            onTap: () {
              setState(() {
                _isReactionCapsuleExpanded = true;
              });
            },
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 6.0, right: 6.0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white70, size: 14),
                ),
              ),
            ),
          ),
        );
      }
    } else {
      final all = [...commonEmojis, ...otherEmojis];
      for (final e in all) {
        children.add(
          TaskReactionPickerItem(
            emoji: e,
            onTap: () {
              setState(() {
                _justClickedCommentId = commentId;
                _activeEmojiPickerCommentId = null;
              });
              Future.delayed(const Duration(milliseconds: 2000), () {
                if (mounted) {
                  setState(() {
                    _justClickedCommentId = null;
                  });
                }
              });
              ref.read(taskCommentsProvider(widget.taskId).notifier).toggleReaction(commentId, e);
            },
          ),
        );
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Color _getReactionColor(String emoji) {
    switch (emoji) {
      case '❤️':
        return Colors.red;
      case '👍':
        return const Color(0xFF0866FF);
      case '🥰':
      case '😆':
      case '😂':
      case '😮':
      case '😢':
        return const Color(0xFFF7B125);
      case '😡':
        return const Color(0xFFF15A36);
      case '🚀':
        return Colors.cyanAccent;
      case '🔥':
        return Colors.orangeAccent;
      case '👏':
        return Colors.yellowAccent;
      case '🎉':
        return Colors.pinkAccent;
      default:
        return Colors.white70;
    }
  }

  Widget _buildReactionsBadgeList({
    required String commentId,
    required Map<String, int> reactions,
    required List<String> reactedEmojis,
  }) {
    final hasReactions = reactions.isNotEmpty;
    if (!hasReactions && !widget.isPanel) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];

    for (final entry in reactions.entries) {
      final isReactedByUser = reactedEmojis.contains(entry.key);
      children.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _justClickedCommentId = commentId;
            });
            Future.delayed(const Duration(milliseconds: 2000), () {
              if (mounted) {
                setState(() {
                  _justClickedCommentId = null;
                });
              }
            });
            ref.read(taskCommentsProvider(widget.taskId).notifier).toggleReaction(commentId, entry.key);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isReactedByUser 
                  ? DashboardColors.primary.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isReactedByUser 
                    ? DashboardColors.primary.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.0,
                    color: _getReactionColor(entry.key),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  '${entry.value}',
                  style: TextStyle(
                    color: isReactedByUser ? DashboardColors.primary : Colors.white54,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.isPanel) {
      children.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _activeEmojiPickerCommentId = _activeEmojiPickerCommentId == commentId ? null : commentId;
              _isReactionCapsuleExpanded = false;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_reaction_outlined, color: Colors.white54, size: 12),
                SizedBox(width: 2),
                Text(
                  '+',
                  style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

class _VoicePlayer extends StatefulWidget {
  const _VoicePlayer({required this.voiceNote});

  final VoiceNoteModel voiceNote;

  @override
  State<_VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<_VoicePlayer> {
  late final AudioPlayer _player;
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _isMuted = false;
  double _playbackSpeed = 1.0;
  double _progress = 0.0;
  int _elapsedMilliseconds = 0;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;

  bool _useSimulation = false;
  Timer? _simTimer;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    final isUploading = widget.voiceNote.audioUrl == 'temp_uploading';
    if (isUploading) {
      _isLoading = true;
    } else {
      _initPlayer();
    }
  }

  @override
  void didUpdateWidget(covariant _VoicePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.voiceNote.audioUrl != widget.voiceNote.audioUrl) {
      final isUploading = widget.voiceNote.audioUrl == 'temp_uploading';
      if (!isUploading) {
        _initPlayer();
      }
    }
  }

  void _initPlayer() async {
    final url = widget.voiceNote.audioUrl;
    if (url.startsWith('voice://') || url == 'temp_uploading') {
      _useSimulation = true;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      _useSimulation = false;
      String cleanUrl = url;
      try {
        final uri = Uri.parse(url);
        if (uri.scheme == 'http' || uri.scheme == 'https') {
          cleanUrl = url.split('?').first;
        }
      } catch (_) {}

      Source source;
      if (cleanUrl.startsWith('http') || cleanUrl.startsWith('https')) {
        source = UrlSource(cleanUrl);
      } else {
        source = DeviceFileSource(cleanUrl);
      }

      await _player.setSource(source);

      _posSub = _player.onPositionChanged.listen((p) {
        if (mounted && _isPlaying) {
          setState(() {
            _elapsedMilliseconds = p.inMilliseconds;
            final durationMs = widget.voiceNote.durationSeconds * 1000;
            _progress = durationMs > 0 ? (_elapsedMilliseconds / durationMs).clamp(0.0, 1.0) : 0.0;
          });
        }
      });

      _durSub = _player.onDurationChanged.listen((d) {
        // Optional
      });

      _stateSub = _player.onPlayerStateChanged.listen((s) {
        if (mounted) {
          setState(() {
            _isPlaying = s == PlayerState.playing;
            if (s == PlayerState.completed) {
              _progress = 0.0;
              _elapsedMilliseconds = 0;
              _isPlaying = false;
            }
          });
        }
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing audioplayer: $e');
      _useSimulation = true;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _togglePlayback() async {
    if (_isLoading) return;

    if (_useSimulation) {
      if (_isPlaying) {
        _simTimer?.cancel();
        setState(() {
          _isPlaying = false;
        });
      } else {
        setState(() {
          _isPlaying = true;
        });
        final totalMs = widget.voiceNote.durationSeconds * 1000;
        _simTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          setState(() {
            _elapsedMilliseconds += (100 * _playbackSpeed).toInt();
            _progress = _elapsedMilliseconds / totalMs;
            if (_progress >= 1.0) {
              _progress = 0.0;
              _elapsedMilliseconds = 0;
              _isPlaying = false;
              _simTimer?.cancel();
            }
          });
        });
      }
      return;
    }

    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.setPlaybackRate(_playbackSpeed);
        await _player.setVolume(_isMuted ? 0.0 : 1.0);
        
        final url = widget.voiceNote.audioUrl;
        String cleanUrl = url;
        try {
          final uri = Uri.parse(url);
          if (uri.scheme == 'http' || uri.scheme == 'https') {
            cleanUrl = url.split('?').first;
          }
        } catch (_) {}

        Source source;
        if (cleanUrl.startsWith('http') || cleanUrl.startsWith('https')) {
          source = UrlSource(cleanUrl);
        } else {
          source = DeviceFileSource(cleanUrl);
        }
        await _player.play(source);
      }
    } catch (e) {
      debugPrint('Error toggling playback: $e');
    }
  }

  void _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    if (_useSimulation) return;
    try {
      await _player.setVolume(_isMuted ? 0.0 : 1.0);
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  void _changeSpeed() async {
    double nextSpeed = 1.0;
    if (_playbackSpeed == 1.0) {
      nextSpeed = 1.5;
    } else if (_playbackSpeed == 1.5) {
      nextSpeed = 2.0;
    } else {
      nextSpeed = 1.0;
    }
    setState(() {
      _playbackSpeed = nextSpeed;
    });
    if (_useSimulation) return;
    try {
      await _player.setPlaybackRate(nextSpeed);
    } catch (e) {
      debugPrint('Error setting playback rate: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final curSec = (_elapsedMilliseconds / 1000).floor();
    final timeStr = '0:${curSec.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F22), // Dark pill background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _isLoading
              ? Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5865F2), // Discord blue
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: _togglePlayback,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5865F2), // Discord blue play button
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            height: 16,
            child: CustomPaint(
              size: const Size(70, 16),
              painter: WaveformPainter(
                waveData: widget.voiceNote.waveData,
                progress: _progress,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            timeStr,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 10),
          // Speed multiplier badge
          GestureDetector(
            onTap: _changeSpeed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_playbackSpeed == 1.0 ? '1' : _playbackSpeed}X',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _toggleMute,
            child: Icon(
              _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: Colors.white54,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRecordingWaveform extends StatefulWidget {
  const _LiveRecordingWaveform();

  @override
  State<_LiveRecordingWaveform> createState() => _LiveRecordingWaveformState();
}

class _LiveRecordingWaveformState extends State<_LiveRecordingWaveform> {
  late Timer _timer;
  final List<double> _heights = List.generate(14, (_) => 0.2);

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          for (int i = 0; i < _heights.length; i++) {
            _heights[i] = 0.15 + random.nextDouble() * 0.85;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _heights.map((h) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.2),
          width: 2.0,
          height: 16 * h,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444), // Red recording wave color
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }).toList(),
    );
  }
}

class _PulsingRecordDot extends StatefulWidget {
  const _PulsingRecordDot();

  @override
  State<_PulsingRecordDot> createState() => _PulsingRecordDotState();
}

class _PulsingRecordDotState extends State<_PulsingRecordDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Color(0xFFEF4444),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> waveData;
  final double progress;

  WaveformPainter({required this.waveData, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paintInactive = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final paintActive = Paint()
      ..color = DashboardColors.primary
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final spacing = size.width / waveData.length;
    final halfHeight = size.height / 2;

    for (int i = 0; i < waveData.length; i++) {
      final x = i * spacing + spacing / 2;
      final barHeight = waveData[i] * size.height;
      final y0 = halfHeight - barHeight / 2;
      final y1 = halfHeight + barHeight / 2;

      final isPast = (x / size.width) <= progress;
      canvas.drawLine(
        Offset(x, y0),
        Offset(x, y1),
        isPast ? paintActive : paintInactive,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.waveData != waveData;
  }
}

class _ReplyConnectionPainter extends CustomPainter {
  final bool isLast;
  final Color lineColor;
  final double startX;

  _ReplyConnectionPainter({
    required this.isLast,
    required this.lineColor,
    required this.startX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const double endX = -4.0;
    const double targetY = 13.0;

    if (isLast) {
      path.moveTo(startX, 0);
      path.lineTo(startX, targetY - 8);
      path.quadraticBezierTo(startX, targetY, startX + 8, targetY);
      path.lineTo(endX, targetY);
    } else {
      path.moveTo(startX, 0);
      path.lineTo(startX, size.height);
      
      path.moveTo(startX, targetY - 8);
      path.quadraticBezierTo(startX, targetY, startX + 8, targetY);
      path.lineTo(endX, targetY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ReplyConnectionPainter oldDelegate) {
    return oldDelegate.isLast != isLast ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.startX != startX;
  }
}

class TaskReactionPickerItem extends StatefulWidget {
  final String emoji;
  final VoidCallback onTap;

  const TaskReactionPickerItem({
    super.key,
    required this.emoji,
    required this.onTap,
  });

  @override
  State<TaskReactionPickerItem> createState() => _TaskReactionPickerItemState();
}

class _TaskReactionPickerItemState extends State<TaskReactionPickerItem> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
        _animationController.repeat();
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
        _animationController.stop();
        _animationController.reset();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 80,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                transform: Matrix4.translationValues(0.0, _isHovered ? -12.0 : 0.0, 0.0)
                  ..multiply(Matrix4.diagonal3Values(_isHovered ? 1.6 : 1.0, _isHovered ? 1.6 : 1.0, 1.0)),
                transformAlignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return _buildAnimatedEmoji(widget.emoji, _animationController.value);
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -14,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _isHovered ? 1.0 : 0.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    transform: Matrix4.translationValues(0.0, _isHovered ? 0.0 : 5.0, 0.0),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _getTooltipLabel(widget.emoji),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedEmoji(String emoji, double val) {
    final emojiWidget = Text(
      widget.emoji,
      style: TextStyle(
        fontSize: 30,
        height: 1.0,
        color: _getReactionColor(emoji),
      ),
    );

    if (!_isHovered) return emojiWidget;

    Matrix4 transform = Matrix4.identity();
    Widget currentWidget = emojiWidget;

    if (emoji == '👍') {
      final double dy = -6.0 * math.sin(val * math.pi * 2).abs();
      transform = Matrix4.translationValues(0.0, dy, 0.0);
    } else if (emoji == '❤️') {
      double scale = 1.0;
      if (val < 0.3) {
        scale += 0.20 * math.sin((val / 0.3) * math.pi);
      } else if (val < 0.6) {
        scale += 0.15 * math.sin(((val - 0.3) / 0.3) * math.pi);
      }
      transform = Matrix4.diagonal3Values(scale, scale, 1.0);
    } else if (emoji == '🥰') {
      final double angle = 0.12 * math.sin(val * math.pi * 2);
      final double dx = 3.0 * math.sin(val * math.pi * 2);
      transform = Matrix4.translationValues(dx, 0.0, 0.0)..rotateZ(angle);
    } else if (emoji == '😆' || emoji == '😂') {
      final double dy = -5.0 * math.sin(val * math.pi * 4).abs();
      final double angle = 0.1 * math.sin(val * math.pi * 6);
      transform = Matrix4.translationValues(0.0, dy, 0.0)..rotateZ(angle);
    } else if (emoji == '😮') {
      final double sy = 1.0 + 0.2 * math.sin(val * math.pi * 2);
      final double sx = 1.0 - 0.1 * math.sin(val * math.pi * 2);
      transform = Matrix4.diagonal3Values(sx, sy, 1.0);
    } else if (emoji == '😢') {
      final double angle = 0.06 * math.sin(val * math.pi * 2);
      transform = Matrix4.rotationZ(angle);
      currentWidget = CustomPaint(
        foregroundPainter: _TearPainter(val),
        child: emojiWidget,
      );
    } else if (emoji == '😡') {
      final double dx = 1.5 * math.sin(val * math.pi * 28);
      final double dy = 1.0 * math.cos(val * math.pi * 36);
      transform = Matrix4.translationValues(dx, dy, 0.0);
    } else if (emoji == '🚀') {
      final double dx = 1.0 * math.sin(val * math.pi * 18);
      final double dy = -6.0 * math.sin(val * math.pi * 2);
      final double angle = 0.04 * math.sin(val * math.pi * 18);
      transform = Matrix4.translationValues(dx, dy, 0.0)..rotateZ(angle);
    } else if (emoji == '🔥') {
      final double sy = 1.0 + 0.12 * math.sin(val * math.pi * 10);
      final double sx = 1.0 - 0.06 * math.sin(val * math.pi * 10);
      final double dy = -1.5 * math.sin(val * math.pi * 5);
      transform = Matrix4.translationValues(0.0, dy, 0.0)..multiply(Matrix4.diagonal3Values(sx, sy, 1.0));
    } else if (emoji == '👏') {
      final double angle = 0.12 * math.cos(val * math.pi * 8);
      final double scale = 1.0 + 0.08 * math.sin(val * math.pi * 8).abs();
      transform = Matrix4.diagonal3Values(scale, scale, 1.0)..rotateZ(angle);
    } else if (emoji == '🎉') {
      final double angle = 0.08 * math.sin(val * math.pi * 4);
      final double scale = 1.0 + 0.12 * math.sin(val * math.pi * 2).abs();
      transform = Matrix4.diagonal3Values(scale, scale, 1.0)..rotateZ(angle);
      currentWidget = CustomPaint(
        foregroundPainter: _ConfettiPainter(val),
        child: emojiWidget,
      );
    }

    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: currentWidget,
    );
  }

  String _getTooltipLabel(String emoji) {
    switch (emoji) {
      case '👍':
        return 'Thích';
      case '❤️':
        return 'Yêu thích';
      case '🥰':
        return 'Thương thương';
      case '😂':
      case '😆':
        return 'Haha';
      case '😮':
        return 'Wow';
      case '😢':
        return 'Buồn';
      case '😡':
        return 'Phẫn nộ';
      case '🚀':
        return 'Bứt phá';
      case '🔥':
        return 'Cố lên';
      case '👏':
        return 'Vỗ tay';
      case '🎉':
        return 'Tiệc tùng';
      default:
        return '';
    }
  }
}

class _TearPainter extends CustomPainter {
  final double progress;
  _TearPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF29B6F6).withValues(alpha: 1.0 - progress)
      ..style = PaintingStyle.fill;

    double cx = size.width / 2;
    double cy = size.height / 2 + 2;

    double ly = cy + (size.height - cy) * progress;
    double lx = cx - 6;
    _drawTear(canvas, lx, ly, paint);

    double rp = (progress + 0.5) % 1.0;
    double ry = cy + (size.height - cy) * rp;
    double rx = cx + 6;
    final rightPaint = Paint()
      ..color = const Color(0xFF29B6F6).withValues(alpha: 1.0 - rp)
      ..style = PaintingStyle.fill;
    _drawTear(canvas, rx, ry, rightPaint);
  }

  void _drawTear(Canvas canvas, double x, double y, Paint paint) {
    final path = Path();
    path.moveTo(x, y - 4);
    path.quadraticBezierTo(x + 2, y - 2, x + 3, y);
    path.arcToPoint(Offset(x - 3, y), radius: const Radius.circular(3), clockwise: true);
    path.quadraticBezierTo(x - 2, y - 2, x, y - 4);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TearPainter oldDelegate) => oldDelegate.progress != progress;
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.yellowAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.pinkAccent,
    ];

    const numParticles = 14;
    for (int i = 0; i < numParticles; i++) {
      final double angle = (i * (360 / numParticles)) * math.pi / 180;
      final double speed = 12.0 + (i % 3) * 6.0;
      double dist = progress * speed;
      double dy = 0.5 * 9.8 * progress * progress * 8;

      double px = cx + math.cos(angle) * dist;
      double py = cy + math.sin(angle) * dist + dy;

      final color = colors[i % colors.length].withValues(alpha: 1.0 - progress);
      final paint = Paint()..color = color;

      if (i % 3 == 0) {
        canvas.drawCircle(Offset(px, py), 2.0 + (i % 2), paint);
      } else if (i % 3 == 1) {
        final rect = Rect.fromCenter(center: Offset(px, py), width: 3.5, height: 3.5);
        canvas.drawRect(rect, paint);
      } else {
        final linePaint = Paint()
          ..color = color
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(px, py),
          Offset(px - math.cos(angle) * 3, py - math.sin(angle) * 3),
          linePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

Color _getReactionColor(String emoji) {
  switch (emoji) {
    case '❤️':
      return Colors.red;
    case '👍':
      return const Color(0xFF0866FF);
    case '🥰':
    case '😆':
    case '😂':
    case '😮':
    case '😢':
      return const Color(0xFFF7B125);
    case '😡':
      return const Color(0xFFF15A36);
    case '🚀':
      return Colors.cyanAccent;
    case '🔥':
      return Colors.orangeAccent;
    case '👏':
      return Colors.yellowAccent;
    case '🎉':
      return Colors.pinkAccent;
    default:
      return Colors.white70;
  }
}
