import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/file_service.dart';
import '../services/session_service.dart';
import 'main_screen.dart';

const _bg = Color(0xFFF6F8FA);
const _surface = Colors.white;
const _border = Color(0xFFD0D7DE);
const _borderSoft = Color(0xFFEAEFF4);
const _text = Color(0xFF24292F);
const _muted = Color(0xFF57606A);
const _primary = Color(0xFF0969DA);
const _success = Color(0xFF1A7F37);
const _warning = Color(0xFF9A6700);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SessionService _sessionService = SessionService();
  List<GradingSession> _sessions = [];
  bool _loading = true;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await _sessionService.loadSessions();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _loading = false;
      if (_sessions.isEmpty) {
        _selectedIndex = -1;
      } else if (_selectedIndex < 0 || _selectedIndex >= _sessions.length) {
        _selectedIndex = 0;
      }
    });
  }

  Future<void> _openSession(GradingSession session) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MainGradingScreen(session: session)),
    );
    await _loadSessions();
  }

  Future<void> _deleteSession(GradingSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete collection?'),
        content: Text('Delete "${session.name}" from this workspace?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCF222E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _sessionService.deleteSession(session.id);
    await _loadSessions();
  }

  Future<void> _showCreateCollectionDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PrepareCollectionDialog(
        sessionService: _sessionService,
        onConfirm: (session) async {
          await _sessionService.saveSession(session);
          if (!context.mounted) return;
          Navigator.of(context).pop();
          await _openSession(session);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIndex >= 0 && _selectedIndex < _sessions.length
        ? _sessions[_selectedIndex]
        : null;

    return Scaffold(
      backgroundColor: _bg,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : selected == null
                      ? _buildEmptyWorkspace()
                      : _buildSessionPreview(selected),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(right: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF4FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF54AEFF)),
                  ),
                  child: const Icon(
                    Icons.collections_bookmark_outlined,
                    color: _primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PMG Grader',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _text,
                        ),
                      ),
                      Text(
                        'Collections',
                        style: GoogleFonts.inter(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: ElevatedButton.icon(
              onPressed: _showCreateCollectionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create collection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              '${_sessions.length} saved',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _muted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _sessions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      'No collections yet.',
                      style: GoogleFonts.inter(fontSize: 13, color: _muted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
                    itemCount: _sessions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      return _SidebarSessionTile(
                        session: session,
                        selected: index == _selectedIndex,
                        onTap: () => setState(() => _selectedIndex = index),
                        onOpen: () => _openSession(session),
                        onDelete: () => _deleteSession(session),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Text(
            'Collection workspace',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _text,
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _loadSessions,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWorkspace() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open_outlined, size: 56, color: _muted),
            const SizedBox(height: 18),
            Text(
              'Create your first collection',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prepare the grading files, then open the collection workspace to review submissions.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.4,
                color: _muted,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _showCreateCollectionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create collection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionPreview(GradingSession session) {
    final progressPercent = (session.progress * 100).round();
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Last modified ${_formatDate(session.lastModified)}',
                      style: GoogleFonts.inter(fontSize: 13, color: _muted),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openSession(session),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Open collection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricPanel(label: 'Progress', value: '$progressPercent%'),
              _MetricPanel(
                label: 'Reviewed',
                value: '${session.gradedCount}/${session.totalStudents}',
              ),
              _MetricPanel(
                label: 'Marker',
                value: session.markerName?.isNotEmpty == true
                    ? session.markerName!
                    : 'Unset',
              ),
              _MetricPanel(label: 'Exam', value: session.examCode ?? 'Unset'),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: _panelDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preparation files',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 12),
                _fileRow('Rubric grading file', session.gradingGuideDocPath),
                _fileRow('Mark input', session.markInputXlsxPath),
                _fileRow('Exam image', session.examImagePath),
                _fileRow('Submissions zip', session.studentZipPath),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fileRow(String label, String? path) {
    final ok = path != null && path.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 18,
            color: ok ? _success : _muted,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _text,
              ),
            ),
          ),
          Expanded(
            child: Text(
              ok ? _basename(path) : 'Not selected',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: ok ? _muted : _warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _SidebarSessionTile extends StatelessWidget {
  final GradingSession session;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _SidebarSessionTile({
    required this.session,
    required this.selected,
    required this.onTap,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFDDF4FF) : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.folder_outlined,
                size: 20,
                color: selected ? _primary : _muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${session.gradedCount}/${session.totalStudents} reviewed',
                      style: GoogleFonts.inter(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Open',
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new, size: 17),
                color: _muted,
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 17),
                color: const Color(0xFFCF222E),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrepareCollectionDialog extends StatefulWidget {
  final SessionService sessionService;
  final Future<void> Function(GradingSession session) onConfirm;

  const _PrepareCollectionDialog({
    required this.sessionService,
    required this.onConfirm,
  });

  @override
  State<_PrepareCollectionDialog> createState() =>
      _PrepareCollectionDialogState();
}

class _PrepareCollectionDialogState extends State<_PrepareCollectionDialog> {
  final TextEditingController _nameController = TextEditingController();
  String? _guidePath;
  String? _markInputPath;
  String? _examImagePath;
  String? _submissionsZipPath;
  bool _busy = false;

  bool get _canCreate {
    return _guidePath != null &&
        _markInputPath != null &&
        _examImagePath != null &&
        _submissionsZipPath != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pick(
    String extension,
    void Function(String path) onPicked,
  ) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [extension],
    );
    if (result?.files.single.path == null) return;
    setState(() => onPicked(result!.files.single.path!));
  }

  Future<void> _confirm() async {
    if (!_canCreate || _busy) return;
    setState(() => _busy = true);
    try {
      final markerName = await FileService().extractMarkerName(_markInputPath!);
      final session = widget.sessionService.createNewSession().copyWith(
        name: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
        gradingGuideDocPath: _guidePath,
        markInputXlsxPath: _markInputPath,
        examImagePath: _examImagePath,
        studentZipPath: _submissionsZipPath,
        examCode: _examImagePath != null
            ? _basename(_examImagePath!).split('.').first
            : null,
        markerName: markerName,
      );
      await widget.onConfirm(session);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 14, 14),
              child: Row(
                children: [
                  const Icon(Icons.create_new_folder_outlined, color: _primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Prepare grading collection',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collection name',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Example: PMG grading batch 1',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _FilePickRow(
                      icon: Icons.description_outlined,
                      label: 'Rubric grading file',
                      hint: 'Select .docx',
                      path: _guidePath,
                      onTap: () => _pick('docx', (path) => _guidePath = path),
                    ),
                    _FilePickRow(
                      icon: Icons.table_chart_outlined,
                      label: 'Mark input',
                      hint: 'Select .xlsx',
                      path: _markInputPath,
                      onTap: () =>
                          _pick('xlsx', (path) => _markInputPath = path),
                    ),
                    _FilePickRow(
                      icon: Icons.image_outlined,
                      label: 'Exam image',
                      hint: 'Select .png',
                      path: _examImagePath,
                      onTap: () =>
                          _pick('png', (path) => _examImagePath = path),
                    ),
                    _FilePickRow(
                      icon: Icons.folder_zip_outlined,
                      label: 'Submissions',
                      hint: 'Select .zip',
                      path: _submissionsZipPath,
                      onTap: () =>
                          _pick('zip', (path) => _submissionsZipPath = path),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: _border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '${[_guidePath, _markInputPath, _examImagePath, _submissionsZipPath].where((path) => path != null).length}/4 files selected',
                    style: GoogleFonts.inter(fontSize: 13, color: _muted),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _canCreate && !_busy ? _confirm : null,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward),
                    label: const Text('Start grading'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilePickRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final String? path;
  final VoidCallback onTap;

  const _FilePickRow({
    required this.icon,
    required this.label,
    required this.hint,
    required this.path,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = path != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? const Color(0xFFF0FFF4) : _surface,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? const Color(0xFFB4E7C2) : _border,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(icon, color: selected ? _success : _muted),
                const SizedBox(width: 12),
                SizedBox(
                  width: 130,
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    selected ? _basename(path!) : hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: selected ? _muted : _warning,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected ? Icons.check_circle_outline : Icons.upload_file,
                  color: selected ? _success : _muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricPanel extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPanel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _muted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _text,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: _surface,
    border: Border.all(color: _borderSoft),
    borderRadius: BorderRadius.circular(8),
  );
}

String _basename(String path) {
  return path.split(Platform.pathSeparator).last;
}
