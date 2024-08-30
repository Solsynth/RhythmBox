import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_box/screens/about.dart';
import 'package:rhythm_box/screens/album/view.dart';
import 'package:rhythm_box/screens/auth/mobile_login.dart';
import 'package:rhythm_box/screens/explore.dart';
import 'package:rhythm_box/screens/library/view.dart';
import 'package:rhythm_box/screens/player/lyrics.dart';
import 'package:rhythm_box/screens/player/mini.dart';
import 'package:rhythm_box/screens/player/view.dart';
import 'package:rhythm_box/screens/playlist/view.dart';
import 'package:rhythm_box/screens/search/view.dart';
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
        path: '/library',
        name: 'library',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/playlist/:id',
        name: 'playlistView',
        builder: (context, state) => PlaylistViewScreen(
          playlistId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/albums/:id',
        name: 'albumView',
        builder: (context, state) => AlbumViewScreen(
          albumId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  ),
  ShellRoute(
    pageBuilder: (context, state, child) => CustomTransitionPage(
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeThroughTransition(
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
    ),
    routes: [
      GoRoute(
        path: '/player',
        name: 'player',
        builder: (context, state) => const PlayerScreen(),
      ),
      GoRoute(
        path: '/player/lyrics',
        name: 'playerLyrics',
        builder: (context, state) => const LyricsScreen(),
      ),
    ],
  ),
  ShellRoute(
    builder: (context, state, child) => child,
    routes: [
      GoRoute(
        path: '/player/mini',
        name: 'playerMini',
        builder: (context, state) => MiniPlayerScreen(
          prevSize: state.extra as Size,
        ),
      ),
    ],
  ),
  ShellRoute(
    builder: (context, state, child) => child,
    routes: [
      GoRoute(
        path: '/auth/mobile-login',
        name: 'authMobileLogin',
        builder: (context, state) => const MobileLogin(),
      ),
    ],
  ),
]);
