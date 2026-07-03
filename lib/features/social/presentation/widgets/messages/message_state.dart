import 'package:to_do_app/core/services/app_providers.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum MessageType { text, image, sticker, file, voice, task, event, video, gif, audio }
enum MessageStatus { sending, sent, delivered, seen, failed }

class ChatMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String senderName;
  final String text;
  final MessageType type;
  final String? mediaUrl;
  final DateTime timestamp;
  final Map<String, List<String>> reactions; // emoji -> list of userIds
  final ChatMessage? replyTo;
  final MessageStatus status;
  final String? metaTitle; // For shared task/event cards
  final String? metaSubtitle;
  
  // Seen status and file metadata fields
  final List<String> seenByUserIds;
  final String? fileName;
  final int? fileSize;
  final String? taskId;
  final String? replyToMessageId;
  final bool isRecalled;
  final bool isPinned;

  String? get replyToId => replyToMessageId;

  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.type = MessageType.text,
    this.mediaUrl,
    required this.timestamp,
    this.reactions = const {},
    this.replyTo,
    this.status = MessageStatus.seen,
    this.metaTitle,
    this.metaSubtitle,
    this.seenByUserIds = const [],
    this.fileName,
    this.fileSize,
    this.taskId,
    this.replyToMessageId,
    this.isRecalled = false,
    this.isPinned = false,
  });

  ChatMessage copyWith({
    String? id,
    String? threadId,
    String? senderId,
    String? senderName,
    String? text,
    MessageType? type,
    String? mediaUrl,
    DateTime? timestamp,
    Map<String, List<String>>? reactions,
    ChatMessage? replyTo,
    MessageStatus? status,
    String? metaTitle,
    String? metaSubtitle,
    List<String>? seenByUserIds,
    String? fileName,
    int? fileSize,
    String? taskId,
    String? replyToMessageId,
    bool? isRecalled,
    bool? isPinned,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      timestamp: timestamp ?? this.timestamp,
      reactions: reactions ?? this.reactions,
      replyTo: replyTo ?? this.replyTo,
      status: status ?? this.status,
      metaTitle: metaTitle ?? this.metaTitle,
      metaSubtitle: metaSubtitle ?? this.metaSubtitle,
      seenByUserIds: seenByUserIds ?? this.seenByUserIds,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      taskId: taskId ?? this.taskId,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      isRecalled: isRecalled ?? this.isRecalled,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

class ChatThread {
  final String id;
  final String name;
  final String avatarInitials;
  final String? avatarUrl;
  final bool online;
  final String? lastActive;
  final bool unread;
  final bool pinned;
  final bool muted;
  final bool isTyping;
  final List<ChatMessage> messages;
  final String? recipientId;

  const ChatThread({
    required this.id,
    required this.name,
    required this.avatarInitials,
    this.avatarUrl,
    this.online = false,
    this.lastActive,
    this.unread = false,
    this.pinned = false,
    this.muted = false,
    this.isTyping = false,
    this.messages = const [],
    this.recipientId,
  });

  ChatThread copyWith({
    String? id,
    String? name,
    String? avatarInitials,
    String? avatarUrl,
    bool? online,
    String? lastActive,
    bool? unread,
    bool? pinned,
    bool? muted,
    bool? isTyping,
    List<ChatMessage>? messages,
    String? recipientId,
  }) {
    return ChatThread(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      online: online ?? this.online,
      lastActive: lastActive ?? this.lastActive,
      unread: unread ?? this.unread,
      pinned: pinned ?? this.pinned,
      muted: muted ?? this.muted,
      isTyping: isTyping ?? this.isTyping,
      messages: messages ?? this.messages,
      recipientId: recipientId ?? this.recipientId,
    );
  }
}

// Sidebars resizing states
final leftSidebarWidthProvider = StateProvider<double>((ref) => 320.0);
final rightSidebarWidthProvider = StateProvider<double>((ref) => 280.0);
final isRightSidebarVisibleProvider = StateProvider<bool>((ref) => true);

// Search and tab filter states
final chatTabFilterProvider = StateProvider<String>((ref) => 'all'); // all, unread, groups, archive, spam
final messageSearchQueryProvider = StateProvider<String>((ref) => '');
final isSearchFocusedProvider = StateProvider<bool>((ref) => false);

// Active thread
final activeThreadIdProvider = StateProvider<String?>((ref) => null);

class ActiveVideoViewerState {
  final List<ChatMessage> videoMessages;
  final int currentIndex;
  ActiveVideoViewerState({required this.videoMessages, required this.currentIndex});
}

final activeVideoViewerProvider = StateProvider<ActiveVideoViewerState?>((ref) => null);

// Chat threads StateNotifier
class ChatThreadsNotifier extends StateNotifier<List<ChatThread>> {
  final Ref ref;
  RealtimeChannel? _realtimeChannel;
  RealtimeChannel? _presenceChannel;
  Timer? _presenceHeartbeat;

  ChatThreadsNotifier(this.ref) : super([]) {
    loadRealtimeThreads();
    // Listen for auth changes to reload threads
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      loadRealtimeThreads();
    });
    ref.listen<String?>(activeThreadIdProvider, (previous, next) {
      final storage = ref.read(lastActiveThreadRepositoryProvider);
      if (next != null) {
        storage.write(_lastActiveThreadKey, next);
      }
    });
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _presenceChannel?.unsubscribe();
    _presenceHeartbeat?.cancel();
    super.dispose();
  }

  bool _isValidUuid(String id) {
    final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(id);
  }

  Future<void> setOnline() async {
    final supabase = Supabase.instance.client;
    final myUserId = supabase.auth.currentUser?.id;
    if (myUserId == null) return;

    try {
      await supabase.from('user_presence').upsert({
        'user_id': myUserId,
        'is_online': true,
        'last_seen_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      _presenceHeartbeat?.cancel();
      _presenceHeartbeat = Timer.periodic(const Duration(seconds: 30), (_) async {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (currentUserId != null) {
          try {
            await Supabase.instance.client.from('user_presence').upsert({
              'user_id': currentUserId,
              'is_online': true,
              'last_seen_at': DateTime.now().toIso8601String(),
            }, onConflict: 'user_id');
          } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint('Error setting presence online: $e');
    }
  }

  Future<void> setOffline() async {
    _presenceHeartbeat?.cancel();
    final supabase = Supabase.instance.client;
    final myUserId = supabase.auth.currentUser?.id;
    if (myUserId == null) return;

    try {
      await supabase.from('user_presence').upsert({
        'user_id': myUserId,
        'is_online': false,
        'last_seen_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('Error setting presence offline: $e');
    }
  }

  Future<void> selectThread(String id) async {
    state = state.map((t) {
      if (t.id == id) {
        return t.copyWith(unread: false);
      }
      return t;
    }).toList();

    await markAllSeen(id);
  }

  Future<void> markAllSeen(String conversationId) async {
    if (!_isValidUuid(conversationId)) return;

    final supabase = Supabase.instance.client;
    final myUserId = supabase.auth.currentUser?.id;
    if (myUserId == null) return;

    final threadIndex = state.indexWhere((t) => t.id == conversationId);
    if (threadIndex == -1) return;

    final thread = state[threadIndex];
    final unseenMsgIds = thread.messages
        .where((m) => m.senderId != 'me' && m.senderId != myUserId && !m.seenByUserIds.contains(myUserId))
        .map((m) => m.id)
        .toList();

    if (unseenMsgIds.isEmpty) return;

    try {
      await supabase.from('message_seen').upsert(
        unseenMsgIds.map((msgId) => {
          'message_id': msgId,
          'user_id': myUserId,
        }).toList(),
        onConflict: 'message_id,user_id',
        ignoreDuplicates: true,
      );

      // Locally update seen status
      state = state.map((t) {
        if (t.id == conversationId) {
          final updatedMsgs = t.messages.map((m) {
            if (unseenMsgIds.contains(m.id) && !m.seenByUserIds.contains(myUserId)) {
              return m.copyWith(seenByUserIds: [...m.seenByUserIds, myUserId]);
            }
            return m;
          }).toList();
          return t.copyWith(messages: updatedMsgs);
        }
        return t;
      }).toList();
    } catch (e) {
      debugPrint('Error marking messages as seen: $e');
    }
  }

  Future<String> createOrGetConversation(String targetUserId) async {
    final supabase = Supabase.instance.client;
    final myUserId = supabase.auth.currentUser?.id;
    if (myUserId == null || !_isValidUuid(targetUserId)) {
      return 'mock_thread';
    }

    try {
      final myParticipationsRes = await supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', myUserId);
          
      final targetParticipationsRes = await supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', targetUserId);
          
      final myConvIds = myParticipationsRes.map((p) => p['conversation_id']).toSet();
      final targetConvIds = targetParticipationsRes.map((p) => p['conversation_id']).toSet();
      
      final commonIds = myConvIds.intersection(targetConvIds);
      
      if (commonIds.isNotEmpty) {
        final existingId = commonIds.first.toString();
        await loadRealtimeThreads();
        return existingId;
      }

      final conv = await supabase.from('conversations').insert({
        'is_group': false,
      }).select().single();
      
      final convId = conv['id'] as String;
      
      await supabase.from('conversation_participants').insert([
        {'conversation_id': convId, 'user_id': myUserId},
        {'conversation_id': convId, 'user_id': targetUserId},
      ]);

      await loadRealtimeThreads();
      return convId;

    } catch (e) {
      debugPrint('Error creating/getting conversation: $e');
      return 'mock_thread';
    }
  }

  Future<void> loadRealtimeThreads() async {
    final supabase = Supabase.instance.client;
    final myUser = supabase.auth.currentUser;
    if (myUser == null) {
      return;
    }
    final myUserId = myUser.id;

    try {
      try {
        await supabase.storage.createBucket('bullet', const BucketOptions(public: true));
      } catch (_) {}

      final myParticipations = await supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', myUserId);

      final List<dynamic> conversationIds = myParticipations.map((p) => p['conversation_id']).toList();

      if (conversationIds.isEmpty) {
        state = [];
        return;
      }

      final allParts = await supabase
          .from('conversation_participants')
          .select('conversation_id, user_id, users!inner(id, email, full_name, username, avatar_url)')
          .inFilter('conversation_id', conversationIds);

      final messagesData = await supabase
          .from('messages')
          .select('*, message_seen(user_id, seen_at), reply_to_message:reply_to_message_id(id, content, sender_id, type, media_url, created_at, file_name, file_size, task_id)')
          .inFilter('conversation_id', conversationIds)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: true);

      final List<dynamic> sentMessagesFromOthers = messagesData
          .where((m) => m['sender_id'] != myUserId && m['status'] == 'sent')
          .toList();
          
      if (sentMessagesFromOthers.isNotEmpty) {
        final List<dynamic> msgIdsToUpdate = sentMessagesFromOthers.map((m) => m['id']).toList();
        try {
          await supabase
              .from('messages')
              .update({'status': 'delivered'})
              .inFilter('id', msgIdsToUpdate);
              
          for (final m in messagesData) {
            if (msgIdsToUpdate.contains(m['id'])) {
              m['status'] = 'delivered';
            }
          }
        } catch (e) {
          debugPrint('Error marking loaded messages as delivered: $e');
        }
      }

      final List<ChatThread> newThreads = [];
      for (final convId in conversationIds) {
        final partsForConv = allParts.where((p) => p['conversation_id'] == convId).toList();
        final otherPart = partsForConv.firstWhere(
          (p) => p['user_id'] != myUserId,
          orElse: () => partsForConv.first,
        );
        
        final otherUser = otherPart['users'] as Map<String, dynamic>;
        final String recipientName = otherUser['full_name'] ?? otherUser['username'] ?? otherUser['email'] ?? 'User';
        final String recipientInitials = recipientName.isNotEmpty ? recipientName[0].toUpperCase() : 'U';
        final String? avatarUrl = otherUser['avatar_url'];
        final String otherUserId = otherUser['id'] as String;

        final convMsgs = messagesData.where((m) => m['conversation_id'] == convId).map((m) {
          final isMe = m['sender_id'] == myUserId;
          final contentStr = m['content'] as String? ?? '';
          
          MessageType msgType = MessageType.text;
          String parsedText = contentStr;
          String? mediaUrl = m['media_url'];
          
          if (m['type'] != null) {
            msgType = MessageType.values.firstWhere(
              (e) => e.name == m['type'],
              orElse: () => MessageType.text,
            );
            if (msgType == MessageType.image) {
              parsedText = 'Đã gửi một hình ảnh';
            } else if (msgType == MessageType.video) {
              parsedText = 'Đã gửi một video';
            } else if (msgType == MessageType.gif) {
              parsedText = 'Đã gửi một ảnh động';
            } else if (msgType == MessageType.voice) {
              parsedText = 'Đã gửi tin nhắn thoại';
            } else if (msgType == MessageType.file) {
              parsedText = m['file_name'] ?? 'Đã gửi một tệp tin';
            } else if (msgType == MessageType.task) {
              parsedText = contentStr.replaceFirst('[TASK]', '');
            }
          } else {
            if (contentStr.startsWith('[IMAGE]')) {
              msgType = MessageType.image;
              mediaUrl = contentStr.replaceFirst('[IMAGE]', '');
              parsedText = 'Đã gửi một hình ảnh';
            } else if (contentStr.startsWith('[VIDEO]')) {
              msgType = MessageType.video;
              mediaUrl = contentStr.replaceFirst('[VIDEO]', '');
              parsedText = 'Đã gửi một video';
            } else if (contentStr.startsWith('[GIF]')) {
              msgType = MessageType.gif;
              mediaUrl = contentStr.replaceFirst('[GIF]', '');
              parsedText = 'Đã gửi một ảnh động';
            } else if (contentStr.startsWith('[VOICE]')) {
              msgType = MessageType.voice;
              mediaUrl = contentStr.replaceFirst('[VOICE]', '');
              parsedText = 'Đã gửi tin nhắn thoại';
            } else if (contentStr.startsWith('[TASK]')) {
              msgType = MessageType.task;
              parsedText = contentStr.replaceFirst('[TASK]', '');
            }
          }

          final statusStr = m['status'] as String? ?? 'seen';
          MessageStatus status = MessageStatus.seen;
          if (statusStr == 'sending') status = MessageStatus.sending;
          else if (statusStr == 'sent') status = MessageStatus.sent;
          else if (statusStr == 'delivered') status = MessageStatus.delivered;

          final seenBy = (m['message_seen'] as List?)
              ?.map((s) => s['user_id'] as String)
              .toList() ?? [];

          // Map joined reply_to_message if present
          final replyMap = m['reply_to_message'] as Map<String, dynamic>?;
          ChatMessage? replyMessageObj;
          if (replyMap != null) {
            final replyContent = replyMap['content'] as String? ?? '';
            final replySenderId = replyMap['sender_id'] as String;
            final isReplyMe = replySenderId == myUserId;
            
            MessageType replyMsgType = MessageType.text;
            String replyParsedText = replyContent;
            String? replyMediaUrl = replyMap['media_url'];
            
            if (replyMap['type'] != null) {
              replyMsgType = MessageType.values.firstWhere(
                (e) => e.name == replyMap['type'],
                orElse: () => MessageType.text,
              );
              if (replyMsgType == MessageType.image) {
                replyParsedText = 'Đã gửi một hình ảnh';
              } else if (replyMsgType == MessageType.video) {
                replyParsedText = 'Đã gửi một video';
              } else if (replyMsgType == MessageType.gif) {
                replyParsedText = 'Đã gửi một ảnh động';
              } else if (replyMsgType == MessageType.voice) {
                replyParsedText = 'Đã gửi tin nhắn thoại';
              } else if (replyMsgType == MessageType.file) {
                replyParsedText = replyMap['file_name'] ?? 'Đã gửi một tệp tin';
              }
            } else {
              if (replyContent.startsWith('[IMAGE]')) {
                replyMsgType = MessageType.image;
                replyMediaUrl = replyContent.replaceFirst('[IMAGE]', '');
                replyParsedText = 'Đã gửi một hình ảnh';
              } else if (replyContent.startsWith('[VIDEO]')) {
                replyMsgType = MessageType.video;
                replyMediaUrl = replyContent.replaceFirst('[VIDEO]', '');
                replyParsedText = 'Đã gửi một video';
              } else if (replyContent.startsWith('[GIF]')) {
                replyMsgType = MessageType.gif;
                replyMediaUrl = replyContent.replaceFirst('[GIF]', '');
                replyParsedText = 'Đã gửi một ảnh động';
              } else if (replyContent.startsWith('[VOICE]')) {
                replyMsgType = MessageType.voice;
                replyMediaUrl = replyContent.replaceFirst('[VOICE]', '');
                replyParsedText = 'Đã gửi tin nhắn thoại';
              }
            }

            replyMessageObj = ChatMessage(
              id: replyMap['id'].toString(),
              threadId: convId,
              senderId: isReplyMe ? 'me' : replySenderId,
              senderName: isReplyMe ? 'Bạn' : recipientName,
              text: replyParsedText,
              type: replyMsgType,
              mediaUrl: replyMediaUrl,
              timestamp: DateTime.parse(replyMap['created_at'] ?? m['created_at']).toLocal(),
            );
          }

          return ChatMessage(
            id: m['id'].toString(),
            threadId: convId,
            senderId: isMe ? 'me' : m['sender_id'],
            senderName: isMe ? 'Bạn' : recipientName,
            text: parsedText,
            type: msgType,
            mediaUrl: mediaUrl,
            timestamp: DateTime.parse(m['created_at']).toLocal(),
            status: status,
            metaTitle: m['task_id'] != null || m['shared_task_id'] != null ? parsedText : null,
            metaSubtitle: m['task_id'] != null || m['shared_task_id'] != null ? 'Nhiệm vụ được chia sẻ' : null,
            seenByUserIds: seenBy,
            fileName: m['file_name'],
            fileSize: m['file_size'],
            taskId: m['task_id']?.toString(),
            replyToMessageId: m['reply_to_message_id']?.toString(),
            replyTo: replyMessageObj,
          );
        }).toList();

        // Resolve replyTo references (fallback / realtime)
        final List<ChatMessage> resolvedMsgs = [];
        for (final msg in convMsgs) {
          if (msg.replyTo == null && msg.replyToMessageId != null) {
            ChatMessage? repliedMsg;
            for (final other in convMsgs) {
              if (other.id == msg.replyToMessageId) {
                repliedMsg = other;
                break;
              }
            }
            if (repliedMsg != null) {
              resolvedMsgs.add(msg.copyWith(replyTo: repliedMsg));
              continue;
            }
          }
          resolvedMsgs.add(msg);
        }

        newThreads.add(ChatThread(
          id: convId,
          name: recipientName,
          avatarInitials: recipientInitials,
          avatarUrl: avatarUrl,
          online: false,
          messages: resolvedMsgs,
          recipientId: otherUserId,
        ));
      }

      state = newThreads;
      if (ref.read(activeThreadIdProvider) == null) {
        final storage = ref.read(lastActiveThreadRepositoryProvider);
        final lastId = await storage.read(_lastActiveThreadKey);
        if (lastId != null && newThreads.any((t) => t.id == lastId)) {
          ref.read(activeThreadIdProvider.notifier).state = lastId;
        }
      }

      _subscribeToRealtime(conversationIds, myUserId);
      _initPresence(myUserId);

    } catch (e) {
      debugPrint('Error loading realtime threads: $e');
    }
  }

  void _initPresence(String myUserId) {
    _presenceChannel?.unsubscribe();
    final supabase = Supabase.instance.client;

    _presenceChannel = supabase.channel('online-users');

    _presenceChannel!
        .onPresenceSync((_) {
          final newState = _presenceChannel!.presenceState();
          final List<String> onlineIds = [];
          newState.forEach((singlePresence) {
            for (final presence in singlePresence.presences) {
              final payload = presence.payload;
              if (payload['user_id'] != null) {
                onlineIds.add(payload['user_id'].toString());
              }
            }
          });

          state = state.map((t) {
            final isOnline = t.recipientId != null && onlineIds.contains(t.recipientId);
            return t.copyWith(
              online: isOnline,
              lastActive: isOnline ? 'Đang hoạt động' : 'Ngoại tuyến',
            );
          }).toList();
        })
        .subscribe((status, [error]) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await _presenceChannel!.track({'user_id': myUserId});
          }
        });
  }

  void _subscribeToRealtime(List<dynamic> conversationIds, String myUserId) {
    _realtimeChannel?.unsubscribe();
    final supabase = Supabase.instance.client;

    _realtimeChannel = supabase.channel('public:chat_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (payload) async {
            final event = payload.eventType;
            final newMsg = payload.newRecord;

            if (event == PostgresChangeEvent.insert) {
              final convId = newMsg['conversation_id'] as String;
              if (!conversationIds.contains(convId)) return;
              
              final senderId = newMsg['sender_id'] as String;
              final contentStr = newMsg['content'] as String? ?? '';
              
              MessageType msgType = MessageType.text;
              String parsedText = contentStr;
              String? mediaUrl = newMsg['media_url'];
              
              if (newMsg['type'] != null) {
                msgType = MessageType.values.firstWhere(
                  (e) => e.name == newMsg['type'],
                  orElse: () => MessageType.text,
                );
              } else {
                if (contentStr.startsWith('[IMAGE]')) {
                  msgType = MessageType.image;
                  mediaUrl = contentStr.replaceFirst('[IMAGE]', '');
                  parsedText = 'Đã gửi một hình ảnh';
                } else if (contentStr.startsWith('[VIDEO]')) {
                  msgType = MessageType.video;
                  mediaUrl = contentStr.replaceFirst('[VIDEO]', '');
                  parsedText = 'Đã gửi một video';
                } else if (contentStr.startsWith('[GIF]')) {
                  msgType = MessageType.gif;
                  mediaUrl = contentStr.replaceFirst('[GIF]', '');
                  parsedText = 'Đã gửi một ảnh động';
                } else if (contentStr.startsWith('[VOICE]')) {
                  msgType = MessageType.voice;
                  mediaUrl = contentStr.replaceFirst('[VOICE]', '');
                  parsedText = 'Đã gửi tin nhắn thoại';
                } else if (contentStr.startsWith('[TASK]')) {
                  msgType = MessageType.task;
                  parsedText = contentStr.replaceFirst('[TASK]', '');
                }
              }

              final chatMsg = ChatMessage(
                id: newMsg['id'].toString(),
                threadId: convId,
                senderId: senderId == myUserId ? 'me' : senderId,
                senderName: senderId == myUserId ? 'Bạn' : 'Bạn bè',
                text: parsedText,
                type: msgType,
                mediaUrl: mediaUrl,
                timestamp: DateTime.parse(newMsg['created_at']).toLocal(),
                status: senderId == myUserId 
                    ? MessageStatus.sent 
                    : (newMsg['status'] == 'seen' ? MessageStatus.seen : MessageStatus.delivered),
                metaTitle: newMsg['task_id'] != null || newMsg['shared_task_id'] != null ? parsedText : null,
                metaSubtitle: newMsg['task_id'] != null || newMsg['shared_task_id'] != null ? 'Nhiệm vụ được chia sẻ' : null,
                fileName: newMsg['file_name'],
                fileSize: newMsg['file_size'],
                taskId: newMsg['task_id']?.toString(),
                replyToMessageId: newMsg['reply_to_message_id']?.toString(),
              );

              state = state.map((t) {
                if (t.id == convId) {
                  if (t.messages.any((m) => m.id == chatMsg.id)) return t;

                  // Resolve replyTo reference for this new incoming message!
                  ChatMessage resolvedChatMsg = chatMsg;
                  if (chatMsg.replyToMessageId != null) {
                    ChatMessage? found;
                    for (final m in t.messages) {
                      if (m.id == chatMsg.replyToMessageId) {
                        found = m;
                        break;
                      }
                    }
                    if (found != null) {
                      resolvedChatMsg = chatMsg.copyWith(replyTo: found);
                    }
                  }

                  return t.copyWith(
                    unread: senderId != myUserId,
                    messages: [...t.messages, resolvedChatMsg],
                  );
                }
                return t;
              }).toList();

              if (senderId != myUserId) {
                final activeThreadId = ref.read(activeThreadIdProvider);
                if (convId == activeThreadId) {
                  await markAllSeen(convId);
                } else {
                  try {
                    await supabase
                        .from('messages')
                        .update({'status': 'delivered'})
                        .eq('id', newMsg['id']);
                  } catch (e) {
                    debugPrint('Error updating message status on receive: $e');
                  }
                }
              }

            } else if (event == PostgresChangeEvent.update) {
              final convId = newMsg['conversation_id'] as String;
              if (!conversationIds.contains(convId)) return;
              
              final dbMsgId = newMsg['id'].toString();
              final statusStr = newMsg['status'] as String? ?? 'seen';
              
              MessageStatus newStatus = MessageStatus.seen;
              if (statusStr == 'sending') newStatus = MessageStatus.sending;
              else if (statusStr == 'sent') newStatus = MessageStatus.sent;
              else if (statusStr == 'delivered') newStatus = MessageStatus.delivered;

              state = state.map((t) {
                if (t.id == convId) {
                  final updatedMsgs = t.messages.map((m) {
                    if (m.id == dbMsgId) {
                      return m.copyWith(status: newStatus);
                    }
                    return m;
                  }).toList();
                  return t.copyWith(messages: updatedMsgs);
                }
                return t;
              }).toList();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'message_seen',
          callback: (payload) {
            final newSeen = payload.newRecord;
            final messageId = newSeen['message_id'] as String;
            final userId = newSeen['user_id'] as String;
            
            state = state.map((t) {
              final updatedMsgs = t.messages.map((m) {
                if (m.id == messageId && !m.seenByUserIds.contains(userId)) {
                  return m.copyWith(seenByUserIds: [...m.seenByUserIds, userId]);
                }
                return m;
              }).toList();
              return t.copyWith(messages: updatedMsgs);
            }).toList();
          }
        );
    _realtimeChannel!.subscribe();
  }

  Future<void> sendMessage(
    String threadId,
    String text, {
    MessageType type = MessageType.text,
    String? mediaUrl,
    ChatMessage? replyTo,
    String? metaTitle,
    String? metaSubtitle,
    String? fileName,
    int? fileSize,
    String? taskId,
    String? replyToId,
    void Function(double)? onUploadProgress,
  }) async {
    final supabase = Supabase.instance.client;
    final myUser = supabase.auth.currentUser;
    final msgId = 'msg_${DateTime.now().millisecondsSinceEpoch}';

    final localMsg = ChatMessage(
      id: msgId,
      threadId: threadId,
      senderId: 'me',
      senderName: 'Bạn',
      text: text,
      type: type,
      mediaUrl: mediaUrl,
      timestamp: DateTime.now(),
      replyTo: replyTo,
      status: MessageStatus.sending,
      metaTitle: metaTitle,
      metaSubtitle: metaSubtitle,
      fileName: fileName,
      fileSize: fileSize,
      taskId: taskId,
      replyToMessageId: replyToId ?? replyTo?.id,
    );

    state = state.map((t) {
      if (t.id == threadId) {
        return t.copyWith(messages: [...t.messages, localMsg]);
      }
      return t;
    }).toList();

    if (myUser == null) {
      Timer(const Duration(milliseconds: 600), () {
        updateMessageStatus(threadId, msgId, MessageStatus.sent);
      });
      Timer(const Duration(milliseconds: 1200), () {
        updateMessageStatus(threadId, msgId, MessageStatus.delivered);
      });
      Timer(const Duration(milliseconds: 1800), () {
        updateMessageStatus(threadId, msgId, MessageStatus.seen);
        Timer(const Duration(milliseconds: 1500), () {
          simulateReply(threadId, text);
        });
      });
      return;
    }

    final myUserId = myUser.id;

    try {
      String finalContent = text;
      String? finalMediaUrl = mediaUrl;

      if (mediaUrl != null && !mediaUrl.startsWith('http')) {
        try {
          final file = File(mediaUrl);
          if (await file.exists()) {
            final fileExt = mediaUrl.split('.').last;
            final uploadFileName = 'chat_${myUserId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
            final bytes = await file.readAsBytes();

            // Simulate progress callback or trigger it directly
            onUploadProgress?.call(0.2);
            await Future.delayed(const Duration(milliseconds: 100));
            onUploadProgress?.call(0.5);
            await Future.delayed(const Duration(milliseconds: 100));
            onUploadProgress?.call(0.8);

            await supabase.storage.from('bullet').uploadBinary(
              uploadFileName,
              bytes,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
            );
            
            onUploadProgress?.call(1.0);

            finalMediaUrl = supabase.storage.from('bullet').getPublicUrl(uploadFileName);
          }
        } catch (e) {
          debugPrint('Error uploading to bullet bucket: $e');
        }
      }

      if (type == MessageType.image) {
        finalContent = '[IMAGE]${finalMediaUrl ?? ""}';
      } else if (type == MessageType.video) {
        finalContent = '[VIDEO]${finalMediaUrl ?? ""}';
      } else if (type == MessageType.gif) {
        finalContent = '[GIF]${finalMediaUrl ?? ""}';
      } else if (type == MessageType.file) {
        finalContent = '[FILE]${finalMediaUrl ?? ""}';
      } else if (type == MessageType.voice || type == MessageType.audio) {
        finalContent = '[VOICE]${finalMediaUrl ?? ""}';
      } else if (type == MessageType.task) {
        finalContent = '[TASK]$text';
      }

      String? sharedTaskId = taskId;
      if (type == MessageType.task && sharedTaskId == null) {
        if (mediaUrl != null && mediaUrl.length == 36) {
          sharedTaskId = mediaUrl;
        }
      }

      final insertRes = await supabase.from('messages').insert({
        'conversation_id': threadId,
        'sender_id': myUserId,
        'content': finalContent,
        'type': type.name,
        'media_url': finalMediaUrl,
        'file_name': fileName,
        'file_size': fileSize,
        'task_id': sharedTaskId != null && _isValidUuid(sharedTaskId) ? sharedTaskId : null,
        'reply_to_message_id': localMsg.replyToMessageId != null && _isValidUuid(localMsg.replyToMessageId!) ? localMsg.replyToMessageId : null,
        'status': 'sent',
      }).select().single();

      final dbMsgId = insertRes['id'].toString();

      state = state.map((t) {
        if (t.id == threadId) {
          final updatedMsgs = t.messages.map((m) {
            if (m.id == msgId) {
              return m.copyWith(
                id: dbMsgId,
                status: MessageStatus.sent,
                mediaUrl: finalMediaUrl,
              );
            }
            return m;
          }).toList();
          return t.copyWith(messages: updatedMsgs);
        }
        return t;
      }).toList();

    } catch (e) {
      debugPrint('Error inserting message: $e');
      updateMessageStatus(threadId, msgId, MessageStatus.failed);
    }
  }

  void updateMessageStatus(String threadId, String msgId, MessageStatus newStatus) {
    state = state.map((t) {
      if (t.id == threadId) {
        final updatedMsgs = t.messages.map((m) {
          if (m.id == msgId) {
            return m.copyWith(status: newStatus);
          }
          return m;
        }).toList();
        return t.copyWith(messages: updatedMsgs);
      }
      return t;
    }).toList();
  }

  void toggleMuteThread(String threadId) {
    state = state.map((t) {
      if (t.id == threadId) {
        return t.copyWith(muted: !t.muted);
      }
      return t;
    }).toList();
  }

  void togglePinThread(String threadId) {
    state = state.map((t) {
      if (t.id == threadId) {
        return t.copyWith(pinned: !t.pinned);
      }
      return t;
    }).toList();
  }

  void toggleUnreadThread(String threadId) {
    state = state.map((t) {
      if (t.id == threadId) {
        return t.copyWith(unread: !t.unread);
      }
      return t;
    }).toList();
  }

  void deleteThread(String threadId) {
    state = state.where((t) => t.id != threadId).toList();
  }

  void deleteMessage(String threadId, String msgId) {
    state = state.map((t) {
      if (t.id == threadId) {
        final updatedMsgs = t.messages.where((m) => m.id != msgId).toList();
        return t.copyWith(messages: updatedMsgs);
      }
      return t;
    }).toList();
  }

  void editMessage(String threadId, String msgId, String newText) {
    state = state.map((t) {
      if (t.id == threadId) {
        final updatedMsgs = t.messages.map((m) {
          if (m.id == msgId) {
            return m.copyWith(text: newText);
          }
          return m;
        }).toList();
        return t.copyWith(messages: updatedMsgs);
      }
      return t;
    }).toList();
  }

  void recallMessage(String threadId, String msgId) {
    state = state.map((t) {
      if (t.id == threadId) {
        final updatedMsgs = t.messages.map((m) {
          if (m.id == msgId) {
            return m.copyWith(isRecalled: true);
          }
          return m;
        }).toList();
        return t.copyWith(messages: updatedMsgs);
      }
      return t;
    }).toList();
  }

  void togglePinMessage(String threadId, String msgId) {
    state = state.map((t) {
      if (t.id == threadId) {
        bool isNowPinned = false;
        final updatedMsgs = t.messages.map((m) {
          if (m.id == msgId) {
            isNowPinned = !m.isPinned;
            return m.copyWith(isPinned: isNowPinned);
          }
          return m;
        }).toList();

        final noticeMsg = ChatMessage(
          id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
          threadId: threadId,
          senderId: 'system',
          senderName: 'System',
          text: isNowPinned ? 'Bạn đã ghim một tin nhắn.' : 'Bạn đã bỏ ghim một tin nhắn.',
          type: MessageType.event,
          timestamp: DateTime.now(),
        );
        updatedMsgs.add(noticeMsg);

        return t.copyWith(messages: updatedMsgs);
      }
      return t;
    }).toList();
  }

  void addReaction(String threadId, String msgId, String emoji) {
    state = state.map((t) {
      if (t.id == threadId) {
        final updatedMsgs = t.messages.map((m) {
          if (m.id == msgId) {
            final newReactions = Map<String, List<String>>.from(m.reactions);
            if (newReactions.containsKey(emoji)) {
              if (newReactions[emoji]!.contains('me')) {
                // remove reaction
                newReactions[emoji]!.remove('me');
                if (newReactions[emoji]!.isEmpty) {
                  newReactions.remove(emoji);
                }
              } else {
                newReactions[emoji]!.add('me');
              }
            } else {
              newReactions[emoji] = ['me'];
            }
            return m.copyWith(reactions: newReactions);
          }
          return m;
        }).toList();
        return t.copyWith(messages: updatedMsgs);
      }
      return t;
    }).toList();
  }

  void simulateReply(String threadId, String outgoingText) {
    // Set isTyping to true
    state = state.map((t) {
      if (t.id == threadId) {
        return t.copyWith(isTyping: true);
      }
      return t;
    }).toList();

    Timer(const Duration(seconds: 2), () {
      final thread = state.firstWhere((t) => t.id == threadId);
      final msgId = 'reply_${DateTime.now().millisecondsSinceEpoch}';
      
      String replyText = 'Tôi đã nhận được tin nhắn: "$outgoingText". Có chuyện gì thế?';
      if (outgoingText.toLowerCase().contains('task') || outgoingText.toLowerCase().contains('công việc')) {
        replyText = 'Ok, tôi đang xem các task được giao đây. Sẽ hoàn thành đúng hạn!';
      } else if (outgoingText.toLowerCase().contains('hello') || outgoingText.toLowerCase().contains('chào')) {
        replyText = 'Chào bạn! Chúc một ngày tốt lành. Có gì cần hỗ trợ không?';
      } else if (outgoingText.trim() == '👍') {
        replyText = '👌';
      }

      final newMsg = ChatMessage(
        id: msgId,
        threadId: threadId,
        senderId: threadId,
        senderName: thread.name,
        text: replyText,
        timestamp: DateTime.now(),
        status: MessageStatus.seen,
      );

      state = state.map((t) {
        if (t.id == threadId) {
          return t.copyWith(
            isTyping: false,
            unread: true,
            messages: [...t.messages, newMsg],
          );
        }
        return t;
      }).toList();
    });
  }

  void addThread(String name) {
    final id = 'thread_${DateTime.now().millisecondsSinceEpoch}';
    final newThread = ChatThread(
      id: id,
      name: name,
      avatarInitials: name.isNotEmpty ? name[0].toUpperCase() : 'U',
      online: true,
      messages: [
        ChatMessage(
          id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
          threadId: id,
          senderId: id,
          senderName: name,
          text: 'Chào bạn! Bắt đầu trò chuyện nhé.',
          timestamp: DateTime.now(),
        )
      ],
    );
    state = [newThread, ...state];
  }
}

final chatThreadsProvider = StateNotifierProvider<ChatThreadsNotifier, List<ChatThread>>((ref) {
  return ChatThreadsNotifier(ref);
});

// Initial mock data to load in threads
final List<ChatThread> _initialMockThreads = [
  ChatThread(
    id: 'lan',
    name: 'Lan',
    avatarInitials: 'L',
    online: true,
    lastActive: 'Đang hoạt động',
    unread: true,
    messages: [
      ChatMessage(
        id: 'lan_1',
        threadId: 'lan',
        senderId: 'lan',
        senderName: 'Lan',
        text: 'Alo, bạn rảnh không? Xem hộ mình cái task này với.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      ChatMessage(
        id: 'lan_task_1',
        threadId: 'lan',
        senderId: 'lan',
        senderName: 'Lan',
        text: 'Đã gửi một Task: Fix Dashboard Layout Bugs',
        type: MessageType.task,
        metaTitle: 'Fix Dashboard Layout Bugs',
        metaSubtitle: 'Priority: Urgent | Due: Today',
        timestamp: DateTime.now().subtract(const Duration(minutes: 28)),
      ),
      ChatMessage(
        id: 'lan_2',
        threadId: 'lan',
        senderId: 'lan',
        senderName: 'Lan',
        text: 'Nhớ check sớm nha, khách hàng đang hối đó 🥺',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ],
  ),
  ChatThread(
    id: 'minh',
    name: 'Minh',
    avatarInitials: 'M',
    online: true,
    pinned: true,
    lastActive: 'Hoạt động 5 phút trước',
    messages: [
      ChatMessage(
        id: 'minh_1',
        threadId: 'minh',
        senderId: 'me',
        senderName: 'Bạn',
        text: 'Minh ơi, cái API upload ảnh xong chưa ấy nhỉ?',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ChatMessage(
        id: 'minh_2',
        threadId: 'minh',
        senderId: 'minh',
        senderName: 'Minh',
        text: 'Xong rồi nha ông ơi. Đã deploy lên staging test ok rồi.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ChatMessage(
        id: 'minh_3',
        threadId: 'minh',
        senderId: 'me',
        senderName: 'Bạn',
        text: 'Ok để mai làm 👍',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ],
  ),
  ChatThread(
    id: 'hung',
    name: 'Hùng',
    avatarInitials: 'H',
    online: false,
    lastActive: 'Hoạt động 1 ngày trước',
    messages: [
      ChatMessage(
        id: 'hung_1',
        threadId: 'hung',
        senderId: 'hung',
        senderName: 'Hùng',
        text: 'Cuối tuần này có đi đá bóng không?',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ChatMessage(
        id: 'hung_2',
        threadId: 'hung',
        senderId: 'me',
        senderName: 'Bạn',
        text: 'Có nha, 5h chiều sân Kỳ Hòa nha.',
        timestamp: DateTime.now().subtract(const Duration(hours: 20)),
      ),
      ChatMessage(
        id: 'hung_3',
        threadId: 'hung',
        senderId: 'hung',
        senderName: 'Hùng',
        text: 'Ok chốt.',
        timestamp: DateTime.now().subtract(const Duration(hours: 19)),
      ),
    ],
  ),
];

enum VoiceRecordingStatus { idle, recording, sending }

class VoiceRecordingState {
  final VoiceRecordingStatus status;
  final Duration elapsed;       // thời gian đã ghi
  final double amplitude;       // 0.0 – 1.0, từ mic input

  const VoiceRecordingState({
    this.status = VoiceRecordingStatus.idle,
    this.elapsed = Duration.zero,
    this.amplitude = 0.0,
  });

  VoiceRecordingState copyWith({
    VoiceRecordingStatus? status,
    Duration? elapsed,
    double? amplitude,
  }) => VoiceRecordingState(
    status: status ?? this.status,
    elapsed: elapsed ?? this.elapsed,
    amplitude: amplitude ?? this.amplitude,
  );
}

final voiceRecordingProvider =
    StateNotifierProvider<VoiceRecordingNotifier, VoiceRecordingState>(
  (ref) => VoiceRecordingNotifier(),
);

class VoiceRecordingNotifier extends StateNotifier<VoiceRecordingState> {
  VoiceRecordingNotifier() : super(const VoiceRecordingState());

  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;
  String? _filePath;

  // ── Bắt đầu ghi ──────────────────────────────────────────
  Future<void> startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return;

      final dir = await getTemporaryDirectory();
      _filePath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
        path: _filePath!,
      );

      state = state.copyWith(
        status: VoiceRecordingStatus.recording,
        elapsed: Duration.zero,
      );

      // Đếm giờ + lấy amplitude mỗi 100ms
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
        try {
          final amp = await _recorder.getAmplitude();
          final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
          state = state.copyWith(
            elapsed: state.elapsed + const Duration(milliseconds: 100),
            amplitude: normalized,
          );
        } catch (_) {}
      });
    } catch (_) {
      state = const VoiceRecordingState();
    }
  }

  // ── Gửi ──────────────────────────────────────────────────
  Future<String?> stopAndSend() async {
    try {
      _timer?.cancel();
      final path = await _recorder.stop();
      state = const VoiceRecordingState(); // reset về idle
      return path; // trả về path để gửi
    } catch (_) {
      state = const VoiceRecordingState();
      return null;
    }
  }

  // ── Huỷ ──────────────────────────────────────────────────
  Future<void> cancelRecording() async {
    try {
      _timer?.cancel();
      await _recorder.cancel();
    } catch (_) {}
    state = const VoiceRecordingState(); // reset về idle
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}

final isCallActiveProvider = StateProvider<bool>((ref) => false);
final isCallMinimizedProvider = StateProvider<bool>((ref) => false);

class ChatThemeModel {
  final String id;
  final String displayName;
  final String? subtitle;
  final List<Color> senderGradient;
  final Color recipientColor;
  final List<Color> chatBackgroundGradient;
  final Color accentColor;
  
  const ChatThemeModel({
    required this.id,
    required this.displayName,
    this.subtitle,
    required this.senderGradient,
    required this.recipientColor,
    required this.chatBackgroundGradient,
    required this.accentColor,
  });
}

final availableChatThemes = [
  const ChatThemeModel(
    id: 'default',
    displayName: 'Default',
    senderGradient: [Color(0xFF0084FF), Color(0xFF0084FF)],
    recipientColor: Color(0xFF2C2C2E),
    chatBackgroundGradient: [Color(0xFF1E1F20), Color(0xFF1E1F20)],
    accentColor: Color(0xFF0084FF),
  ),
  const ChatThemeModel(
    id: 'supergirl',
    displayName: 'Supergirl',
    senderGradient: [Color(0xFFDC2626), Color(0xFFB91C1C)],
    recipientColor: Color(0xFF243B55),
    chatBackgroundGradient: [Color(0xFF0F172A), Color(0xFF1E293B)],
    accentColor: Color(0xFFDC2626),
  ),
  const ChatThemeModel(
    id: 'avatar',
    displayName: 'Avatar: The Last Airbender',
    subtitle: 'Mùa 2',
    senderGradient: [Color(0xFF0D5C4B), Color(0xFF0F766E)],
    recipientColor: Color(0xFF4C3E35),
    chatBackgroundGradient: [Color(0xFF0D2E27), Color(0xFF111E1B)],
    accentColor: Color(0xFF0D5C4B),
  ),
  const ChatThemeModel(
    id: 'olivia',
    displayName: 'Olivia Rodrigo',
    senderGradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    recipientColor: Color(0xFF3B2E4F),
    chatBackgroundGradient: [Color(0xFF1E132D), Color(0xFF110B1B)],
    accentColor: Color(0xFF8B5CF6),
  ),
  const ChatThemeModel(
    id: 'football',
    displayName: 'Chế độ bóng đá',
    subtitle: 'Trò chơi bắt đầu',
    senderGradient: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    recipientColor: Color(0xFF213226),
    chatBackgroundGradient: [Color(0xFF0B2415), Color(0xFF09140C)],
    accentColor: Color(0xFF06B6D4),
  ),
  const ChatThemeModel(
    id: 'backstage',
    displayName: 'Hậu trường',
    senderGradient: [Color(0xFFD4AF37), Color(0xFFAA7C11)],
    recipientColor: Color(0xFF302E2A),
    chatBackgroundGradient: [Color(0xFF1D1B16), Color(0xFF141310)],
    accentColor: Color(0xFFD4AF37),
  ),
  const ChatThemeModel(
    id: 'deliboys',
    displayName: 'Deli Boys',
    senderGradient: [Color(0xFFF97316), Color(0xFFEF4444)],
    recipientColor: Color(0xFF3E2D26),
    chatBackgroundGradient: [Color(0xFF2E1A12), Color(0xFF1E0E08)],
    accentColor: Color(0xFFF97316),
  ),
];

class ThreadThemeNotifier extends StateNotifier<Map<String, String>> {
  ThreadThemeNotifier() : super({});

  void setTheme(String threadId, String themeId) {
    state = {...state, threadId: themeId};
  }
}

final threadThemeProvider = StateNotifierProvider<ThreadThemeNotifier, Map<String, String>>((ref) {
  return ThreadThemeNotifier();
});

class ThreadQuickReactionNotifier extends StateNotifier<Map<String, String>> {
  ThreadQuickReactionNotifier() : super({});

  void setQuickReaction(String threadId, String emoji) {
    state = {...state, threadId: emoji};
  }
}

final threadQuickReactionProvider = StateNotifierProvider<ThreadQuickReactionNotifier, Map<String, String>>((ref) {
  return ThreadQuickReactionNotifier();
});

class ThreadNicknamesNotifier extends StateNotifier<Map<String, Map<String, String>>> {
  ThreadNicknamesNotifier() : super({});

  void setNickname(String threadId, String userId, String nickname) {
    final threadMap = Map<String, String>.from(state[threadId] ?? {});
    if (nickname.trim().isEmpty) {
      threadMap.remove(userId);
    } else {
      threadMap[userId] = nickname;
    }
    state = {...state, threadId: threadMap};
  }
}

final threadNicknamesProvider = StateNotifierProvider<ThreadNicknamesNotifier, Map<String, Map<String, String>>>((ref) {
  return ThreadNicknamesNotifier();
});

enum InfoPanelTab { main, media, permissions, readReceipts }

final infoPanelTabProvider = StateProvider<InfoPanelTab>((ref) => InfoPanelTab.main);

class ThreadMuteDurationNotifier extends StateNotifier<Map<String, String>> {
  ThreadMuteDurationNotifier() : super({});

  void setMuteDuration(String threadId, String duration) {
    state = {...state, threadId: duration};
  }
}

final threadMuteDurationProvider = StateNotifierProvider<ThreadMuteDurationNotifier, Map<String, String>>((ref) {
  return ThreadMuteDurationNotifier();
});

class ThreadDisappearingMessagesNotifier extends StateNotifier<Map<String, String>> {
  ThreadDisappearingMessagesNotifier() : super({});

  void setDisappearingMessages(String threadId, String stateVal) {
    state = {...state, threadId: stateVal};
  }
}

final threadDisappearingMessagesProvider = StateNotifierProvider<ThreadDisappearingMessagesNotifier, Map<String, String>>((ref) {
  return ThreadDisappearingMessagesNotifier();
});

class ThreadReadReceiptsNotifier extends StateNotifier<Map<String, bool>> {
  ThreadReadReceiptsNotifier() : super({});

  void toggleReadReceipts(String threadId, bool value) {
    state = {...state, threadId: value};
  }
}

final threadReadReceiptsProvider = StateNotifierProvider<ThreadReadReceiptsNotifier, Map<String, bool>>((ref) {
  return ThreadReadReceiptsNotifier();
});

class ThreadPermissionsNotifier extends StateNotifier<Map<String, bool>> {
  ThreadPermissionsNotifier() : super({});

  void toggleAllowSharing(String threadId, bool value) {
    state = {...state, threadId: value};
  }
}

final threadPermissionsProvider = StateNotifierProvider<ThreadPermissionsNotifier, Map<String, bool>>((ref) {
  return ThreadPermissionsNotifier();
});

class ChatInputState {
  final String text;
  final ChatMessage? replyTo;

  const ChatInputState({this.text = '', this.replyTo});
}

class ChatInputNotifier extends StateNotifier<Map<String, ChatInputState>> {
  ChatInputNotifier() : super({});

  void setReplyTo(String threadId, ChatMessage? message) {
    final current = state[threadId] ?? const ChatInputState();
    state = {
      ...state,
      threadId: ChatInputState(text: current.text, replyTo: message),
    };
  }

  void clearReplyTo(String threadId) {
    final current = state[threadId] ?? const ChatInputState();
    state = {
      ...state,
      threadId: ChatInputState(text: current.text, replyTo: null),
    };
  }

  void setText(String threadId, String text) {
    final current = state[threadId] ?? const ChatInputState();
    state = {
      ...state,
      threadId: ChatInputState(text: text, replyTo: current.replyTo),
    };
  }
}

final chatInputProvider = StateNotifierProvider<ChatInputNotifier, Map<String, ChatInputState>>((ref) {
  return ChatInputNotifier();
});

// Thêm vào cuối message_state.dart

final replyingToProvider = StateProvider.family<ChatMessage?, String>(
  (ref, conversationId) => null,
);

const _lastActiveThreadKey = 'last_active_thread_id';

final lastActiveThreadRepositoryProvider = Provider((ref) {
  return ref.watch(secureStorageServiceProvider);
});