import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:journexa/core/theme/app_colors.dart';
import '../providers/research_provider.dart';
import 'analytics_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'trends_hub_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  static const _kDesktopBreak = 800.0;

  Widget _buildScreen() => switch (_selectedIndex) {
        0 => HomeScreen(
            onOpenResearch: () => _onSelect(1),
            onOpenTrends: () => _onSelect(2),
            onOpenRankings: _openRankings,
            onSearchTopic: _searchFromHome,
          ),
        1 => SearchScreen(
            onViewDashboard: () => _onSelect(2),
            onOpenRankings: () => _openRankings(0),
          ),
        2 => TrendsHubScreen(
            onChangeTopic: () => _onSelect(1),
            onOpenRankings: () => _openRankings(0),
          ),
        _ => const ProfileScreen(),
      };

  void _onSelect(int index) => setState(() => _selectedIndex = index);

  /// Kicks off a live search for a trending topic, then lands the user on
  /// the Research tab where the loading state and results appear.
  void _searchFromHome(String topic) {
    context.read<ResearchProvider>().search(topic);
    _onSelect(1);
  }

  /// Rankings is not a nav destination — it opens as a pushed route (with a
  /// back button), keeping the bottom bar to the four main pages.
  /// [initialTab] deep-links to a specific ranking (0 Journals, 1 Authors, …).
  void _openRankings(int initialTab) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalyticsScreen(
          initialTab: initialTab,
          onChangeTopic: () {
            Navigator.of(context).pop();
            _onSelect(1);
          },
        ),
      ),
    );
  }

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
                icon: Icon(Icons.travel_explore_outlined),
                selectedIcon: Icon(Icons.travel_explore),
                label: Text('Research'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.show_chart_outlined),
                selectedIcon: Icon(Icons.show_chart),
                label: Text('Trends'),
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
              icon: Icon(Icons.travel_explore_outlined),
              selectedIcon: Icon(Icons.travel_explore),
              label: 'Research',
            ),
            NavigationDestination(
              icon: Icon(Icons.show_chart_outlined),
              selectedIcon: Icon(Icons.show_chart),
              label: 'Trends',
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
