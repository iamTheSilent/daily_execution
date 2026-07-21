import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/inbox/inbox_screen.dart';
import '../../features/plans/plans_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/today/today_screen.dart';
import '../../providers/app_providers.dart';
import '../theme/app_colors.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/today',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _MainScaffold(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/plans', builder: (_, __) => const PlansScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/calendar', builder: (_, __) => const CalendarScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/today', builder: (_, __) => const TodayScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/inbox', builder: (_, __) => const InboxScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/settings', builder: (_, __) => const SettingsScreen()),
          ]),
        ],
      ),
    ],
  );
});

class _MainScaffold extends ConsumerWidget {
  const _MainScaffold({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badge = ref.watch(planBadgeProvider).valueOrNull ?? 0;
    final s = ref.watch(appStringsProvider);
    final current = shell.currentIndex;
    // Keep the reminder server in sync while the app is open.
    ref.watch(autoSyncProvider);

    return Scaffold(
      body: shell,
      bottomNavigationBar: _BottomBar(
        currentIndex: current,
        badge: badge,
        labels: [
          s.navPlans,
          s.navCalendar,
          s.navToday,
          s.navInbox,
          s.navSettings,
        ],
        onTap: (i) => shell.goBranch(i, initialLocation: i == current),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentIndex,
    required this.badge,
    required this.labels,
    required this.onTap,
  });

  final int currentIndex;
  final int badge;
  final List<String> labels;
  final ValueChanged<int> onTap;

  static const _icons = [
    Icons.menu_book_outlined,      // Plans
    Icons.calendar_today_outlined, // Calendar
    Icons.menu,                    // Today (مرکز)
    Icons.insights_outlined,       // Stats
    Icons.settings_outlined,       // Settings
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      padding: EdgeInsets.only(
        top: 6,
        bottom: 6 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(5, (i) {
          if (i == 2) {
            return _CenterButton(
              label: labels[i],
              active: currentIndex == 2,
              onTap: () => onTap(2),
            );
          }
          return _NavItem(
            icon: _icons[i],
            label: labels[i],
            active: currentIndex == i,
            badge: i == 0 ? badge : 0,
            onTap: () => onTap(i),
          );
        }),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.textSecondary;
    final iconWidget = Icon(icon, color: color, size: 24);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            badge > 0
                ? Badge(
                    label: Text('$badge'),
                    backgroundColor: AppColors.red,
                    child: iconWidget,
                  )
                : iconWidget,
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final circleColor = active ? AppColors.accent : AppColors.dark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -14),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: circleColor.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.menu, color: Colors.white, size: 26),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -10),
            child: Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: active ? AppColors.accent : AppColors.textSecondary,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
          ),
        ],
      ),
    );
  }
}