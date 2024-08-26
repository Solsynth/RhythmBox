import 'package:go_router/go_router.dart';
import 'package:rhythm_box/screens/explore.dart';
import 'package:rhythm_box/screens/settings.dart';
import 'package:rhythm_box/shells/nav_shell.dart';

final router = GoRouter(routes: [
  ShellRoute(
    builder: (context, state, child) => NavShell(child: child),
    routes: [
      GoRoute(
        path: "/",
        name: "explore",
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: "/settings",
        name: "settings",
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  ),
]);
