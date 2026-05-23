import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GraderApp());
}

class GraderApp extends StatelessWidget {
  const GraderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PMG Grader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0969DA),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      ),
      home: const HomeScreen(),
    );
  }
}
