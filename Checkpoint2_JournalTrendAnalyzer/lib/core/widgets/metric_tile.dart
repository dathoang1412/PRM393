import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.iconColor,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Theme.of(context).colorScheme.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE8EDF5)),
      ),
      child: Stack(
        children: [
          // Left accent bar
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 11, 14, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(icon, color: color, size: 13),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.55,
                              fontSize: 9.5,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                    height: 1.15,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF94A3B8),
                          fontSize: 10,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
