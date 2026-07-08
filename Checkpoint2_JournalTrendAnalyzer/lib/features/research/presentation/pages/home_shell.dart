import 'package:flutter/material.dart';

import 'package:journexa/core/theme/app_colors.dart';
import 'home_screen.dart';
import 'journals_screen.dart';
import 'keywords_screen.dart';
import 'profile_screen.dart';

/// Main shell (Lab 03 spec §3): bottom navigation with Home, Journals,
/// Keywords, and Profile.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  static const _kDesktopBreak = 800.0;

  Widget _buildScreen() => switch (_selectedIndex) {
        0 => const HomeScreen(),
        1 => JournalsScreen(onSearchTopic: () => _onSelect(0)),
        2 => KeywordsScreen(onSearchTopic: () => _onSelect(0)),
        _ => const ProfileScreen(),
      };

  void _onSelect(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return constraints.maxWidth >= _kDesktopBreak
            ? _buildDesktop(context)
            : _buildMobile(context);
      },
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onSelect,
            minWidth: 80,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_stories,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: Text('Journals'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.label_outline),
                selectedIcon: Icon(Icons.label),
                label: Text('Keywords'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Profile'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: _buildScreen()),
        ],
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildScreen()),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onSelect,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Journals',
            ),
            NavigationDestination(
              icon: Icon(Icons.label_outline),
              selectedIcon: Icon(Icons.label),
              label: 'Keywords',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
