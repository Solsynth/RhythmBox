import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:html/dom.dart' hide Text;
import 'package:rhythm_box/services/sort.dart';
import 'package:spotify/spotify.dart';

import 'package:html/parser.dart' as parser;

import 'dart:async';

import 'package:flutter/material.dart' hide Element;

abstract class ServiceUtils {
  static final _englishMatcherRegex = RegExp(
    "^[a-zA-Z0-9\\s!\"#\$%&\\'()*+,-.\\/:;<=>?@\\[\\]^_`{|}~]*\$",
  );
  static bool onlyContainsEnglish(String text) {
    return _englishMatcherRegex.hasMatch(text);
  }

  static String clearArtistsOfTitle(String title, List<String> artists) {
    return title
        .replaceAll(RegExp(artists.join('|'), caseSensitive: false), '')
        .trim();
  }

  static String getTitle(
    String title, {
    List<String> artists = const [],
    bool onlyCleanArtist = false,
  }) {
    final match = RegExp(r'(?<=\().+?(?=\))').firstMatch(title)?.group(0);
    final artistInBracket =
        artists.any((artist) => match?.contains(artist) ?? false);

    if (artistInBracket) {
      title = title.replaceAll(
        RegExp(' *\\([^)]*\\) *'),
        '',
      );
    }

    title = clearArtistsOfTitle(title, artists);
    if (onlyCleanArtist) {
      artists = [];
    }

    return "$title ${artists.map((e) => e.replaceAll(",", " ")).join(", ")}"
        .toLowerCase()
        .replaceAll(RegExp(r'\s*\[[^\]]*]'), ' ')
        .replaceAll(RegExp(r'\sfeat\.|\sft\.'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Future<String?> extractLyrics(Uri url) async {
    final client = GetConnect();
    final response = await client.get(url.toString());

    Document document = parser.parse(response.body);
    String? lyrics = document.querySelector('div.lyrics')?.text.trim();
    if (lyrics == null) {
      lyrics = '';
      document
          .querySelectorAll('div[class^="Lyrics__Container"]')
          .forEach((element) {
        if (element.text.trim().isNotEmpty) {
          final snippet = element.innerHtml.replaceAll('<br>', '\n').replaceAll(
                RegExp('<(?!\\s*br\\s*\\/?)[^>]+>', caseSensitive: false),
                '',
              );
          final el = document.createElement('textarea');
          el.innerHtml = snippet;
          lyrics = '$lyrics${el.text.trim()}\n\n';
        }
      });
    }

    return lyrics;
  }

  static void navigate(BuildContext context, String location, {Object? extra}) {
    if (GoRouterState.of(context).matchedLocation == location) return;
    GoRouter.of(context).go(location, extra: extra);
  }

  static void navigateNamed(
    BuildContext context,
    String name, {
    Object? extra,
    Map<String, String>? pathParameters,
    Map<String, dynamic>? queryParameters,
  }) {
    if (GoRouterState.of(context).matchedLocation == name) return;
    GoRouter.of(context).goNamed(
      name,
      pathParameters: pathParameters ?? const {},
      queryParameters: queryParameters ?? const {},
      extra: extra,
    );
  }

  static void push(BuildContext context, String location, {Object? extra}) {
    final router = GoRouter.of(context);
    final routerState = GoRouterState.of(context);
    final routerStack = router.routerDelegate.currentConfiguration.matches
        .map((e) => e.matchedLocation);

    if (routerState.matchedLocation == location ||
        routerStack.contains(location)) return;
    router.push(location, extra: extra);
  }

  static void pushNamed(
    BuildContext context,
    String name, {
    Object? extra,
    Map<String, String> pathParameters = const {},
    Map<String, String> queryParameters = const {},
  }) {
    final router = GoRouter.of(context);
    final routerState = GoRouterState.of(context);
    final routerStack = router.routerDelegate.currentConfiguration.matches
        .map((e) => e.matchedLocation);

    final nameLocation = routerState.namedLocation(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
    );

    if (routerState.matchedLocation == nameLocation ||
        routerStack.contains(nameLocation)) {
      return;
    }
    router.pushNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  static DateTime parseSpotifyAlbumDate(AlbumSimple? album) {
    if (album == null || album.releaseDate == null) {
      return DateTime.parse('1975-01-01');
    }

    switch (album.releaseDatePrecision ?? DatePrecision.year) {
      case DatePrecision.day:
        return DateTime.parse(album.releaseDate!);
      case DatePrecision.month:
        return DateTime.parse('${album.releaseDate}-01');
      case DatePrecision.year:
        return DateTime.parse('${album.releaseDate}-01-01');
    }
  }

  static List<T> sortTracks<T extends Track>(List<T> tracks, SortBy sortBy) {
    if (sortBy == SortBy.none) return tracks;
    return List<T>.from(tracks)
      ..sort((a, b) {
        switch (sortBy) {
          case SortBy.ascending:
            return a.name?.compareTo(b.name ?? '') ?? 0;
          case SortBy.descending:
            return b.name?.compareTo(a.name ?? '') ?? 0;
          case SortBy.newest:
            final aDate = parseSpotifyAlbumDate(a.album);
            final bDate = parseSpotifyAlbumDate(b.album);
            return bDate.compareTo(aDate);
          case SortBy.oldest:
            final aDate = parseSpotifyAlbumDate(a.album);
            final bDate = parseSpotifyAlbumDate(b.album);
            return aDate.compareTo(bDate);
          case SortBy.duration:
            return a.durationMs?.compareTo(b.durationMs ?? 0) ?? 0;
          case SortBy.artist:
            return a.artists?.first.name
                    ?.compareTo(b.artists?.first.name ?? '') ??
                0;
          case SortBy.album:
            return a.album?.name?.compareTo(b.album?.name ?? '') ?? 0;
          default:
            return 0;
        }
      });
  }
}
