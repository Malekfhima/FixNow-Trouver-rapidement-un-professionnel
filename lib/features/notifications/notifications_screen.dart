import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/widgets/app_alerts.dart';
import 'package:fixnow/core/widgets/skeleton.dart';
import 'package:fixnow/features/home/home_controller.dart'
    show userProfileProvider;
import 'package:fixnow/features/notifications/notifications_controller.dart';
import 'package:fixnow/models/notification_model.dart';
import 'package:fixnow/services/notification_routing.dart';

/// Locale init (once per app run — not in build).
bool _timeagoLocaleRegistered = false;

void _ensureTimeagoLocale() {
  if (!_timeagoLocaleRegistered) {
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    _timeagoLocaleRegistered = true;
  }
}

/// In-app notifications screen.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    _ensureTimeagoLocale();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
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
            ? const EmptyState(
                icon: Icons.notifications_off_outlined,
                title: 'Aucune notification',
                message:
                    'Vous serez prévenu des devis, messages et prestations.',
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
        loading: () => const NotificationSkeletonList(),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationItem item;
  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, color) = _iconFor(context, item.type);

    // tileColor + shape (et non un Container décoré) : un ListTile peint
    // son fond sur le Material ancêtre — un DecoratedBox intermédiaire le
    // masquerait (assertion Flutter en test).
    return ListTile(
      tileColor: item.read
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
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
              style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    // Mark as read when opened.
    if (!item.read) {
      ref.read(notificationsControllerProvider.notifier).markRead(item.id);
    }
    // Même table de routage que le tap sur notification locale / push FCM.
    final isPro =
        ref.read(userProfileProvider).valueOrNull?.isPro ?? false;
    final location = resolveNotificationLocation(
      type: item.type.name,
      relatedId: item.relatedId,
      isPro: isPro,
    );
    if (location != null) context.push(location);
  }

  (IconData, Color) _iconFor(BuildContext context, NotificationType type) {
    switch (type) {
      case NotificationType.newMessage:
        return (Icons.chat_bubble_outline_rounded, AppColors.primary);
      case NotificationType.quoteReceived:
        return (Icons.request_quote_outlined, AppColors.accent);
      case NotificationType.requestStarted:
        return (Icons.construction_rounded, AppColors.accent);
      case NotificationType.reviewReceived:
        return (Icons.rate_review_outlined, AppColors.accent);
      case NotificationType.requestAccepted:
        return (Icons.check_circle_outline_rounded, AppColors.success);
      case NotificationType.requestDeclined:
        return (Icons.cancel_outlined, AppColors.error);
      case NotificationType.requestCompleted:
        return (Icons.task_alt_rounded, AppColors.success);
      case NotificationType.requestCancelled:
        return (Icons.event_busy_outlined, Theme.of(context).colorScheme.onSurfaceVariant);
      case NotificationType.proApproved:
        return (Icons.verified_outlined, AppColors.success);
      case NotificationType.proRejected:
        return (Icons.warning_amber_outlined, AppColors.error);
      case NotificationType.generic:
        return (Icons.notifications_none_rounded, Theme.of(context).colorScheme.onSurfaceVariant);
    }
  }
}
