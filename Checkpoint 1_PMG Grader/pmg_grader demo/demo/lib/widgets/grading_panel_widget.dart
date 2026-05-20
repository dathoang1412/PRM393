import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/submission.dart';
import '../models/exam_type.dart';

class GradingPanelWidget extends StatelessWidget {
  final Submission submission;
  final VoidCallback onAskAi;
  final VoidCallback onCopyAiToTeacher;
  final VoidCallback onSaveScores;
  final List<TextEditingController> scoreControllers;
  final TextEditingController commentController;
  final bool hasNext;

  const GradingPanelWidget({
    super.key,
    required this.submission,
    required this.onAskAi,
    required this.onCopyAiToTeacher,
    required this.onSaveScores,
    required this.scoreControllers,
    required this.commentController,
    required this.hasNext,
  });

  @override
  Widget build(BuildContext context) {
    final exam = submission.examType ?? defaultExamTypes.first;
    submission.initScores(exam);
    final hasRubric = exam.customRubric != null && exam.customRubric!.isNotEmpty;

    return Container(
      width: 520,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          left: BorderSide(
            color: Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'TRỢ LÝ AI',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.8,
                      color: const Color(0xFF6366F1),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                 Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                Expanded(
                  child: Text(
                    'NGƯỜI CHẤM',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.8,
                      color: const Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // AI panel
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: const Border(
                        right: BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: hasRubric ? onAskAi : null,
                            icon: const Icon(Icons.smart_toy, size: 16),
                            label: const Text('Chấm bằng AI'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasRubric ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                              foregroundColor: hasRubric ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
                              disabledBackgroundColor: const Color(0xFFF1F5F9),
                              disabledForegroundColor: const Color(0xFF94A3B8),
                              elevation: 0,
                              minimumSize: const Size(double.infinity, 42),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          if (!hasRubric) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9E6), // light amber
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFFE0B2)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: Color(0xFFD97706),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Vui lòng nạp Rubric Word (.docx) để chấm bằng AI',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFB45309),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          if (submission.hasAiGraded) ...[
                            Text(
                              'ĐIỂM AI GỢI Ý',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Render AI scores dynamically
                            ...exam.criteria.asMap().entries.map((entry) {
                              final index = entry.key;
                              final c = entry.value;
                              final scoreVal = index < submission.aiScores.length ? submission.aiScores[index] : 0.0;
                              return _buildAiScoreRow(c.name, scoreVal, c.maxScore10);
                            }),
                            const Divider(height: 32),
                            Text(
                              'Nhận xét AI:',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              submission.aiComment,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                height: 1.5,
                                color: const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: onCopyAiToTeacher,
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: const Text('Áp dụng điểm AI'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD1FAE5),
                                foregroundColor: const Color(0xFF065F46),
                                elevation: 0,
                                minimumSize: const Size(double.infinity, 42),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            )
                          ] else
                            const Padding(
                              padding: EdgeInsets.only(top: 48.0),
                              child: Center(
                                child: Text(
                                  'Chưa có kết quả AI.',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                ),
                // Human Grader Panel
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Render Human Score input fields dynamically
                          ...exam.criteria.asMap().entries.map((entry) {
                            final index = entry.key;
                            final c = entry.value;
                            if (index >= scoreControllers.length) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildScoreField(
                                '${c.name} (Tối đa: ${c.maxScore10})',
                                scoreControllers[index],
                              ),
                            );
                          }),
                          const Divider(height: 24),
                          _buildCommentField(commentController),
                          const SizedBox(height: 20),
                          // Total summary card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'TỔNG ĐIỂM (Thang 10)',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Builder(
                                  builder: (context) {
                                    double t = 0;
                                    for (var controller in scoreControllers) {
                                      t += double.tryParse(controller.text) ?? 0.0;
                                    }
                                    return Text(
                                      '${t.toStringAsFixed(1)} / 10.0',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF4F46E5),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: onSaveScores,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                hasNext ? 'Lưu & Bài tiếp theo' : 'Hoàn tất chấm điểm',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiScoreRow(String label, double score, double maxScore) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                score.toStringAsFixed(1),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                '/ $maxScore',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6366F1)),
            ),
          ),
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _buildCommentField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhận xét người chấm',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: 'Nhập ý kiến đánh giá...',
            hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6366F1)),
            ),
          ),
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B)),
        ),
      ],
    );
  }
}
