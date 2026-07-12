import 'package:flutter/material.dart';

import 'package:journexa/core/constants/app_images.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({this.message, super.key});

  /// Optional caption under the animation; omitted by default so the
  /// loading state stays clean.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: Image.asset(
              AppImages.loading,
              width: 280,
              height: 280,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              // Fall back to the plain spinner if the GIF asset can't load
              // (e.g. widget tests, or the file being removed).
              errorBuilder: (context, _, __) => Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: primary,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5D6672),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
