import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/research/presentation/pages/home_shell.dart';

class JournexaApp extends StatelessWidget {
  const JournexaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journexa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeShell(),
    );
  }
}
