import 'package:flutter/material.dart';

import 'package:journexa/core/theme/app_colors.dart';

/// Shows the app-standard success snackbar (green, floating, check icon) so
/// confirmation feedback looks identical on every screen.
void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
}
