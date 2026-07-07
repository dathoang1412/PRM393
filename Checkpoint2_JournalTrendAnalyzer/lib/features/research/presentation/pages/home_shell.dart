import 'package:flutter/material.dart';

import 'analytics_screen.dart';
import 'insights_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  static const _kDesktopBreak = 800.0;

  Widget _buildScreen() => switch (_selectedIndex) {
        0 => SearchScreen(onSearchSuccess: () => _onSelect(2)),
        1 => const InsightsScreen(),
        2 => const AnalyticsScreen(),
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
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: Text('Search'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Insights'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
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
          border: Border(top: BorderSide(color: Color(0xFFDDE3F5))),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onSelect,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Insights',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
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
