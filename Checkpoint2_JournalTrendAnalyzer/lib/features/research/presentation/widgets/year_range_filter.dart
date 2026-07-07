import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/research_provider.dart';

/// Horizontal scrolling chip row for filtering analytics by publication year.
class YearRangeFilter extends StatelessWidget {
  const YearRangeFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();
    final primary = Theme.of(context).colorScheme.primary;
    final curYear = DateTime.now().year;

    final options = <(String, int?, int?)>[
      ('All time', null, null),
      ('Last 5 yrs', curYear - 4, curYear),
      ('Last 10 yrs', curYear - 9, curYear),
      ('2015–2019', 2015, 2019),
      ('2010–2014', 2010, 2014),
      ('2000–2009', 2000, 2009),
      ('Before 2000', null, 1999),
    ];

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final (label, optFrom, optTo) = options[index];
          final isActive =
              provider.yearFrom == optFrom && provider.yearTo == optTo;

          return GestureDetector(
            onTap: () =>
                context.read<ResearchProvider>().setYearRange(optFrom, optTo),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive ? primary : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? primary : const Color(0xFFBFDBFE),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? Colors.white : const Color(0xFF1D4ED8),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
