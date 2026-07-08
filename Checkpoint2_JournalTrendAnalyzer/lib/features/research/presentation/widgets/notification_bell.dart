import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:journexa/core/theme/app_colors.dart';
import '../viewmodels/notifications_viewmodel.dart';
import 'notification_detail_sheet.dart';

/// Bell icon with an unread-count badge; tapping it opens a dropdown of the
/// most recent FCM notifications without leaving the current screen. Shared
/// across every top-level tab's AppBar (Home, Journals, Keywords, Profile).
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationsViewModel>();
    final count = notifications.items.length;

    return PopupMenuButton<void>(
      key: const Key('notificationBell'),
      tooltip: 'Notifications',
      icon: Badge(
        label: Text('$count'),
        isLabelVisible: count > 0,
        backgroundColor: AppColors.danger,
        child: const Icon(Icons.notifications_outlined),
      ),
      // Drop the menu clearly below the bell instead of overlapping it, and
      // paint a crisp opaque card — Material 3's default surfaceTint would
      // otherwise wash the white background out to a muted grey.
      offset: const Offset(-8, 44),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      constraints: const BoxConstraints(minWidth: 300, maxWidth: 340),
      itemBuilder: (menuContext) {
        if (notifications.isEmpty) {
          return [
            PopupMenuItem<void>(
              child: Text(
                'No notifications yet',
                style: Theme.of(menuContext)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.inkMuted),
              ),
            ),
          ];
        }

        return [
          for (final n in notifications.items.take(6))
            PopupMenuItem<void>(
              // PopupMenuItem.onTap fires *before* the menu route pops, so
              // pushing a new route (the detail sheet) synchronously here
              // would race the pop animation. Deferring by a tick lets the
              // dropdown fully close first.
              onTap: () => Future.delayed(Duration.zero, () {
                if (context.mounted) showNotificationDetail(context, n);
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.circle_notifications_outlined,
                          size: 18, color: AppColors.seriesAuthors),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            n.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.inkSecondary),
                          ),
                          Text(
                            DateFormat.Hm().format(n.receivedAt),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    if (n.imageUrl != null) ...[
                      const SizedBox(width: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          n.imageUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const PopupMenuDivider(),
          PopupMenuItem<void>(
            onTap: () => context.read<NotificationsViewModel>().clear(),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_sweep_outlined,
                    size: 16, color: AppColors.danger),
                SizedBox(width: 6),
                Text('Clear all', style: TextStyle(color: AppColors.danger)),
              ],
            ),
          ),
        ];
      },
    );
  }
}
