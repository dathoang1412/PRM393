import 'package:flutter/material.dart';

/// A callout box for surfacing data insights with a strong left-accent strip.
class InsightNote extends StatelessWidget {
  const InsightNote({
    required this.text,
    this.icon = Icons.lightbulb_outline,
    this.color,
    this.label,
    super.key,
  });

  final String text;
  final IconData icon;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF1D4ED8);

    // ClipRRect + Container(Border.all uniform) avoids the Flutter restriction
    // that borderRadius requires uniform border colors.
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.04),
          border: Border.all(color: c.withValues(alpha: 0.14)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar — no borderRadius needed since ClipRRect clips
              Container(width: 3, color: c),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(icon, size: 14, color: c),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: label != null
                            ? RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$label  ',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: c,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    TextSpan(
                                      text: text,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: const Color(0xFF374151),
                                            height: 1.55,
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : Text(
                                text,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFF374151),
                                      height: 1.55,
                                    ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
