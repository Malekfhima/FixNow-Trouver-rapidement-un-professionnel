import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixnow/services/firestore_service.dart';
import 'package:fixnow/services/firebase_auth_service.dart';
import 'package:fixnow/models/chat_model.dart';
import 'package:fixnow/features/notifications/notification_helpers.dart';
import 'package:fixnow/models/notification_model.dart';
import 'package:fixnow/models/user_model.dart';

/// Resolves a user profile by uid (names/avatars in chat screens).
final userByIdProvider = FutureProvider.autoDispose.family<AppUser?, String>(
  (ref, uid) {
    if (uid.isEmpty) return Future.value(null);
    return ref.watch(firestoreServiceProvider).getUser(uid);
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
        state = state.copyWith(isLoading: false, error: e.toString());
      },
    );
  }
}

final chatListControllerProvider = StateNotifierProvider<ChatListController, ChatListState>((ref) {
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

  ChatDetailController(this._ref, this.chatId) : super(const ChatDetailState()) {
    loadChat();
  }

  void loadChat() {
    state = state.copyWith(isLoading: true, error: null);

    final firestore = _ref.read(firestoreServiceProvider);
    final user = _ref.read(currentUserProvider);

    final messagesStream = firestore.messagesStream(chatId);
    final chatsStream = firestore.userChatsStream(user?.uid ?? '');

    // Keep a handle on the chat list so we can derive participant info.
    StreamSubscription<List<Chat>>? chatSub;
    chatSub = chatsStream.listen((chats) {
      final chat = chats.where((chat) => chat.id == chatId).firstOrNull;
      if (chat != null) {
        final other = chat.clientId == user?.uid ? chat.proId : chat.clientId;
        state = state.copyWith(otherId: other);
      }
    });

    messagesStream.listen(
      (messages) {
        state = state.copyWith(messages: messages, isLoading: false);
      },
      onError: (e, st) {
        state = state.copyWith(isLoading: false, error: e.toString());
      },
    ).onDone(chatSub.cancel);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    final message = ChatMessage(
      id: '', // Firestore will provide the document id
      senderId: user.uid,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    try {
      await _ref.read(firestoreServiceProvider).sendMessage(chatId, message);

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
            );
          }
        }
      } catch (_) {}
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final chatDetailControllerProvider =
    StateNotifierProvider.family<ChatDetailController, ChatDetailState, String>(
  (ref, chatId) => ChatDetailController(ref, chatId),
);

/// Creates a chat between a client and a pro if one doesn't exist yet.
/// Accepts a [WidgetRef] so it can be called from widgets (e.g. router helpers).
Future<String?> ensureChatBetween({required String proId, required WidgetRef ref}) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return null;

  final firestore = ref.read(firestoreServiceProvider);

  // Look for an existing chat between these two participants.
  final chatsStream = firestore.userChatsStream(user.uid);
  final existingChats = await chatsStream.first;

  final existing = existingChats.where((chat) {
    return (chat.clientId == user.uid && chat.proId == proId) ||
        (chat.proId == user.uid && chat.clientId == proId);
  }).toList();

  if (existing.isNotEmpty) return existing.first.id;

  // Create a new chat.
  final chat = Chat(
    id: '',
    clientId: user.uid,
    proId: proId,
    lastMessage: '',
    lastMessageAt: DateTime.now(),
  );

  final firestoreInstance = FirebaseFirestore.instance;
  final chatDocRef = await firestoreInstance.collection('chats').add(chat.toFirestore());

  return chatDocRef.id;
}
