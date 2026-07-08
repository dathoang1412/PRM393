import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:journexa/core/firebase/app_notification.dart';
import 'package:journexa/core/theme/app_colors.dart';

/// Shows a notification's full detail — untruncated body, full-size image,
/// and full timestamp — in a bottom sheet. The "expanded view" equivalent
/// of Android's big-picture system notification, reachable by tapping a row
/// in either the AppBar bell dropdown or the full Notification Center list.
void showNotificationDetail(BuildContext context, AppNotification notification) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _NotificationDetailSheet(notification: notification),
  );
}

class _NotificationDetailSheet extends StatelessWidget {
  const _NotificationDetailSheet({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (n.imageUrl != null) ...[
              const SizedBox(height: 16),
              Image.network(
                n.imageUrl!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.notifications,
                            size: 18, color: AppColors.seriesAuthors),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          n.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Text(
                      DateFormat('EEE, MMM d • HH:mm').format(n.receivedAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    n.body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.inkSecondary,
                          height: 1.55,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
