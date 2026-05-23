import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/submission.dart';
import '../models/exam_type.dart';

class ContentViewerWidget extends StatefulWidget {
  final Submission submission;
  final int currentIndex;
  final int totalSubmissions;
  final ValueChanged<ExamType?> onExamTypeChanged;
  final VoidCallback onConfigureCriteria;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final List<ExamType> examTypes;
  final String? examImagePath;

  const ContentViewerWidget({
    super.key,
    required this.submission,
    required this.currentIndex,
    required this.totalSubmissions,
    required this.onExamTypeChanged,
    required this.onConfigureCriteria,
    required this.onPrev,
    required this.onNext,
    required this.examTypes,
    this.examImagePath,
  });

  @override
  State<ContentViewerWidget> createState() => _ContentViewerWidgetState();
}

class _ContentViewerWidgetState extends State<ContentViewerWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.submission.examType;
    final hasCustomRubric = exam?.customRubric != null && exam!.customRubric!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bottom controls (moved to top)
          _buildBottomControls(exam, hasCustomRubric),
          const SizedBox(height: 20),
          
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 16),
                      SizedBox(width: 6),
                      Text('Nội dung'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined, size: 16),
                      SizedBox(width: 6),
                      Text('Đề bài'),
                    ],
                  ),
                ),
              ],
              labelColor: const Color(0xFF6366F1),
              unselectedLabelColor: const Color(0xFF64748B),
              indicator: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSubmissionContent(),
                _buildExamImageContent(),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildSubmissionContent() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: SingleChildScrollView(
        child: Text(
          widget.submission.content,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.6,
            color: const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildExamImageContent() {
    if (widget.examImagePath == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_outlined,
                size: 48,
                color: const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 12),
              Text(
                'Không có đề bài',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // InteractiveViewer for zoom and pan
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(20),
              child: Image.file(
                File(widget.examImagePath!),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Không thể tải ảnh đề bài',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Zoom controls overlay
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.zoom_in, color: Colors.white, size: 20),
                      onPressed: () {
                        final currentScale = _transformationController.value.getMaxScaleOnAxis();
                        final newScale = (currentScale * 1.2).clamp(0.5, 4.0);
                        _transformationController.value = Matrix4.identity()..scale(newScale);
                      },
                      tooltip: "Phóng to (Ctrl +)",
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 4),
                    IconButton(
                      icon: const Icon(Icons.zoom_out, color: Colors.white, size: 20),
                      onPressed: () {
                        final currentScale = _transformationController.value.getMaxScaleOnAxis();
                        final newScale = (currentScale / 1.2).clamp(0.5, 4.0);
                        _transformationController.value = Matrix4.identity()..scale(newScale);
                      },
                      tooltip: "Thu nhỏ (Ctrl -)",
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 4),
                    IconButton(
                      icon: const Icon(Icons.center_focus_strong, color: Colors.white, size: 20),
                      onPressed: () {
                        _transformationController.value = Matrix4.identity();
                      },
                      tooltip: "Đưa về kích thước gốc",
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            
            // Zoom hint
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Sử dụng chuột/phím để zoom và di chuyển',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(ExamType? exam, bool hasCustomRubric) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          // Left side: Filename and counter
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.submission.fileName,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Bài ${widget.currentIndex + 1} / ${widget.totalSubmissions}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Middle: Exam selection
          Row(
            children: [
              Text(
                "Đề thi:",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 6),
              DropdownButtonHideUnderline(
                child: DropdownButton<ExamType>(
                  value: exam,
                  items: widget.examTypes
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.code)))
                      .toList(),
                  onChanged: widget.onExamTypeChanged,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 16, color: Color(0xFF6366F1)),
                tooltip: "Cấu hình tiêu chí đề thi",
                onPressed: widget.onConfigureCriteria,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Right side: Rubric info
          if (hasCustomRubric)
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  "Đã nạp Word Rubric",
                  style: GoogleFonts.inter(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 16),
                const SizedBox(width: 4),
                Text(
                  "Rubric mặc định",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous button
        IconButton.filledTonal(
          onPressed: widget.onPrev,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          padding: const EdgeInsets.all(12),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFEEF2FF),
            foregroundColor: const Color(0xFF6366F1),
          ),
        ),
        
        const SizedBox(width: 32),
        
        // Next button
        IconButton.filled(
          onPressed: widget.onNext,
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          padding: const EdgeInsets.all(12),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
