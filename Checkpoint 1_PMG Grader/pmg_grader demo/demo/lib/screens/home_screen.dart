import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../services/session_service.dart';
import 'main_screen.dart';

// ─── Colour tokens ────────────────────────────────────────────────────────────
const _kBg = Color(0xFF0F1117);
const _kSurface = Color(0xFF1A1D27);
const _kCard = Color(0xFF20243A);
const _kBorder = Color(0xFF2E3350);
const _kPrimary = Color(0xFF6C63FF);
const _kPrimaryLight = Color(0xFF9D97FF);
const _kAccent = Color(0xFF00D4AA);
const _kTextPrimary = Color(0xFFF0F2FF);
const _kTextSecondary = Color(0xFF8B8FA8);
const _kSuccess = Color(0xFF22C55E);
const _kWarning = Color(0xFFF59E0B);

// ─── Home Screen ──────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final SessionService _sessionService = SessionService();
  List<GradingSession> _sessions = [];
  bool _loading = true;
  late AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _loadSessions();
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    final sessions = await _sessionService.loadSessions();
    if (mounted) setState(() { _sessions = sessions; _loading = false; });
  }

  void _openSession(GradingSession session) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a, b) => MainGradingScreen(session: session),
        transitionsBuilder: (context, anim, secondaryAnim, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    _loadSessions();
  }

  Future<void> _deleteSession(GradingSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDeleteDialog(sessionName: session.name),
    );
    if (confirm == true) {
      await _sessionService.deleteSession(session.id);
      if (mounted) _loadSessions();
    }
  }

  void _createNewSession() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ImportFilesDialog(
        onConfirm: (session) async {
          await _sessionService.saveSession(session);
          if (!ctx.mounted) return;
          Navigator.of(ctx).pop();
          _openSession(session);
        },
        sessionService: _sessionService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── Decorative blobs ──
          Positioned(top: -120, right: -80, child: _GlowBlob(color: _kPrimary.withValues(alpha: 0.15), size: 400)),
          Positioned(bottom: -80, left: -60, child: _GlowBlob(color: _kAccent.withValues(alpha: 0.10), size: 320)),

          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: _kPrimary))
                    : _sessions.isEmpty
                        ? _buildEmptyState()
                        : _buildSessionList(),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut),
        child: _NewSessionFab(onTap: _createNewSession),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 28),
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kPrimary, _kAccent],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PMG Grader',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: _kTextPrimary)),
              Text('Hệ thống chấm bài tự động',
                  style: GoogleFonts.inter(fontSize: 13, color: _kTextSecondary)),
            ],
          ),
          const Spacer(),
          if (_sessions.isNotEmpty) ...[
            _StatPill(
              icon: Icons.folder_open_rounded,
              label: '${_sessions.length} phiên',
              color: _kPrimary,
            ),
            const SizedBox(width: 12),
            _StatPill(
              icon: Icons.check_circle_outline_rounded,
              label: '${_sessions.where((s) => s.gradedCount > 0).length} đang dở',
              color: _kAccent,
            ),
          ]
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: _kBorder),
            ),
            child: const Icon(Icons.folder_open_rounded, size: 56, color: _kPrimary),
          ),
          const SizedBox(height: 28),
          Text('Chưa có phiên chấm nào',
              style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w700, color: _kTextPrimary)),
          const SizedBox(height: 10),
          Text('Nhấn nút "Tạo mới" để bắt đầu một phiên chấm bài mới.',
              style: GoogleFonts.inter(fontSize: 14, color: _kTextSecondary)),
          const SizedBox(height: 36),
          _GradientButton(
            onTap: _createNewSession,
            label: '＋  Tạo phiên mới',
          ),
        ],
      ),
    );
  }

  // ── Session list ──────────────────────────────────────────────────────────
  Widget _buildSessionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 16),
          child: Text('Phiên đang chấm dở',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: _kTextPrimary)),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 120),
            itemCount: _sessions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (_, i) => _SessionCard(
              session: _sessions[i],
              onOpen: () => _openSession(_sessions[i]),
              onDelete: () => _deleteSession(_sessions[i]),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Session Card ─────────────────────────────────────────────────────────────
class _SessionCard extends StatefulWidget {
  final GradingSession session;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _SessionCard({required this.session, required this.onOpen, required this.onDelete});

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final progress = s.progress;
    final progressPercent = (progress * 100).round();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _hovered ? _kCard.withValues(alpha: 0.9) : _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? _kPrimary.withValues(alpha: 0.5) : _kBorder,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: _hovered
              ? [BoxShadow(color: _kPrimary.withValues(alpha: 0.08), blurRadius: 20, spreadRadius: 2)]
              : [],
        ),
        child: InkWell(
          onTap: widget.onOpen,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: s.isComplete
                          ? [_kPrimary, _kPrimaryLight]
                          : [_kWarning, _kWarning.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    s.isComplete ? Icons.folder_special_rounded : Icons.folder_outlined,
                    color: Colors.white, size: 26,
                  ),
                ),
                const SizedBox(width: 18),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(s.name,
                                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: _kTextPrimary),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (s.examCode != null) ...[
                            const SizedBox(width: 8),
                            _Tag(label: 'Mã đề ${s.examCode}', color: _kAccent),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 13, color: _kTextSecondary),
                          const SizedBox(width: 4),
                          Text(s.markerName ?? 'Chưa xác định',
                              style: GoogleFonts.inter(fontSize: 12, color: _kTextSecondary)),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time_rounded, size: 13, color: _kTextSecondary),
                          const SizedBox(width: 4),
                          Text(_formatRelative(s.lastModified),
                              style: GoogleFonts.inter(fontSize: 12, color: _kTextSecondary)),
                        ],
                      ),
                      if (s.totalStudents > 0) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: _kBorder,
                                  valueColor: AlwaysStoppedAnimation(
                                    progress >= 1.0 ? _kSuccess : _kPrimary,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('$progressPercent%  (${s.gradedCount}/${s.totalStudents})',
                                style: GoogleFonts.inter(fontSize: 11, color: _kTextSecondary)),
                          ],
                        ),
                      ],
                      // File status chips
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        children: [
                          _FileChip(label: 'Guide', ok: s.gradingGuideDocPath != null),
                          _FileChip(label: 'Mark', ok: s.markInputXlsxPath != null),
                          _FileChip(label: 'Đề', ok: s.examImagePath != null),
                          _FileChip(label: 'Bài nộp', ok: s.studentZipPath != null),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Actions
                Column(
                  children: [
                    _ActionBtn(
                      icon: Icons.play_arrow_rounded,
                      tooltip: 'Mở',
                      color: _kPrimary,
                      onTap: widget.onOpen,
                    ),
                    const SizedBox(height: 8),
                    _ActionBtn(
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Xoá',
                      color: Colors.redAccent,
                      onTap: widget.onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Import Files Dialog ──────────────────────────────────────────────────────
class _ImportFilesDialog extends StatefulWidget {
  final void Function(GradingSession) onConfirm;
  final SessionService sessionService;

  const _ImportFilesDialog({required this.onConfirm, required this.sessionService});

  @override
  State<_ImportFilesDialog> createState() => _ImportFilesDialogState();
}

class _ImportFilesDialogState extends State<_ImportFilesDialog> {
  String? _docPath, _xlsxPath, _pngPath, _zipPath;
  final TextEditingController _nameCtrl = TextEditingController();
  bool _busy = false;

  bool get _canProceed =>
      _docPath != null && _xlsxPath != null && _pngPath != null && _zipPath != null;

  Future<void> _pick(String ext, void Function(String) onPicked) async {
    final r = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [ext],
    );
    if (r != null && r.files.single.path != null) {
      onPicked(r.files.single.path!);
    }
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    final session = widget.sessionService.createNewSession().copyWith(
      name: _nameCtrl.text.trim().isNotEmpty
          ? _nameCtrl.text.trim()
          : null,
      gradingGuideDocPath: _docPath,
      markInputXlsxPath: _xlsxPath,
      examImagePath: _pngPath,
      studentZipPath: _zipPath,
      examCode: _pngPath != null ? _extractExamCode(_pngPath!) : null,
    );
    widget.onConfirm(session);
  }

  String? _extractExamCode(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final match = RegExp(r'(\d+)').firstMatch(name);
    return match?.group(1);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Container(
        width: 560,
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 16))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(28, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kPrimary.withValues(alpha: 0.15), _kAccent.withValues(alpha: 0.08)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.create_new_folder_rounded, color: _kPrimary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tạo phiên chấm mới',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: _kTextPrimary)),
                      Text('Import các file cần thiết để bắt đầu',
                          style: GoogleFonts.inter(fontSize: 12, color: _kTextSecondary)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: _kTextSecondary),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Session name
                  Text('Tên phiên (tuỳ chọn)',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _kTextSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    style: GoogleFonts.inter(color: _kTextPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'VD: Chấm giữa kỳ - SE1857',
                      hintStyle: GoogleFonts.inter(color: _kTextSecondary, fontSize: 14),
                      filled: true,
                      fillColor: _kCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text('Files cần import',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _kTextSecondary)),
                  const SizedBox(height: 12),

                  // File import rows
                  _FileImportRow(
                    icon: Icons.description_outlined,
                    iconColor: const Color(0xFF818CF8),
                    label: 'Grading Guide',
                    hint: 'File .docx hướng dẫn chấm điểm',
                    ext: 'docx',
                    filePath: _docPath,
                    onPick: () => _pick('docx', (p) => setState(() => _docPath = p)),
                  ),
                  const SizedBox(height: 10),
                  _FileImportRow(
                    icon: Icons.table_chart_outlined,
                    iconColor: const Color(0xFF34D399),
                    label: 'Mark Input',
                    hint: 'File .xlsx thông tin người chấm',
                    ext: 'xlsx',
                    filePath: _xlsxPath,
                    onPick: () => _pick('xlsx', (p) => setState(() => _xlsxPath = p)),
                  ),
                  const SizedBox(height: 10),
                  _FileImportRow(
                    icon: Icons.image_outlined,
                    iconColor: const Color(0xFFFBBF24),
                    label: 'Đề thi',
                    hint: 'File .png ảnh mã đề',
                    ext: 'png',
                    filePath: _pngPath,
                    onPick: () => _pick('png', (p) => setState(() => _pngPath = p)),
                  ),
                  const SizedBox(height: 10),
                  _FileImportRow(
                    icon: Icons.folder_zip_outlined,
                    iconColor: const Color(0xFFF472B6),
                    label: 'Bài nộp học sinh',
                    hint: 'File .zip chứa bài làm',
                    ext: 'zip',
                    filePath: _zipPath,
                    onPick: () => _pick('zip', (p) => setState(() => _zipPath = p)),
                  ),

                  const SizedBox(height: 28),

                  // Progress indicator
                  Row(
                    children: [
                      ...[_docPath, _xlsxPath, _pngPath, _zipPath].map(
                        (p) => Expanded(
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: p != null ? _kAccent : _kBorder,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _canProceed
                        ? '✓ Đã chọn đủ 4 files — sẵn sàng bắt đầu!'
                        : '${[_docPath, _xlsxPath, _pngPath, _zipPath].where((p) => p != null).length}/4 files đã chọn',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _canProceed ? _kAccent : _kTextSecondary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kTextSecondary,
                            side: const BorderSide(color: _kBorder),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Huỷ', style: GoogleFonts.inter(fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _canProceed ? 1.0 : 0.4,
                          child: ElevatedButton(
                            onPressed: (_canProceed && !_busy) ? _confirm : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: _busy
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Bắt đầu chấm →', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Confirm Delete Dialog ────────────────────────────────────────────────────
class _ConfirmDeleteDialog extends StatelessWidget {
  final String sessionName;
  const _ConfirmDeleteDialog({required this.sessionName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _kBorder)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
              const SizedBox(width: 8),
              Text('Xoá phiên chấm?', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: _kTextPrimary)),
            ]),
            const SizedBox(height: 12),
            Text('Bạn có chắc muốn xoá "$sessionName"? Hành động này không thể hoàn tác.',
                style: GoogleFonts.inter(fontSize: 13, color: _kTextSecondary)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Huỷ', style: GoogleFonts.inter(color: _kTextSecondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: Text('Xoá', style: GoogleFonts.inter()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable small widgets ───────────────────────────────────────────────────

class _FileImportRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String hint;
  final String ext;
  final String? filePath;
  final VoidCallback onPick;

  const _FileImportRow({
    required this.icon, required this.iconColor, required this.label,
    required this.hint, required this.ext, required this.filePath, required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final picked = filePath != null;
    final filename = picked ? filePath!.split(Platform.pathSeparator).last : null;

    return Container(
      decoration: BoxDecoration(
        color: picked ? _kAccent.withValues(alpha: 0.06) : _kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: picked ? _kAccent.withValues(alpha: 0.4) : _kBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextPrimary)),
                      Text(
                        picked ? filename! : hint,
                        style: GoogleFonts.inter(fontSize: 11, color: picked ? _kAccent : _kTextSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  picked ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                  color: picked ? _kAccent : _kTextSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _FileChip extends StatelessWidget {
  final String label;
  final bool ok;
  const _FileChip({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: ok ? _kSuccess.withValues(alpha: 0.1) : _kBorder.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ok ? Icons.check_rounded : Icons.remove_rounded, size: 10,
              color: ok ? _kSuccess : _kTextSecondary),
          const SizedBox(width: 3),
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: ok ? _kSuccess : _kTextSecondary)),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.tooltip, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _GradientButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_kPrimary, Color(0xFF818CF8)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: _kPrimary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Text(label, style: GoogleFonts.outfit(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _NewSessionFab extends StatelessWidget {
  final VoidCallback onTap;
  const _NewSessionFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_kPrimary, Color(0xFF818CF8)]),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: _kPrimary.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text('Tạo mới', style: GoogleFonts.outfit(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
