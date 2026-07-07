import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/publication.dart';

class PublicationCard extends StatefulWidget {
  const PublicationCard({
    required this.publication,
    required this.onTap,
    super.key,
  });

  final Publication publication;
  final VoidCallback onTap;

  @override
  State<PublicationCard> createState() => _PublicationCardState();
}

class _PublicationCardState extends State<PublicationCard> {
  bool _hovered = false;

  static Color _citationBg(int count) {
    if (count > 500) return const Color(0xFFFEF3C7);
    if (count > 50) return const Color(0xFFECFDF5);
    if (count > 5) return const Color(0xFFEFF6FF);
    return const Color(0xFFF1F5F9);
  }

  static Color _citationFg(int count) {
    if (count > 500) return const Color(0xFFB45309);
    if (count > 50) return const Color(0xFF047857);
    if (count > 5) return const Color(0xFF1D4ED8);
    return const Color(0xFF475569);
  }

  static Color _accentBar(int count) {
    if (count > 500) return const Color(0xFFF59E0B);
    if (count > 50) return const Color(0xFF10B981);
    if (count > 5) return const Color(0xFF3B82F6);
    return const Color(0xFFCBD5E1);
  }

  @override
  Widget build(BuildContext context) {
    final pub = widget.publication;
    final citationText = NumberFormat.compact().format(pub.citedByCount);
    final citBg = _citationBg(pub.citedByCount);
    final citFg = _citationFg(pub.citedByCount);
    final bar = _accentBar(pub.citedByCount);

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            pub.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  color: const Color(0xFF0F172A),
                ),
          ),
          if (pub.authors.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              pub.authors.take(3).join(', ') +
                  (pub.authors.length > 3 ? ' et al.' : ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              _Chip(
                icon: Icons.calendar_today_outlined,
                label: pub.publicationYear?.toString() ?? 'N/A',
                bgColor: const Color(0xFFEFF6FF),
                fgColor: const Color(0xFF1D4ED8),
              ),
              _Chip(
                icon: Icons.format_quote,
                label: '$citationText citations',
                bgColor: citBg,
                fgColor: citFg,
              ),
              if (pub.journalName != null)
                _Chip(
                  icon: Icons.menu_book_outlined,
                  label: pub.journalName!,
                  bgColor: const Color(0xFFF5F3FF),
                  fgColor: const Color(0xFF6D28D9),
                ),
            ],
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: 'Open publication details',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    const BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: widget.onTap,
              // IntrinsicHeight lets CrossAxisAlignment.stretch work when
              // the card is inside a ListView with unbounded height.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 4,
                      decoration: BoxDecoration(
                        color: bar,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                      ),
                    ),
                    Expanded(child: content),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.fgColor,
  });

  final IconData icon;
  final String label;
  final Color bgColor;
  final Color fgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fgColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: fgColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
