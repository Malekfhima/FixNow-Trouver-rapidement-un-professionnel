import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:fixnow/services/storage_service.dart';
import 'package:fixnow/core/services/error_mapper.dart';
import 'package:fixnow/services/firestore_service.dart';
import 'package:fixnow/services/firebase_auth_service.dart';
import 'package:fixnow/models/chat_model.dart';
import 'package:fixnow/features/notifications/notification_helpers.dart';
import 'package:fixnow/models/notification_model.dart';
import 'package:fixnow/models/user_model.dart';

/// Resolves a PUBLIC profile by uid (names/avatars in chat screens).
/// users/{uid} is private (email/phone/fcmToken) — publicProfiles only.
final userByIdProvider = FutureProvider.autoDispose.family<AppUser?, String>(
  (ref, uid) {
    if (uid.isEmpty) return Future.value(null);
    return ref.watch(firestoreServiceProvider).getPublicProfile(uid);
  },
);

/// State for chat list.
class ChatListState {
  final List<Chat> chats;
  final bool isLoading;
  final String? error;

  const ChatListState({
    this.chats = const [],
    this.isLoading = false,
    this.error,
  });

  ChatListState copyWith({
    List<Chat>? chats,
    bool? isLoading,
    String? error,
  }) {
    return ChatListState(
      chats: chats ?? this.chats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Controller that loads the current user's conversations.
class ChatListController extends StateNotifier<ChatListState> {
  final Ref _ref;

  ChatListController(this._ref) : super(const ChatListState()) {
    loadChats();
  }

  void loadChats() {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(chats: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final stream = _ref.read(firestoreServiceProvider).userChatsStream(user.uid);
    stream.listen(
      (chats) {
        state = state.copyWith(chats: chats, isLoading: false);
      },
      onError: (e, st) {
        debugPrint('chat stream error: $e');
        state = state.copyWith(isLoading: false, error: ErrorMapper.message(e));
      },
    );
  }
}

final chatListControllerProvider =
    StateNotifierProvider<ChatListController, ChatListState>((ref) {
  return ChatListController(ref);
});

/// Provides the currently selected chat (by id).
final selectedChatProvider = StateProvider<Chat?>((ref) => null);

/// State for a single chat detail.
class ChatDetailState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final String? otherId;

  const ChatDetailState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.otherId,
  });

  ChatDetailState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    String? otherId,
  }) {
    return ChatDetailState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      otherId: otherId ?? this.otherId,
    );
  }
}

class ChatDetailController extends StateNotifier<ChatDetailState> {
  final Ref _ref;
  final String chatId;
  StreamSubscription<List<ChatMessage>>? _messagesSub;

  ChatDetailController(this._ref, this.chatId)
      : super(const ChatDetailState()) {
    loadChat();
    _markReadOnOpen();
  }

  Future<void> _markReadOnOpen() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    try {
      await _ref.read(firestoreServiceProvider).markChatRead(chatId, user.uid);
    } catch (_) {}
  }

  Future<void> markReadNow() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    try {
      await _ref.read(firestoreServiceProvider).markChatRead(chatId, user.uid);
    } catch (_) {}
  }

  /// Uploads an image and sends it as a chat message.
  /// Uses [XFile] directly from ImagePicker — no dart:io needed.
  Future<void> sendImage() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 75,
      );
      if (picked == null) return;

      state = state.copyWith(isLoading: true);
      final storage = _ref.read(storageServiceProvider);
      final url = await storage.uploadChatImage(
        chatId,
        const Uuid().v4(),
        picked, // XFile — works on web and mobile
      );
      await sendMessage('', imageUrl: url);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Envoi de l\'image impossible',
      );
      debugPrint('sendImage failed: $e');
    }
  }

  StreamSubscription<List<Chat>>? _chatsSub;

  void loadChat() {
    state = state.copyWith(isLoading: true, error: null);

    final firestore = _ref.read(firestoreServiceProvider);
    final user = _ref.read(currentUserProvider);

    _messagesSub?.cancel();
    _messagesSub = firestore.messagesStream(chatId).listen(
      (messages) {
        state = state.copyWith(messages: messages, isLoading: false);
      },
      onError: (e, st) {
        debugPrint('chat stream error: $e');
        state = state.copyWith(isLoading: false, error: ErrorMapper.message(e));
      },
    );

    _chatsSub?.cancel();
    _chatsSub = firestore.userChatsStream(user?.uid ?? '').listen((chats) {
      final chat = chats.where((chat) => chat.id == chatId).firstOrNull;
      if (chat != null) {
        final other = chat.clientId == user?.uid ? chat.proId : chat.clientId;
        state = state.copyWith(otherId: other);
      }
    });
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _chatsSub?.cancel();
    super.dispose();
  }

  Future<void> sendMessage(String text, {String? imageUrl}) async {
    if (text.trim().isEmpty && imageUrl == null) return;

    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    final message = ChatMessage(
      id: '',
      senderId: user.uid,
      text: text.trim(),
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
    );

    try {
      await _ref.read(firestoreServiceProvider).sendMessage(
            chatId,
            message,
            senderId: user.uid,
          );

      // Notify the other participant (best-effort).
      try {
        final chatDoc = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .get();
        final data = chatDoc.data();
        if (data != null) {
          final otherId = data['clientId'] == user.uid
              ? data['proId'] as String?
              : data['clientId'] as String?;
          if (otherId != null && otherId.isNotEmpty) {
            await pushNotification(
              _ref,
              userId: otherId,
              type: NotificationType.newMessage,
              relatedId: chatId,
              title: 'Nouveau message',
              body: text.trim(),
            ).timeout(const Duration(seconds: 8));
          }
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('sendMessage failed: $e');
      state = state.copyWith(error: ErrorMapper.message(e));
    }
  }
}

final chatDetailControllerProvider = StateNotifierProvider.family<
    ChatDetailController, ChatDetailState, String>(
  (ref, chatId) => ChatDetailController(ref, chatId),
);

Future<String?> ensureChatBetween(
    {required String proId, required WidgetRef ref}) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return null;

  final firestore = ref.read(firestoreServiceProvider);

  final chatsStream = firestore.userChatsStream(user.uid);
  final existingChats = await chatsStream.first;

  final existing = existingChats.where((chat) {
    return (chat.clientId == user.uid && chat.proId == proId) ||
        (chat.proId == user.uid && chat.clientId == proId);
  }).toList();

  if (existing.isNotEmpty) return existing.first.id;

  final chat = Chat(
    id: '',
    clientId: user.uid,
    proId: proId,
    lastMessage: '',
    lastMessageAt: DateTime.now(),
  );

  final firestoreInstance = FirebaseFirestore.instance;
  final chatDocRef =
      await firestoreInstance.collection('chats').add(chat.toFirestore());

  return chatDocRef.id;
}
