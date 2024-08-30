import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:get/get.dart';
import 'package:lrc/lrc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rhythm_box/providers/database.dart';
import 'package:rhythm_box/providers/spotify.dart';
import 'package:rhythm_box/services/database/database.dart';
import 'package:rhythm_box/services/lyrics/model.dart';
import 'package:spotify/spotify.dart';

class SyncedLyricsProvider extends GetxController {
  RxInt delay = 0.obs;

  Future<SubtitleSimple> getSpotifyLyrics(Track track, String? token) async {
    final res = await Dio().getUri(
      Uri.parse(
        'https://spclient.wg.spotify.com/color-lyrics/v2/track/${track.id}?format=json&market=from_token',
      ),
      options: Options(
        headers: {
          'User-Agent':
              'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.0.0 Safari/537.36',
          'App-platform': 'WebPlayer',
          'authorization': 'Bearer $token'
        },
        responseType: ResponseType.json,
        validateStatus: (status) => true,
      ),
    );

    if (res.statusCode != 200) {
      return SubtitleSimple(
        lyrics: [],
        name: track.name!,
        uri: res.realUri,
        rating: 0,
        provider: 'Spotify',
      );
    }

    final linesRaw =
        Map.castFrom<dynamic, dynamic, String, dynamic>(res.data)['lyrics']
            ?['lines'] as List?;

    final lines = linesRaw?.map((line) {
          return LyricSlice(
            time: Duration(milliseconds: int.parse(line['startTimeMs'])),
            text: line['words'] as String,
          );
        }).toList() ??
        [];

    return SubtitleSimple(
      lyrics: lines,
      name: track.name!,
      uri: res.realUri,
      rating: 100,
      provider: 'Spotify',
    );
  }

  Future<SubtitleSimple> getLRCLibLyrics(Track track) async {
    final packageInfo = await PackageInfo.fromPlatform();

    final res = await Dio().getUri(
      Uri(
        scheme: 'https',
        host: 'lrclib.net',
        path: '/api/get',
        queryParameters: {
          'artist_name': track.artists?.first.name,
          'track_name': track.name,
          'album_name': track.album?.name,
          'duration': track.duration?.inSeconds.toString(),
        },
      ),
      options: Options(
        headers: {'User-Agent': 'RhythmBox/${packageInfo.version}'},
        responseType: ResponseType.json,
      ),
    );

    if (res.statusCode != 200) {
      return SubtitleSimple(
        lyrics: [],
        name: track.name!,
        uri: res.realUri,
        rating: 0,
        provider: 'LRCLib',
      );
    }

    final json = res.data as Map<String, dynamic>;

    final syncedLyricsRaw = json['syncedLyrics'] as String?;
    final syncedLyrics = syncedLyricsRaw?.isNotEmpty == true
        ? Lrc.parse(syncedLyricsRaw!)
            .lyrics
            .map(LyricSlice.fromLrcLine)
            .toList()
        : null;

    if (syncedLyrics?.isNotEmpty == true) {
      return SubtitleSimple(
        lyrics: syncedLyrics!,
        name: track.name!,
        uri: res.realUri,
        rating: 100,
        provider: 'LRCLib',
      );
    }

    final plainLyrics = (json['plainLyrics'] as String)
        .split('\n')
        .map((line) => LyricSlice(text: line, time: Duration.zero))
        .toList();

    return SubtitleSimple(
      lyrics: plainLyrics,
      name: track.name!,
      uri: res.realUri,
      rating: 0,
      provider: 'LRCLib',
    );
  }

  Future<SubtitleSimple> fetch(Track track) async {
    try {
      final database = Get.find<DatabaseProvider>().database;
      final spotify = Get.find<SpotifyProvider>().api;

      final cachedLyrics = await (database.select(database.lyricsTable)
            ..where((tbl) => tbl.trackId.equals(track.id!)))
          .map((row) => row.data)
          .getSingleOrNull();

      SubtitleSimple? lyrics = cachedLyrics;

      final token = await spotify.getCredentials();

      if (lyrics == null || lyrics.lyrics.isEmpty) {
        lyrics = await getSpotifyLyrics(track, token.accessToken);
      }

      if (lyrics.lyrics.isEmpty || lyrics.lyrics.length <= 5) {
        lyrics = await getLRCLibLyrics(track);
      }

      if (lyrics.lyrics.isEmpty) {
        throw Exception('Unable to find lyrics');
      }

      if (cachedLyrics == null || cachedLyrics.lyrics.isEmpty) {
        await database.into(database.lyricsTable).insert(
              LyricsTableCompanion.insert(
                trackId: track.id!,
                data: lyrics,
              ),
              mode: InsertMode.replace,
            );
      }

      return lyrics;
    } catch (e, stackTrace) {
      log('[Lyrics] Error: $e; Trace:\n$stackTrace');
      return SubtitleSimple(
        uri: Uri.parse('https://example.com/not-found'),
        name: 'Lyrics Not Found',
        lyrics: [],
        rating: 0,
        provider: 'Not Found',
      );
    }
  }
}
