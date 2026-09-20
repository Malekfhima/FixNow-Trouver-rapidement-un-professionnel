import 'dart:async';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/core/services/error_mapper.dart';

/// Type of user-facing alert, driving the icon and semantic color.
enum AppAlertType { success, error, warning, info }

/// Centralized user-facing alerts: typed floating toasts, confirmation
/// dialogs and bottom sheets. Replaces scattered SnackBar/showDialog calls.
///
/// Toasts never stack: each call replaces the current one.
/// Never show raw exceptions — use [AppAlerts.fromError] which maps
/// errors through [ErrorMapper].
class AppAlerts {
  AppAlerts._();

  static void success(BuildContext context, String message,
      {String? actionLabel, VoidCallback? action}) {
    _show(context, AppAlertType.success, message,
        actionLabel: actionLabel, action: action);
  }

  static void error(BuildContext context, String message,
      {String? actionLabel, VoidCallback? action}) {
    _show(context, AppAlertType.error, message,
        actionLabel: actionLabel, action: action);
  }

  static void warning(BuildContext context, String message,
      {String? actionLabel, VoidCallback? action}) {
    _show(context, AppAlertType.warning, message,
        actionLabel: actionLabel, action: action);
  }

  static void info(BuildContext context, String message,
      {String? actionLabel, VoidCallback? action}) {
    _show(context, AppAlertType.info, message,
        actionLabel: actionLabel, action: action);
  }

  /// Maps a technical error to a French message and shows it as an error toast.
  static void fromError(BuildContext context, Object error,
      {String? actionLabel, VoidCallback? action}) {
    _show(context, AppAlertType.error, ErrorMapper.message(error),
        actionLabel: actionLabel, action: action);
  }

  static void _show(
    BuildContext context,
    AppAlertType type,
    String message, {
    String? actionLabel,
    VoidCallback? action,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;

    late final Color color;
    late final IconData icon;
    switch (type) {
      case AppAlertType.success:
        color = semantic.success;
        icon = Icons.check_circle_rounded;
      case AppAlertType.error:
        color = cs.error;
        icon = Icons.error_rounded;
      case AppAlertType.warning:
        color = semantic.warning;
        icon = Icons.warning_amber_rounded;
      case AppAlertType.info:
        color = semantic.info;
        icon = Icons.info_rounded;
    }

    // Replace the current toast instead of stacking.
    messenger
      ..removeCurrentSnackBar(reason: SnackBarClosedReason.hide)
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          elevation: 4,
          duration:
              type == AppAlertType.error || type == AppAlertType.warning
                  ? const Duration(seconds: 6)
                  : const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          backgroundColor: cs.inverseSurface,
          content: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: cs.onInverseSurface,
                  ),
                ),
              ),
            ],
          ),
          action: (actionLabel != null && action != null)
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: color,
                  onPressed: action,
                )
              : null,
        ),
      );
  }

  /// Confirmation dialog for sensitive actions. [destructive] highlights
  /// the confirm button with the error color (cancel, delete, sign out…).
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    bool destructive = false,
  }) async {
    final cs = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: Text(title, style: AppTextStyles.h4),
        content: message == null
            ? null
            : Text(message,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: cs.error)
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Themed bottom sheet for short forms and choice lists.
  static Future<T?> bottomSheet<T>(
    BuildContext context, {
    required String title,
    required WidgetBuilder builder,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.lg),
            builder(sheetContext),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Persistent offline banner shown at the top of the app whenever the
/// device loses connectivity. Mount once, e.g. via MaterialApp.builder.
class OfflineBanner extends StatefulWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  late final StreamSubscription<List<ConnectivityResult>> _sub;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _sub = Connectivity().onConnectivityChanged.listen(_update);
    // Initial state check.
    Connectivity().checkConnectivity().then(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final offline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (mounted && offline != _offline) {
      setState(() => _offline = offline);
    }
  }

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    return Stack(
      children: [
        widget.child,
        if (_offline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: semantic.warning,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          size: 16, color: Colors.black87),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Pas de connexion — certaines fonctionnalités sont indisponibles',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Empty state with icon, title, description and optional action.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.h4.copyWith(color: cs.onSurface),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state with a friendly message and a "Réessayer" button.
class ErrorState extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const ErrorState({super.key, this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Oups, une erreur est survenue',
              textAlign: TextAlign.center,
              style: AppTextStyles.h4.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error != null ? ErrorMapper.message(error!) : '',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
