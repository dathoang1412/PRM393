import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/submission.dart';

class SidebarWidget extends StatelessWidget {
  final List<Submission> submissions;
  final int currentIndex;
  final ValueChanged<int> onSubmissionSelected;
  final double width;

  const SidebarWidget({
    super.key,
    required this.submissions,
    required this.currentIndex,
    required this.onSubmissionSelected,
    this.width = 280,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: submissions.length,
              itemBuilder: (context, index) {
                final sub = submissions[index];
                final isSelected = index == currentIndex;
                final status = _submissionStatus(sub);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  child: ListTile(
                    selected: isSelected,
                    selectedTileColor: const Color(0xFFEEF2FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    leading: Icon(
                      status.icon,
                      color: status.color,
                      size: 20,
                    ),
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
                    subtitle: Text(
                      status.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: status.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

  _SidebarSubmissionStatus _submissionStatus(Submission submission) {
    if (submission.graded) {
      return const _SidebarSubmissionStatus(
        label: 'Human complete',
        icon: Icons.check_circle_rounded,
        color: Color(0xFF1A7F37),
      );
    }
    if (submission.hasAiGraded) {
      return const _SidebarSubmissionStatus(
        label: 'AI graded',
        icon: Icons.smart_toy_rounded,
        color: Color(0xFF2DA44E),
      );
    }
    if (submission.opened) {
      return const _SidebarSubmissionStatus(
        label: 'Clicked - needs review',
        icon: Icons.pending_rounded,
        color: Color(0xFFBF8700),
      );
    }
    return const _SidebarSubmissionStatus(
      label: 'Open',
      icon: Icons.radio_button_unchecked_rounded,
      color: Color(0xFF8C959F),
    );
  }
}

class _SidebarSubmissionStatus {
  final String label;
  final IconData icon;
  final Color color;

  const _SidebarSubmissionStatus({
    required this.label,
    required this.icon,
    required this.color,
  });
}
