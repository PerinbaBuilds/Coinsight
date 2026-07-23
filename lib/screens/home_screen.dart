import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';
import 'advisor_screen.dart';
import 'dashboard_screen.dart';
import 'income_screen.dart';
import 'goals_screen.dart';
import 'insights_screen.dart';
import 'history_screen.dart';
import 'manage_budgets_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openMenu() => _scaffoldKey.currentState?.openEndDrawer();

  late final List<Widget> _screens = [
    DashboardScreen(onMenuTap: _openMenu),
    const IncomeScreen(),
    const GoalsScreen(),
    const AdvisorScreen(),
    const InsightsScreen(),
    const HistoryScreen(),
  ];

  static const _navItems = [
    _NavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _NavItem(
      label: 'Income',
      icon: Icons.trending_up_outlined,
      selectedIcon: Icons.trending_up,
    ),
    _NavItem(
      label: 'Goals',
      icon: Icons.savings_outlined,
      selectedIcon: Icons.savings,
    ),
    _NavItem(
      label: 'Advisor',
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome,
    ),
    _NavItem(
      label: 'Insights',
      icon: Icons.lightbulb_outline,
      selectedIcon: Icons.lightbulb,
    ),
    _NavItem(
      label: 'History',
      icon: Icons.history,
      selectedIcon: Icons.history,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      body: AnimatedSwitcher(
        duration: AppTheme.motionMedium,
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppTheme.motionCurve,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: _FloatingNavBar(
        selectedIndex: _selectedIndex,
        items: _navItems,
        onItemSelected: (i) => setState(() => _selectedIndex = i),
      ),
      endDrawer: _AppDrawer(
        auth: auth,
        onProfileTap: () {
          Navigator.pop(context);
          Navigator.push(
              context, AppTheme.slideRoute(const ProfileScreen()));
        },
        onManageTap: () {
          final finance = context.read<FinanceService>();
          Navigator.pop(context);
          Navigator.push(
              context, AppTheme.slideRoute(const ManageBudgetsScreen()));
          if (finance.isBudgetLocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Budgets are locked — edits open again on the 1st of next month.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }
}

// ── Nav Item Data ────────────────────────────────────────────────────────────
class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _NavItem(
      {required this.label, required this.icon, required this.selectedIcon});
}

// ── Floating Nav Bar ─────────────────────────────────────────────────────────
class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onItemSelected;

  const _FloatingNavBar({
    required this.selectedIndex,
    required this.items,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3D2C), Color(0xFF0C1B12)],
                )
              : null,
          color: Theme.of(context).brightness == Brightness.dark
              ? null
              : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl + 4),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2D5A3D)
                : const Color(0xFFC9E6D4),
            width: 1,
          ),
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.navShadow
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        // Every tab shows its icon and label stacked vertically and shares the
        // width evenly, so all names stay visible, aligned, and uncramped.
        child: Row(
          children: List.generate(items.length, (i) {
            final item = items[i];
            final selected = i == selectedIndex;
            final unselectedColor =
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
            return Expanded(
              child: GestureDetector(
                onTap: () => onItemSelected(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: AppTheme.motionMedium,
                      curve: AppTheme.motionCurve,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.navy.withValues(
                                alpha: isDark ? 0.9 : 1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        selected ? item.selectedIcon : item.icon,
                        color: selected ? Colors.white : unselectedColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.label,
                        maxLines: 1,
                        style: TextStyle(
                          color: selected ? AppTheme.navy : unselectedColor,
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── End Drawer ───────────────────────────────────────────────────────────────
class _AppDrawer extends StatelessWidget {
  final AuthService auth;
  final VoidCallback onProfileTap;
  final VoidCallback onManageTap;

  const _AppDrawer({
    required this.auth,
    required this.onProfileTap,
    required this.onManageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              left: 20,
              right: 20,
              bottom: 28,
            ),
            decoration: BoxDecoration(
              gradient: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.primaryGradient
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF16A34A), Color(0xFF22C55E), Color(0xFF4ADE80)],
                    ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    auth.displayName.isNotEmpty
                        ? auth.displayName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  auth.displayName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17),
                ),
                const SizedBox(height: 2),
                Text(
                  auth.userEmail ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppTheme.navy),
            title: const Text('Profile',
                style: TextStyle(fontWeight: FontWeight.w500)),
            onTap: onProfileTap,
          ),
          ListTile(
            leading: const Icon(Icons.tune_outlined, color: AppTheme.navy),
            title: const Text('Manage Budgets',
                style: TextStyle(fontWeight: FontWeight.w500)),
            onTap: onManageTap,
          ),
        ],
      ),
    );
  }
}
