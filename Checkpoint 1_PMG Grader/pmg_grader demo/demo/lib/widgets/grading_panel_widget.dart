import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/submission.dart';
import '../models/exam_type.dart';

class GradingPanelWidget extends StatefulWidget {
  final Submission submission;
  final VoidCallback onAskAi;
  final VoidCallback onCopyAiToTeacher;
  final VoidCallback onSaveScores;
  final List<TextEditingController> scoreControllers;
  final TextEditingController commentController;
  final bool hasNext;
  final ValueChanged<String> onRubricChanged;

  const GradingPanelWidget({
    super.key,
    required this.submission,
    required this.onAskAi,
    required this.onCopyAiToTeacher,
    required this.onSaveScores,
    required this.scoreControllers,
    required this.commentController,
    required this.hasNext,
    required this.onRubricChanged,
  });

  @override
  State<GradingPanelWidget> createState() => _GradingPanelWidgetState();
}

class _GradingPanelWidgetState extends State<GradingPanelWidget> {
  int _activeTabIndex = 0; // 0 for Tổng quan, 1 for GV chấm, 2 for AI tool
  late TextEditingController _rubricController;

  @override
  void initState() {
    super.initState();
    final exam = widget.submission.examType ?? defaultExamTypes.first;
    _rubricController = TextEditingController(text: exam.customRubric ?? "");
    _rubricController.addListener(_onRubricTextChanged);
  }

  void _onRubricTextChanged() {
    widget.onRubricChanged(_rubricController.text);
  }

  @override
  void didUpdateWidget(covariant GradingPanelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.submission != oldWidget.submission || 
        widget.submission.examType != oldWidget.submission.examType) {
      final exam = widget.submission.examType ?? defaultExamTypes.first;
      // Temporarily remove listener to avoid triggering callback during text reset
      _rubricController.removeListener(_onRubricTextChanged);
      _rubricController.text = exam.customRubric ?? "";
      _rubricController.addListener(_onRubricTextChanged);
    }
  }

  @override
  void dispose() {
    _rubricController.removeListener(_onRubricTextChanged);
    _rubricController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.submission.examType ?? defaultExamTypes.first;
    widget.submission.initScores(exam);
    final hasRubric = exam.customRubric != null && exam.customRubric!.isNotEmpty;

    return Container(
      width: 480,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(
            color: Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 3 Tabs Header
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9)),
              ),
            ),
            child: Row(
              children: [
                // Tab 1: Tổng quan
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTabIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _activeTabIndex == 0 ? const Color(0xFF6366F1) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.summarize_outlined,
                            size: 16,
                            color: _activeTabIndex == 0 ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'TỔNG QUAN',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                              color: _activeTabIndex == 0 ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                // Tab 2: GV chấm
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTabIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _activeTabIndex == 1 ? const Color(0xFF6366F1) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            size: 16,
                            color: _activeTabIndex == 1 ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'GV CHẤM',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                              color: _activeTabIndex == 1 ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                // Tab 3: AI tool
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTabIndex = 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _activeTabIndex == 2 ? const Color(0xFF6366F1) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.smart_toy_outlined,
                            size: 16,
                            color: _activeTabIndex == 2 ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AI TOOL',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                              color: _activeTabIndex == 2 ? const Color(0xFF6366F1) : const Color(0xFF64748B),
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
          
          // Tab Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: _buildActiveTabContent(exam, hasRubric),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent(ExamType exam, bool hasRubric) {
    switch (_activeTabIndex) {
      case 0:
        return _buildOverviewTab(exam);
      case 1:
        return _buildAssessmentTab(exam);
      case 2:
        return _buildAiToolTab(hasRubric);
      default:
        return const SizedBox();
    }
  }

  Widget _buildOverviewTab(ExamType exam) {
    return Column(
      key: const ValueKey('overview_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question summary
        Text(
          'CẤU TRÚC ĐIỂM ĐỀ THI',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        // List questions and point limits in a nice clean container
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: [
              ...exam.criteria.asMap().entries.map((entry) {
                final c = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        c.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      Text(
                        '${c.maxScore10.toStringAsFixed(1)} điểm',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng cộng',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '${exam.totalMaxScore10.toStringAsFixed(1)} điểm',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'TIÊU CHÍ CHẤM ĐIỂM (RUBRIC)',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Thông tin được trích xuất tự động từ file Word (.docx) của phiên chấm. Bạn có thể chỉnh sửa trực tiếp nội dung dưới đây để AI cập nhật tiêu chí chấm tức thì:',
          style: GoogleFonts.inter(
            fontSize: 12,
            height: 1.5,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _rubricController,
          maxLines: 18,
          minLines: 10,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: 'Nhập hoặc trích xuất tiêu chí chấm điểm tại đây...',
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
          style: GoogleFonts.inter(
            fontSize: 12.5,
            height: 1.5,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildAiToolTab(bool hasRubric) {
    final sub = widget.submission;
    final exam = sub.examType ?? defaultExamTypes.first;

    return Column(
      key: const ValueKey('ai_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: hasRubric ? widget.onAskAi : null,
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
          const SizedBox(height: 12),
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
                    'Vui lòng nhập hoặc nạp tiêu chí chấm điểm ở tab Tổng Quan để bắt đầu chấm bằng AI',
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
        if (sub.hasAiGraded) ...[
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
            final scoreVal = index < sub.aiScores.length ? sub.aiScores[index] : 0.0;
            final commentVal = index < sub.aiComments.length ? sub.aiComments[index] : "";
            return _buildAiScoreRow(
              c.name,
              scoreVal,
              c.maxScore10,
              commentVal,
              'Đã sao chép nhận xét: "${c.name}"',
            );
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
            sub.aiComment,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.5,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: widget.onCopyAiToTeacher,
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
              child: Column(
                children: [
                  Icon(Icons.smart_toy_outlined, size: 48, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 12),
                  Text(
                    'Chưa có kết quả AI.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
      ],
    );
  }

  Widget _buildAssessmentTab(ExamType exam) {
    return Column(
      key: const ValueKey('assessment_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Marker information
        if (widget.submission.marker != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Row(
              children: [
                Icon(Icons.person_rounded, size: 16, color: const Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Text(
                  'Người chấm: ${widget.submission.marker}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Render Human Score input fields dynamically
        ...exam.criteria.asMap().entries.map((entry) {
          final index = entry.key;
          final c = entry.value;
          if (index >= widget.scoreControllers.length) return const SizedBox();
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildScoreField(
              '${c.name} (Tối đa: ${c.maxScore10})',
              widget.scoreControllers[index],
            ),
          );
        }),
        const Divider(height: 24),
        _buildCommentField(widget.commentController),
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
                  for (var controller in widget.scoreControllers) {
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
            onPressed: widget.onSaveScores,
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
              widget.hasNext ? 'Lưu & Bài tiếp theo' : 'Hoàn tất chấm điểm',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiScoreRow(String label, double score, double maxScore, String comment, String successMessage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
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
          const SizedBox(height: 6),
          // Comment box with a copy button next to it
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    comment.isNotEmpty ? comment : "Không có nhận xét từ AI cho câu này.",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: comment.isNotEmpty ? const Color(0xFF334155) : const Color(0xFF94A3B8),
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CopyCommentButton(
                textToCopy: comment,
                successMessage: successMessage,
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

class CopyCommentButton extends StatefulWidget {
  final String textToCopy;
  final String successMessage;

  const CopyCommentButton({
    super.key,
    required this.textToCopy,
    required this.successMessage,
  });

  @override
  State<CopyCommentButton> createState() => _CopyCommentButtonState();
}

class _CopyCommentButtonState extends State<CopyCommentButton> {
  bool _copied = false;

  void _handleCopy() {
    if (widget.textToCopy.isEmpty) return;
    Clipboard.setData(ClipboardData(text: widget.textToCopy));
    
    setState(() {
      _copied = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.successMessage,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF10B981), // emerald success color
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _copied ? 'Đã sao chép!' : 'Sao chép nhận xét',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.textToCopy.isNotEmpty ? _handleCopy : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _copied ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _copied ? const Color(0xFF34D399) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              size: 16,
              color: _copied ? const Color(0xFF059669) : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}
