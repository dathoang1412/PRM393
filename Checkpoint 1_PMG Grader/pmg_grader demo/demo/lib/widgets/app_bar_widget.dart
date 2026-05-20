import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppBarWidget extends StatelessWidget {
  final TextEditingController markerController;
  final VoidCallback onLoadZip;
  final VoidCallback onExportExcel;
  final VoidCallback onShowSettings;
  final bool hasSubmissions;

  const AppBarWidget({
    super.key,
    required this.markerController,
    required this.onLoadZip,
    required this.onExportExcel,
    required this.onShowSettings,
    required this.hasSubmissions,
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
          const Icon(
            Icons.auto_stories_rounded,
            size: 32,
            color: Color(0xFF6366F1),
          ),
          const SizedBox(width: 12),
          Text(
            'PMG GRADER',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: const Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          // Marker Name Input Field
          Container(
            width: 240,
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            child: TextField(
              controller: markerController,
              decoration: InputDecoration(
                hintText: 'Nhập tên người chấm...',
                prefixIcon: const Icon(Icons.person_rounded, size: 18, color: Color(0xFF6366F1)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                ),
              ),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
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
