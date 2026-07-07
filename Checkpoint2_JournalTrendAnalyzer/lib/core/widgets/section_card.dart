import 'package:flutter/material.dart';

/// Card wrapping a chart or list section: a colored top-accent header with
/// an icon, title and subtitle, followed by [child]. Shared by every screen
/// that lays out chart/ranking sections (Dashboard, Trends, Analytics) so
/// the header markup lives in exactly one place.
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE6E2D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.03),
              border: Border(
                top: BorderSide(color: iconColor, width: 2.5),
                bottom: const BorderSide(color: Color(0xFFF3F1EA)),
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF222D3A),
                                  fontSize: 13,
                                ),
                      ),
                      Text(
                        subtitle,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF8F8D84),
                                  fontSize: 11,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}
