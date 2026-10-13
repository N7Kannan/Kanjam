import 'package:flutter/material.dart';

import '../goals/goal_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/monthly_report_screen.dart';
import '../transactions/transactions_screen.dart';
import 'home_screen.dart';

/// Bottom-navigation container: Home, Transactions, Reports, Goals, Profile.
/// Tabs are built the first time they are opened and then kept alive, so
/// filters and scroll positions survive switching tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  static const int tabHome = 0;
  static const int tabTransactions = 1;
  static const int tabReports = 2;
  static const int tabGoals = 3;
  static const int tabProfile = 4;

  int _index = tabHome;
  final List<bool> _visited = <bool>[true, false, false, false, false];

  void _select(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      _visited[index] = true;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A new day or month may have started while the app was in the background.
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  Widget _tab(int i) {
    if (!_visited[i]) return const SizedBox.shrink();
    switch (i) {
      case tabHome:
        return HomeTab(onSelectTab: _select);
      case tabTransactions:
        return const TransactionsScreen();
      case tabReports:
        return const MonthlyReportScreen();
      case tabGoals:
        return const GoalScreen();
      case tabProfile:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back on any other tab returns to Home; back on Home leaves the app.
      canPop: _index == tabHome,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _select(tabHome);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: List<Widget>.generate(5, _tab),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: _select,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.flag_outlined),
              activeIcon: Icon(Icons.flag),
              label: 'Goals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
