import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/features/chat/chat_controller.dart';
import 'package:fixnow/models/chat_model.dart';
import 'package:fixnow/services/firebase_auth_service.dart';

/// Chat list screen showing all conversations.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatListControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Messages'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: chatState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : chatState.error != null
              ? Center(child: Text('Erreur: ${chatState.error}'))
              : chatState.chats.isEmpty
                  ? _emptyState(context)
                  : RefreshIndicator(
                      onRefresh: () async => ref.read(chatListControllerProvider.notifier).loadChats(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: chatState.chats.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final chat = chatState.chats[index];
                          return _ChatListItem(chat: chat, onTap: () => context.push('/chat/${chat.id}'));
                        },
                      ),
                    ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Aucun message',
            style: AppTextStyles.h4.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Vos conversations apparaîtront ici',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ChatListItem extends ConsumerWidget {
  final Chat chat;
  final VoidCallback onTap;

  const _ChatListItem({required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final otherId = chat.clientId == currentUser?.uid ? chat.proId : chat.clientId;
    final other = ref.watch(userByIdProvider(otherId)).valueOrNull;
    final unread = currentUser == null ? 0 : chat.unreadFor(currentUser.uid);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage:
                  other?.avatarUrl != null ? NetworkImage(other!.avatarUrl!) : null,
              child: other?.avatarUrl == null
                  ? const Icon(Icons.person, color: AppColors.primary, size: 22)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    other?.name.isNotEmpty == true
                        ? other!.name
                        : (otherId.isEmpty ? 'Utilisateur' : 'Conversation'),
                    style: AppTextStyles.h4,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chat.lastMessage.isEmpty ? 'Pas encore de messages' : chat.lastMessage,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(chat.lastMessageAt),
                  style: AppTextStyles.caption,
                ),
                if (unread > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unread',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Hier';
    return '${dt.day}/${dt.month}';
  }
}
