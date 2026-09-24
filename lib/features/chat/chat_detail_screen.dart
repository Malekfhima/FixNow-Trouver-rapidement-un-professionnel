import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/app_avatar.dart';
import 'package:fixnow/core/widgets/skeleton.dart';
import 'package:fixnow/features/chat/chat_controller.dart';
import 'package:fixnow/services/firebase_auth_service.dart';
import 'package:fixnow/models/chat_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fixnow/features/professional_profile/pro_profile_controller.dart';

/// Chat detail screen for a single conversation.
class ChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;
  const ChatDetailScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Mark the conversation as read when it becomes visible again
    // (returning to the screen with unread messages).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(chatDetailControllerProvider(widget.chatId).notifier)
            .markReadNow();
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;

    ref.read(chatDetailControllerProvider(widget.chatId).notifier).sendMessage(text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatDetailControllerProvider(widget.chatId));

    // Resolve the other participant's display name (pro profile first,
    // user profile as fallback).
    final otherId = state.otherId;
    final otherName = otherId == null
        ? 'Conversation'
        : (ref.watch(proByIdProvider(otherId)).valueOrNull?.name ??
            ref.watch(userByIdProvider(otherId)).valueOrNull?.name ??
            'Conversation');
    final otherAvatar = otherId == null
        ? null
        : (ref.watch(proByIdProvider(otherId)).valueOrNull?.avatarUrl ??
            ref.watch(userByIdProvider(otherId)).valueOrNull?.avatarUrl);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            AppAvatar(
              url: otherAvatar,
              radius: 18,
              foregroundColor: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(otherName, style: AppTextStyles.h4),
                Text(
                  state.isLoading ? 'Chargement...' : 'En ligne',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: state.isLoading
                ? const MessageBubblesSkeleton()
                : state.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Erreur : ${state.error}',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              OutlinedButton.icon(
                                onPressed: () => ref
                                    .read(chatDetailControllerProvider(
                                            widget.chatId)
                                        .notifier)
                                    .loadChat(),
                                icon: const Icon(Icons.refresh_rounded,
                                    size: 18),
                                label: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : state.messages.isEmpty
                        ? const Center(
                            child: Text(
                              'Commencez la conversation...',
                              style: AppTextStyles.bodySmall,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: state.messages.length,
                            itemBuilder: (context, index) {
                              final msg = state.messages[index];
                              final currentUser = ref.watch(currentUserProvider);
                              final isMe = msg.senderId == currentUser?.uid;
                              return _MessageBubble(message: msg, isMe: isMe);
                            },
                          ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.camera_alt_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    tooltip: 'Envoyer une photo',
                    onPressed: () => ref
                        .read(chatDetailControllerProvider(widget.chatId)
                            .notifier)
                        .sendImage(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.fullAll,
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send_rounded,
                          color: Theme.of(context).colorScheme.onPrimary, size: 18),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.md),
            topRight: const Radius.circular(AppRadius.md),
            bottomLeft: Radius.circular(isMe ? AppRadius.md : 4),
            bottomRight: Radius.circular(isMe ? 4 : AppRadius.md),
          ),
          border: isMe ? null : Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Image message (optional)
            if (message.imageUrl != null) ...[
              ClipRRect(
                borderRadius: AppRadius.mdAll,
                child: CachedNetworkImage(
                  imageUrl: message.imageUrl!,
                  width: 220,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox(
                    width: 220,
                    height: 140,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => const SizedBox(
                    width: 220,
                    height: 60,
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            Text(
              _formatTime(message.timestamp),
              style: AppTextStyles.caption.copyWith(
                color: isMe
                    ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
