import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/submission.dart';

class SidebarWidget extends StatelessWidget {
  final List<Submission> submissions;
  final int currentIndex;
  final ValueChanged<int> onSubmissionSelected;

  const SidebarWidget({
    super.key,
    required this.submissions,
    required this.currentIndex,
    required this.onSubmissionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          right: BorderSide(
            color: Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bài nộp',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${submissions.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _countBadge(
                  submissions.where((s) => s.graded).length,
                  const Color(0xFF10B981),
                  const Color(0xFFD1FAE5),
                  'đã chấm',
                ),
                const SizedBox(width: 8),
                _countBadge(
                  submissions.where((s) => !s.graded).length,
                  const Color(0xFF94A3B8),
                  const Color(0xFFF1F5F9),
                  'chưa chấm',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: submissions.length,
              itemBuilder: (context, index) {
                final sub = submissions[index];
                final isSelected = index == currentIndex;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  child: ListTile(
                    selected: isSelected,
                    selectedTileColor: const Color(0xFFEEF2FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    leading: _buildStatusIcon(sub, isSelected),
                    title: Text(
                      sub.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                        color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF334155),
                      ),
                    ),
                    trailing: sub.graded ? _buildScoreBadge(sub.total) : null,
                    onTap: () => onSubmissionSelected(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(Submission sub, bool isSelected) {
    if (sub.graded) {
      return const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20);
    } else {
      return Icon(
        Icons.description_outlined,
        color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
        size: 20,
      );
    }
  }

  static Widget _buildScoreBadge(double total) {
    final isPass = total >= 4.0;
    final textColor = isPass ? const Color(0xFF065F46) : const Color(0xFF991B1B);
    final bgColor = isPass ? const Color(0xFFD1FAE5) : const Color(0xFFFFE4E6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        total.toStringAsFixed(1),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  static Widget _countBadge(int count, Color textColor, Color bgColor, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count $label',
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}
