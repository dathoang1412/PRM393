import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:journexa/core/theme/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Login gate: Google Sign-In via Firebase Authentication. When Firebase is
/// not configured yet, a guest-mode entry keeps the app usable in dev.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Brand mark ─────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.auto_stories,
                          color: Colors.white, size: 36),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'JOURNEXA',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fraunces(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Journal Trend Analyzer & Bibliometrics',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fraunces(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── Google Sign-In ─────────────────────────────────────
                  ElevatedButton.icon(
                    key: const Key('googleSignInButton'),
                    onPressed: auth.status == AuthStatus.signingIn
                        ? null
                        : () =>
                            context.read<AuthViewModel>().signInWithGoogle(),
                    icon: auth.status == AuthStatus.signingIn
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.login, size: 18),
                    label: Text(auth.status == AuthStatus.signingIn
                        ? 'Signing in…'
                        : 'Sign in with Google'),
                  ),

                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        auth.errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.danger,
                              height: 1.45,
                            ),
                      ),
                    ),
                  ],

                  // ── Guest mode ──────────────────────────────────────────
                  // Always available as a dev/testing escape hatch — the
                  // Google provider can be enabled in Firebase but still
                  // fail locally (missing SHA-1, provider not enabled yet),
                  // which would otherwise strand the user on this screen.
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.wash,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      auth.firebaseAvailable
                          ? 'Sign-in gặp lỗi? Kiểm tra đã bật Google '
                              'provider + thêm SHA-1 chưa (xem '
                              'FIREBASE_SETUP.md mục 2). Trong lúc đó bạn '
                              'có thể dùng chế độ khách.'
                          : 'Firebase chưa được cấu hình — chạy `flutterfire '
                              'configure` theo FIREBASE_SETUP.md để bật Google '
                              'Sign-In. Trong lúc đó bạn có thể dùng chế độ khách.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.inkSecondary,
                            height: 1.5,
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: const Key('continueAsGuestButton'),
                    onPressed: () =>
                        context.read<AuthViewModel>().continueAsGuest(),
                    icon: const Icon(Icons.person_outline, size: 18),
                    label: const Text('Continue as guest'),
                  ),

                  const SizedBox(height: 28),
                  Text(
                    'Powered by OpenAlex open data · PRM393 Lab 03',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
