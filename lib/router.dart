import 'package:go_router/go_router.dart';
import 'package:rhythm_box/screens/explore.dart';
import 'package:rhythm_box/screens/playlist/view.dart';
import 'package:rhythm_box/screens/settings.dart';
import 'package:rhythm_box/shells/nav_shell.dart';

final router = GoRouter(routes: [
  ShellRoute(
    builder: (context, state, child) => NavShell(child: child),
    routes: [
      GoRoute(
        path: '/',
        name: 'explore',
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: '/playlist/:id',
        name: 'playlistView',
        builder: (context, state) => PlaylistViewScreen(
          playlistId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  ),
]);
