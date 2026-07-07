import 'package:flutter/material.dart';

import 'package:journexa/core/theme/app_colors.dart';
import 'year_range_filter.dart';

/// The "YEAR FILTER" pill followed by the year-range chips. Shared by the
/// Dashboard, Trends, and Rankings screens so the filter row renders
/// identically everywhere.
class FilterHeader extends StatelessWidget {
  const FilterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryWash,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.primaryBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_month_outlined,
                  size: 12, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                'YEAR FILTER',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: YearRangeFilter()),
      ],
    );
  }
}
