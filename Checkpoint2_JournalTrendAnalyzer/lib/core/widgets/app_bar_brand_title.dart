import 'package:flutter/material.dart';

import 'package:journexa/core/theme/app_colors.dart';

/// AppBar title used on every screen: the app's mark (small rounded-square
/// logo) followed by the current screen's title, so the brand stays visible
/// no matter where the user is in the app.
class AppBarBrandTitle extends StatelessWidget {
  const AppBarBrandTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.auto_stories, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
