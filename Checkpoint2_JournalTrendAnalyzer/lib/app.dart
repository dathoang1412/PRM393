import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/research/presentation/pages/home_shell.dart';
import 'features/research/presentation/pages/login_screen.dart';
import 'features/research/presentation/viewmodels/auth_viewmodel.dart';

class JournexaApp extends StatelessWidget {
  const JournexaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journexa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AuthGate(),
    );
  }
}

/// Shows the main shell only for an authenticated (or guest-mode) user;
/// otherwise the Google Sign-In screen.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return auth.isAuthenticated ? const HomeShell() : const LoginScreen();
  }
}
