import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/features/notifications/notifications_controller.dart';
import 'package:fixnow/models/notification_model.dart';

/// In-app notifications screen.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);

    timeago.setLocaleMessages('fr', timeago.FrMessages());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsControllerProvider.notifier).markAllRead(),
            child: const Text('Tout lire'),
          ),
        ],
      ),
      body: async.when(
        data: (items) => items.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined,
                        size: 64, color: AppColors.textHint),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Aucune notification',
                        style: AppTextStyles.h4
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(notificationsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _NotificationTile(item: item);
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationItem item;
  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, color) = _iconFor(item.type);

    return Container(
      decoration: BoxDecoration(
        color: item.read ? AppColors.white : AppColors.primaryContainer.withValues(alpha: 0.35),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          item.title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: item.read ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              timeago.format(item.createdAt, locale: 'fr'),
              style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () => _handleTap(context, ref),
        trailing: item.read
            ? null
            : IconButton(
                icon: const Icon(Icons.done_all_rounded, size: 18),
                tooltip: 'Marquer comme lue',
                onPressed: () => ref
                    .read(notificationsControllerProvider.notifier)
                    .markRead(item.id),
              ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    // Mark as read when opened.
    if (!item.read) {
      ref.read(notificationsControllerProvider.notifier).markRead(item.id);
    }
    switch (item.type) {
      case NotificationType.quoteReceived:
      case NotificationType.requestAccepted:
      case NotificationType.requestDeclined:
      case NotificationType.requestCompleted:
      case NotificationType.requestCancelled:
        if (item.relatedId != null) context.push('/orders');
        break;
      case NotificationType.newMessage:
        if (item.relatedId != null) context.push('/chat/${item.relatedId}');
        break;
      case NotificationType.proApproved:
      case NotificationType.proRejected:
        context.push('/profile');
        break;
      case NotificationType.generic:
        break;
    }
  }

  (IconData, Color) _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.newMessage:
        return (Icons.chat_bubble_outline_rounded, AppColors.primary);
      case NotificationType.quoteReceived:
        return (Icons.request_quote_outlined, AppColors.accent);
      case NotificationType.requestAccepted:
        return (Icons.check_circle_outline_rounded, AppColors.success);
      case NotificationType.requestDeclined:
        return (Icons.cancel_outlined, AppColors.error);
      case NotificationType.requestCompleted:
        return (Icons.task_alt_rounded, AppColors.success);
      case NotificationType.requestCancelled:
        return (Icons.event_busy_outlined, AppColors.textSecondary);
      case NotificationType.proApproved:
        return (Icons.verified_outlined, AppColors.success);
      case NotificationType.proRejected:
        return (Icons.warning_amber_outlined, AppColors.error);
      case NotificationType.generic:
        return (Icons.notifications_none_rounded, AppColors.textSecondary);
    }
  }
}
