import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/submission.dart';
import '../models/exam_type.dart';

class ContentViewerWidget extends StatelessWidget {
  final Submission submission;
  final int currentIndex;
  final int totalSubmissions;
  final ValueChanged<ExamType?> onExamTypeChanged;
  final VoidCallback onImportDocxRubric;
  final VoidCallback onConfigureCriteria;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final List<ExamType>? examTypes;

  const ContentViewerWidget({
    super.key,
    required this.submission,
    required this.currentIndex,
    required this.totalSubmissions,
    required this.onExamTypeChanged,
    required this.onImportDocxRubric,
    required this.onConfigureCriteria,
    required this.onPrev,
    required this.onNext,
    this.examTypes,
  });

  @override
  Widget build(BuildContext context) {
    final exam = submission.examType;
    final hasCustomRubric = exam?.customRubric != null && exam!.customRubric!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: Text(
                  submission.fileName,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Bài ${currentIndex + 1} / $totalSubmissions',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Rubric & Exam Type Configuration Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Đề thi:",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<ExamType>(
                        value: exam,
                        items: (examTypes ?? defaultExamTypes)
                            .map((e) => DropdownMenuItem(value: e, child: Text('Mã đề ${e.code}')))
                            .toList(),
                        onChanged: onExamTypeChanged,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 18, color: Color(0xFF6366F1)),
                      tooltip: "Cấu hình tiêu chí đề thi",
                      onPressed: onConfigureCriteria,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: onImportDocxRubric,
                      icon: const Icon(Icons.description_rounded, size: 16),
                      label: const Text("Nhập Rubric Word (.docx)"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: const Color(0xFF475569),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    if (hasCustomRubric)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            "Đã nạp Word Rubric",
                            style: GoogleFonts.inter(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            "Sử dụng Rubric mặc định",
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Content Editor
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SelectableText(
                  submission.content,
                  style: GoogleFonts.firaCode(
                    fontSize: 14,
                    height: 1.6,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Arrows Navigation Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: onPrev,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                padding: const EdgeInsets.all(12),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFEEF2FF),
                  foregroundColor: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 32),
              IconButton.filled(
                onPressed: onNext,
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                padding: const EdgeInsets.all(12),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
