import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
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
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
        ],
      ),
    );
  }
}
