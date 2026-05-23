import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/submission.dart';

class AppBarWidget extends StatelessWidget {
  final TextEditingController markerController;
  final VoidCallback onLoadZip;
  final VoidCallback onExportExcel;
  final VoidCallback onShowSettings;
  final bool hasSubmissions;
  final Submission? currentSubmission;
  final String? sessionName;

  const AppBarWidget({
    super.key,
    required this.markerController,
    required this.onLoadZip,
    required this.onExportExcel,
    required this.onShowSettings,
    required this.hasSubmissions,
    this.currentSubmission,
    this.sessionName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 24, color: Color(0xFF475569)),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Quay lại',
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.auto_stories_rounded,
            size: 28,
            color: Color(0xFF6366F1),
          ),
          const SizedBox(width: 10),
          Text(
            'PMG GRADER',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: const Color(0xFF1E293B),
            ),
          ),
          if (sessionName != null && sessionName!.isNotEmpty) ...[
            const SizedBox(width: 16),
            Container(
              height: 20,
              width: 1,
              color: const Color(0xFFE2E8F0),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Text(
                sessionName!,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4F46E5),
                ),
              ),
            ),
          ],
          const Spacer(),
          // Current Marker Display
          Container(
            width: 240,
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_rounded, size: 18, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentSubmission?.marker ?? (markerController.text.isNotEmpty 
                        ? markerController.text 
                        : 'Chưa có người chấm'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF475569)),
            onPressed: onShowSettings,
            tooltip: "Settings",
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: onLoadZip,
            icon: const Icon(Icons.folder_zip_rounded, size: 18),
            label: const Text('Load Zip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (hasSubmissions)
            ElevatedButton.icon(
              onPressed: onExportExcel,
              icon: const Icon(Icons.file_download_rounded, size: 18),
              label: const Text('Export Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
