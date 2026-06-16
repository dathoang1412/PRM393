import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/publication.dart';

class PublicationDetailScreen extends StatelessWidget {
  const PublicationDetailScreen({required this.publication, super.key});

  final Publication publication;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final citationText = NumberFormat.decimalPattern().format(
      publication.citedByCount,
    );
    final authorPreview = _authorPreviewText(publication.authors);
    return Scaffold(
      appBar: AppBar(title: const Text('Publication Details')),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              publication.title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Authors: ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: authorPreview),
                ],
              ),
              style: textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF475569),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: publication.publicationYear?.toString() ?? 'Unknown',
                ),
                _InfoChip(
                  icon: Icons.format_quote,
                  label: '$citationText citations',
                  color: const Color(0xFFD97706),
                ),
                _InfoChip(
                  icon: Icons.menu_book_outlined,
                  label: publication.journalName ?? 'Unknown venue',
                  color: const Color(0xFF7C3AED),
                  maxWidth: 300,
                ),
              ],
            ),
            if (publication.doi != null) ...[
              const SizedBox(height: 12),
              _DoiRow(doi: publication.doi!),
            ],
            const SizedBox(height: 16),
            _Section(
              title: 'Abstract',
              child: Text(
                publication.abstractText ??
                    'No abstract available from OpenAlex.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _authorPreviewText(List<String> authors) {
  if (authors.isEmpty) return 'Unknown authors';
  if (authors.length <= 3) return authors.join(', ');

  final visibleAuthors = authors.take(3).join(', ');
  final hiddenCount = authors.length - 3;
  return '$visibleAuthors, and $hiddenCount more';
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = const Color(0xFF2563EB),
    this.maxWidth = 190,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoiRow extends StatelessWidget {
  const _DoiRow({required this.doi});

  final String doi;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.link_outlined, size: 16, color: Color(0xFF64748B)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            doi,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.3,
                ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
