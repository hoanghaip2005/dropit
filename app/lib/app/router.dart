import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth.dart';
import '../core/invite_navigation.dart';
import '../core/providers.dart';
import '../core/widgets.dart';
import '../features/achievements/achievements_screen.dart';
import '../features/appeals/appeal_screens.dart';
import '../features/auth/auth_screens.dart';
import '../features/auth/registration_screen.dart';
import '../features/history/history_screen.dart';
import '../features/journal/journal_screens.dart';
import '../features/reports/report_screens.dart';
import '../features/groups/group_screens.dart';
import '../features/groups/membership_screens.dart';
import '../features/profile/my_data_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screens.dart';
import '../features/shop/shop_screen.dart';
import '../features/session/result_screen.dart';
import '../features/session/session_screen.dart';

/// Chuyển AuthState thành Listenable cho go_router.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthListenable(ref);
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: listenable,
    redirect: (context, state) {
      final a = ref.read(authProvider);
      final loc = state.matchedLocation;
      final next = loc.startsWith('/consent/')
          ? safeInviteReturn(loc)
          : safeInviteReturn(state.uri.queryParameters['next']);
      if (!a.onboarded && loc != '/welcome' && loc != '/register') {
        return authRouteWithInvite('/welcome', next);
      }
      if (a.onboarded && !a.loggedIn && loc != '/login' && loc != '/register') {
        return authRouteWithInvite('/login', next);
      }
      if (a.loggedIn && (loc == '/login' || loc == '/welcome')) return next ?? '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegistrationScreen()),
      ShellRoute(
        builder: (context, state, child) =>
            _NavShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/groups', builder: (_, _) => const GroupsScreen()),
          GoRoute(path: '/shop', builder: (_, _) => const ShopScreen()),
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          GoRoute(
            path: '/owner/schedule',
            builder: (_, _) => const OwnerScheduleHubScreen(),
          ),
          GoRoute(
            path: '/owner/reports',
            builder: (_, _) => const OwnerReportsHubScreen(),
          ),
        ],
      ),
      GoRoute(path: '/shop/mine', builder: (_, _) => const InventoryScreen()),
      GoRoute(
        path: '/shop/item/:id',
        builder: (_, s) => ShopItemScreen(itemId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/achievements',
        builder: (_, _) => const AchievementsScreen(),
      ),
      GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
      GoRoute(
        path: '/history/:sid',
        builder: (_, s) => ResultScreen(
          sessionId: s.pathParameters['sid']!,
          fromHistory: true,
        ),
      ),
      GoRoute(path: '/journal', builder: (_, _) => const JournalScreen()),
      GoRoute(
        path: '/journal/:date',
        builder: (_, s) => JournalEditScreen(date: s.pathParameters['date']!),
      ),
      GoRoute(
        path: '/explanation/:sid',
        builder: (_, s) =>
            ExplanationScreen(sessionId: s.pathParameters['sid']!),
      ),
      GoRoute(
        path: '/appeal/new/:sid',
        builder: (_, s) =>
            AppealCreateScreen(sessionId: s.pathParameters['sid']!),
      ),
      GoRoute(
        path: '/appeals/:id',
        builder: (_, s) => OwnerAppealScreen(appealId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/owner/sessions/:sid/explanations',
        builder: (_, s) =>
            OwnerExplanationsScreen(sessionId: s.pathParameters['sid']!),
      ),
      GoRoute(
        path: '/reports/:gid',
        builder: (_, s) => ReportScreen(groupId: s.pathParameters['gid']!),
      ),
      GoRoute(
        path: '/reports/:gid/:month/members/:uid',
        builder: (_, s) => OwnerMemberReportScreen(
          groupId: s.pathParameters['gid']!,
          month: s.pathParameters['month']!,
          userId: s.pathParameters['uid']!,
        ),
      ),
      GoRoute(
        path: '/groups/new',
        builder: (_, _) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/groups/:gid',
        builder: (_, s) => GroupDetailScreen(groupId: s.pathParameters['gid']!),
      ),
      GoRoute(
        path: '/groups/:gid/invite',
        builder: (_, s) => InviteScreen(groupId: s.pathParameters['gid']!),
      ),
      GoRoute(
        path: '/groups/:gid/schedule',
        builder: (_, s) => ScheduleScreen(groupId: s.pathParameters['gid']!),
      ),
      GoRoute(path: '/join', builder: (_, _) => const JoinScreen()),
      GoRoute(
        path: '/consent/:code',
        builder: (_, s) => ConsentScreen(code: s.pathParameters['code']!),
      ),
      GoRoute(
        path: '/owner/sessions/:sid',
        builder: (_, s) =>
            OwnerSessionDetailScreen(sessionId: s.pathParameters['sid']!),
      ),
      GoRoute(
        path: '/session/:sid',
        builder: (_, s) => SessionScreen(sessionId: s.pathParameters['sid']!),
      ),
      GoRoute(
        path: '/session/:sid/result',
        builder: (_, s) => ResultScreen(sessionId: s.pathParameters['sid']!),
      ),
      GoRoute(path: '/coins', builder: (_, _) => const CoinsScreen()),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(path: '/profile/edit', redirect: (_, _) => '/profile'),
      GoRoute(
        path: '/owner/sessions/:sid/edit',
        builder: (_, s) =>
            EditSessionScreen(sessionId: s.pathParameters['sid']!),
      ),
      GoRoute(
        path: '/users/:uid',
        builder: (_, s) =>
            PublicProfileScreen(userId: s.pathParameters['uid']!),
      ),
      GoRoute(path: '/my-data', builder: (_, _) => const MyDataScreen()),
      GoRoute(path: '/leave-group', redirect: (_, _) => '/groups'),
      GoRoute(
        path: '/leave-group/:gid',
        builder: (_, s) => LeaveGroupScreen(groupId: s.pathParameters['gid']!),
      ),
    ],
  );
});

/// Hai bộ thanh điều hướng theo mockup:
/// - Thành viên (trắng, `employee_home_dashboard`/`the_shop`): Trang chủ · Nhóm · Shop · Hồ sơ.
/// - Chỉ là chủ nhóm (đen, `manager_dashboard`): Nhóm · Lịch · Báo cáo · Hồ sơ — không Shop/Coins (BR-53).
class _NavShell extends ConsumerWidget {
  const _NavShell({required this.location, required this.child});
  final String location;
  final Widget child;

  static const memberTabs = [
    NavItem(
      path: '/home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Trang chủ',
    ),
    NavItem(
      path: '/groups',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups,
      label: 'Nhóm',
    ),
    NavItem(
      path: '/shop',
      icon: Icons.local_mall_outlined,
      activeIcon: Icons.local_mall,
      label: 'Shop',
    ),
    NavItem(
      path: '/profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Hồ sơ',
    ),
  ];
  static const ownerTabs = [
    NavItem(
      path: '/groups',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups,
      label: 'Nhóm',
    ),
    NavItem(
      path: '/owner/schedule',
      icon: Icons.event_outlined,
      activeIcon: Icons.event,
      label: 'Lịch',
    ),
    NavItem(
      path: '/owner/reports',
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Báo cáo',
    ),
    NavItem(
      path: '/profile',
      icon: Icons.account_circle_outlined,
      activeIcon: Icons.account_circle,
      label: 'Hồ sơ',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(ownerOnlyProvider) ?? false;
    final tabs = owner ? ownerTabs : memberTabs;
    // Chủ nhóm không có Trang chủ thành viên / Shop → về tab Nhóm.
    if (owner && (location == '/home' || location == '/shop')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) GoRouter.of(context).go('/groups');
      });
    }
    final idx = tabs.indexWhere((t) => location.startsWith(t.path));
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: AppBottomNav(
        light: !owner,
        items: tabs,
        currentIndex: idx < 0 ? 0 : idx,
        onTap: (i) => context.go(tabs[i].path),
      ),
    );
  }
}
