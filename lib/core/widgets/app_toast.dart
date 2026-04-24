import 'package:flutter/material.dart';

enum AppToastType { success, info, error, loading }

class AppToast {
  const AppToast._();

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      backgroundColor: _backgroundColor(context, type),
      duration: type == AppToastType.loading ? const Duration(days: 1) : duration,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (type == AppToastType.loading) ...[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
          ] else ...[
            Icon(_iconFor(type), color: Colors.white, size: 18),
            const SizedBox(width: 12),
          ],
          Flexible(child: Text(message)),
        ],
      ),
    );

    return messenger.showSnackBar(snackBar);
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSuccess(
    BuildContext context,
    String message,
  ) {
    return show(context, message: message, type: AppToastType.success);
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showError(
    BuildContext context,
    String message,
  ) {
    return show(context, message: message, type: AppToastType.error, duration: const Duration(seconds: 3));
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLoading(
    BuildContext context,
    String message,
  ) {
    return show(context, message: message, type: AppToastType.loading);
  }

  static Color _backgroundColor(BuildContext context, AppToastType type) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (type) {
      AppToastType.success => colorScheme.primary,
      AppToastType.info => colorScheme.inverseSurface,
      AppToastType.error => colorScheme.error,
      AppToastType.loading => colorScheme.inverseSurface,
    };
  }

  static IconData _iconFor(AppToastType type) {
    return switch (type) {
      AppToastType.success => Icons.check_circle_outline,
      AppToastType.info => Icons.info_outline,
      AppToastType.error => Icons.error_outline,
      AppToastType.loading => Icons.hourglass_bottom,
    };
  }
}