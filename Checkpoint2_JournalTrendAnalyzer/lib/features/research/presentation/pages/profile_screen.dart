import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:journexa/core/firebase/analytics_service.dart';
import 'package:journexa/core/firebase/firebase_bootstrap.dart';
import 'package:journexa/core/firebase/remote_config_service.dart';
import 'package:journexa/core/firebase/storage_service.dart';
import 'package:journexa/core/theme/app_colors.dart';
import 'package:journexa/core/utils/app_feedback.dart';
import 'package:journexa/core/utils/pdf_report.dart';
import 'package:journexa/core/widgets/section_card.dart';
import 'package:journexa/features/research/domain/usecases/analytics_calculator.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/notifications_viewmodel.dart';
import '../viewmodels/research_viewmodel.dart';

/// Profile tab (spec 4.8): account info + sign-out, FCM Notification
/// Center, PDF report export → Firebase Storage, Remote Config demo, and
/// Crashlytics demo.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _exporting = false;
  String? _uploadedUrl;
  String? _localPath;
  String? _exportError;

  Future<void> _exportPdf() async {
    final vm = context.read<ResearchViewModel>();
    if (vm.publications.isEmpty) {
      showSuccessSnackBar(context, 'Search a topic first to export a report.');
      return;
    }

    setState(() {
      _exporting = true;
      _exportError = null;
      _uploadedUrl = null;
      _localPath = null;
    });

    try {
      final filtered = vm.filteredPublications;
      final summary = vm.summary;
      final fmt = NumberFormat.decimalPattern();
      final byCount = [...vm.trends]
        ..sort((a, b) => b.count.compareTo(a.count));

      final file = await buildDashboardReportPdf(
        topic: vm.keyword,
        stats: [
          (label: 'Total publications', value: fmt.format(vm.totalWorksInRange)),
          (
            label: 'Average citations',
            value: summary.averageCitations.toStringAsFixed(1)
          ),
          (
            label: 'Most active year',
            value: byCount.isNotEmpty ? '${byCount.first.year}' : 'N/A'
          ),
          (label: 'Top author', value: summary.topAuthor?.name ?? 'N/A'),
          (label: 'Top journal', value: summary.topJournal?.name ?? 'N/A'),
          (
            label: 'Most influential paper',
            value: summary.mostInfluentialPaper?.title ?? 'N/A'
          ),
        ],
        topJournals: AnalyticsCalculator.topJournals(filtered)
            .take(10)
            .map((j) => (name: j.name, detail: '${j.publicationCount} papers'))
            .toList(),
        topAuthors: AnalyticsCalculator.topAuthors(filtered)
            .take(10)
            .map((a) => (name: a.name, detail: '${a.publicationCount} papers'))
            .toList(),
      );

      // The PDF itself is always generated locally. Uploading requires the
      // Storage bucket to be provisioned (Blaze plan) — when that hasn't
      // been done yet, fall back to a local-only save instead of failing
      // the whole export.
      String? url;
      try {
        url = await const StorageService().uploadReport(file, vm.keyword);
      } catch (_) {
        url = null;
      }
      await AnalyticsService.instance.logExportPdf(vm.keyword);

      if (!mounted) return;
      if (url != null) {
        setState(() => _uploadedUrl = url);
        showSuccessSnackBar(context, 'Report uploaded to Firebase Storage');
      } else {
        setState(() => _localPath = file.path);
        showSuccessSnackBar(context,
            'Report saved locally (enable Firebase Storage to auto-upload)');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _exportError = '$e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _throwHandledException() {
    try {
      throw StateError('Journexa handled-exception demo (Crashlytics)');
    } catch (e, stack) {
      if (FirebaseBootstrap.isAvailable) {
        FirebaseCrashlytics.instance
            .recordError(e, stack, reason: 'Crashlytics demo', fatal: false);
        showSuccessSnackBar(
            context, 'Handled exception recorded to Crashlytics');
      } else {
        showSuccessSnackBar(
            context, 'Firebase not configured — exception logged locally');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final notifications = context.watch<NotificationsViewModel>();
    final remoteConfig = context.watch<RemoteConfigService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _UserCard(auth: auth),
                  const SizedBox(height: 14),

                  // ── Notification Center ────────────────────────────────
                  SectionCard(
                    icon: Icons.notifications_outlined,
                    iconColor: AppColors.seriesAuthors,
                    title: 'Notification Center',
                    subtitle: 'Push messages received via FCM',
                    child: notifications.isEmpty
                        ? Text(
                            'No notifications yet. Send a test message from '
                            'Firebase Console → Messaging while the app is '
                            'in the foreground.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: AppColors.inkSecondary,
                                    height: 1.5),
                          )
                        : Column(
                            children: [
                              for (final n in notifications.items)
                                ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                      Icons.circle_notifications_outlined,
                                      color: AppColors.seriesAuthors),
                                  title: Text(n.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text(n.body),
                                  trailing: Text(
                                    DateFormat.Hm().format(n.receivedAt),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                            color: AppColors.inkMuted),
                                  ),
                                ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: notifications.clear,
                                  child: const Text('Clear'),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 14),

                  // ── Report Export ──────────────────────────────────────
                  SectionCard(
                    icon: Icons.picture_as_pdf_outlined,
                    iconColor: AppColors.seriesPapers,
                    title: 'Report Export',
                    subtitle:
                        'Export dashboard analytics as PDF → Firebase Storage',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          key: const Key('exportPdfButton'),
                          onPressed: _exporting ? null : _exportPdf,
                          icon: _exporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.upload_file, size: 18),
                          label: Text(_exporting
                              ? 'Exporting & uploading…'
                              : 'Export PDF report'),
                        ),
                        if (_uploadedUrl != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            key: const Key('uploadedUrlBox'),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryWash,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: AppColors.primaryBorder),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    _uploadedUrl!,
                                    maxLines: 2,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.primaryDark),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Copy URL',
                                  icon: const Icon(Icons.copy, size: 16),
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: _uploadedUrl!));
                                    showSuccessSnackBar(
                                        context, 'URL copied');
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_localPath != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            key: const Key('localPathBox'),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.wash,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 16, color: AppColors.inkSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Saved locally (Storage not enabled)',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.ink),
                                      ),
                                      const SizedBox(height: 2),
                                      SelectableText(
                                        _localPath!,
                                        maxLines: 2,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color:
                                                    AppColors.inkSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_exportError != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _exportError!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.danger),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Remote Config demo ─────────────────────────────────
                  SectionCard(
                    icon: Icons.tune,
                    iconColor: AppColors.seriesCountries,
                    title: 'Remote Config',
                    subtitle: remoteConfig.fetched
                        ? 'Values fetched from Firebase'
                        : 'Defaults (Firebase not configured / not fetched)',
                    child: Column(
                      children: [
                        _ConfigRow(
                          key: const Key('remoteConfigMaxJournals'),
                          name: 'max_journals',
                          value: '${remoteConfig.maxJournals}',
                          description: 'Journals shown in rankings',
                        ),
                        _ConfigRow(
                          key: const Key('remoteConfigMaxKeywords'),
                          name: 'max_keywords',
                          value: '${remoteConfig.maxKeywords}',
                          description: 'Keywords shown in rankings',
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            key: const Key('remoteConfigRefreshButton'),
                            onPressed: () =>
                                context.read<RemoteConfigService>().refresh(),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Refresh'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Crashlytics demo ───────────────────────────────────
                  SectionCard(
                    icon: Icons.bug_report_outlined,
                    iconColor: AppColors.danger,
                    title: 'Crashlytics',
                    subtitle: 'Generate test errors for crash monitoring',
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('handledExceptionButton'),
                            onPressed: _throwHandledException,
                            child: const Text('Handled exception'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('forceCrashButton'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side:
                                  const BorderSide(color: AppColors.danger),
                            ),
                            onPressed: () {
                              if (FirebaseBootstrap.isAvailable) {
                                FirebaseCrashlytics.instance.crash();
                              } else {
                                showSuccessSnackBar(context,
                                    'Firebase not configured — crash skipped');
                              }
                            },
                            child: const Text('Force test crash'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Journexa · PRM393 Lab 03 · OpenAlex + Firebase',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── User info card (spec 4.8) ─────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  const _UserCard({required this.auth});

  final AuthViewModel auth;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryWash,
              backgroundImage:
                  auth.photoUrl != null ? NetworkImage(auth.photoUrl!) : null,
              child: auth.photoUrl == null
                  ? const Icon(Icons.person_outline,
                      size: 28, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.displayName,
                    key: const Key('profileDisplayName'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    auth.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.inkSecondary,
                        ),
                  ),
                  if (auth.isGuest)
                    Text(
                      'Guest mode — sign in after configuring Firebase',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.accent,
                          ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              key: const Key('signOutButton'),
              onPressed: () => context.read<AuthViewModel>().signOut(),
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Sign out'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({
    required this.name,
    required this.value,
    required this.description,
    super.key,
  });

  final String name;
  final String value;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        fontFamily: 'monospace',
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryWash,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Text(
              value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
