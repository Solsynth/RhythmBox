import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:get/get.dart' hide Value;
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:rhythm_box/providers/auth.dart';
import 'package:rhythm_box/providers/database.dart';
import 'package:rhythm_box/providers/user_preferences.dart';
import 'package:rhythm_box/services/database/database.dart';
import 'package:spotify/spotify.dart';
import 'package:rhythm_box/services/sourced_track/enums.dart';
import 'package:rhythm_box/services/sourced_track/exceptions.dart';
import 'package:rhythm_box/services/sourced_track/models/source_info.dart';
import 'package:rhythm_box/services/sourced_track/models/source_map.dart';
import 'package:rhythm_box/services/sourced_track/sourced_track.dart';

class NeteaseSourceInfo extends SourceInfo {
  NeteaseSourceInfo({
    required super.id,
    required super.title,
    required super.artist,
    required super.thumbnail,
    required super.pageUrl,
    required super.duration,
    required super.artistUrl,
    required super.album,
  });
}

class NeteaseSourcedTrack extends SourcedTrack {
  NeteaseSourcedTrack({
    required super.source,
    required super.siblings,
    required super.sourceInfo,
    required super.track,
  });

  static String getBaseUrl() {
    final preferences = Get.find<UserPreferencesProvider>().state.value;
    return preferences.neteaseApiInstance;
  }

  static GetConnect getClient() {
    final client = GetConnect(
      withCredentials: true,
      timeout: const Duration(seconds: 30),
    );
    client.baseUrl = getBaseUrl();
    client.httpClient.addRequestModifier((Request request) async {
      final AuthenticationProvider auth = Get.find();
      if (auth.auth.value?.neteaseCookie != null) {
        final cookie =
            'MUSIC_U=${auth.auth.value!.getNeteaseCookie('MUSIC_U')}';
        if (request.headers['Cookie'] == null) {
          request.headers['Cookie'] = cookie;
        } else {
          request.headers['Cookie'] = request.headers['Cookie']! + cookie;
        }
      }

      return request;
    });
    return client;
  }

  static String? _lookedUpRealIp;

  static Future<String> lookupRealIp() async {
    if (_lookedUpRealIp != null) return _lookedUpRealIp!;
    const ipCheckUrl = 'https://api.ipify.org';
    final client = GetConnect(timeout: const Duration(seconds: 30));
    final resp = await client.get(ipCheckUrl);
    _lookedUpRealIp = resp.body;
    return _lookedUpRealIp!;
  }

  static Future<SourcedTrack> fetchFromTrack({
    required Track track,
  }) async {
    final DatabaseProvider db = Get.find();
    final cachedSource = await (db.database.select(db.database.sourceMatchTable)
          ..where((s) => s.trackId.equals(track.id!))
          ..limit(1)
          ..orderBy([
            (s) =>
                OrderingTerm(expression: s.createdAt, mode: OrderingMode.desc),
          ]))
        .get()
        .then((s) => s.firstOrNull);

    if (cachedSource == null || cachedSource.sourceType != SourceType.netease) {
      final siblings = await fetchSiblings(track: track);
      if (siblings.isEmpty) {
        throw TrackNotFoundError(track);
      }

      final client = getClient();
      final checkResp = await client.get(
        '/check/music?id=${siblings.first.info.id}&realIP=${await lookupRealIp()}',
      );
      if (checkResp.body['success'] != true) throw TrackNotFoundError(track);

      await db.database.into(db.database.sourceMatchTable).insert(
            SourceMatchTableCompanion.insert(
              trackId: track.id!,
              sourceId: siblings.first.info.id,
              sourceType: const Value(SourceType.netease),
            ),
            mode: InsertMode.insertOrReplace,
          );

      return NeteaseSourcedTrack(
        siblings: siblings.map((s) => s.info).skip(1).toList(),
        source: siblings.first.source as SourceMap,
        sourceInfo: siblings.first.info,
        track: track,
      );
    } else if (cachedSource.sourceType != SourceType.netease) {
      final out =
          await SourcedTrack.reRoutineFetchFromTrack(track, cachedSource);
      if (out == null) throw TrackNotFoundError(track);
      return out;
    }

    final client = getClient();
    final resp = await client.get('/song/detail?ids=${cachedSource.sourceId}');
    if (resp.body?['songs'] == null) throw TrackNotFoundError(track);
    final item = (resp.body['songs'] as List<dynamic>).firstOrNull;

    if (item == null) throw TrackNotFoundError(track);

    final checkResp = await client.get(
      '/check/music?id=${item['id']}&realIP=${await lookupRealIp()}',
    );
    if (checkResp.body['success'] != true) throw TrackNotFoundError(track);

    return NeteaseSourcedTrack(
      siblings: [],
      source: toSourceMap(item),
      sourceInfo: NeteaseSourceInfo(
        id: item['id'].toString(),
        artist: item['ar'].map((x) => x['name']).join(','),
        artistUrl: 'https://music.163.com/#/artist?id=${item['ar'][0]['id']}',
        pageUrl: 'https://music.163.com/#/song?id=${item['id']}',
        thumbnail: item['al']['picUrl'],
        title: item['name'],
        duration: Duration(milliseconds: item['dt']),
        album: item['al']['name'],
      ),
      track: track,
    );
  }

  static SourceMap toSourceMap(dynamic manifest) {
    final baseUrl = getBaseUrl();

    // Due to netease may provide m4a, mp3 and others, we cannot decide this so mock this data.
    return SourceMap(
      m4a: SourceQualityMap(
        high: '$baseUrl/song/url?id=${manifest['id']}',
        medium: '$baseUrl/song/url?id=${manifest['id']}&br=192000',
        low: '$baseUrl/song/url?id=${manifest['id']}&br=128000',
      ),
      weba: SourceQualityMap(
        high: '$baseUrl/song/url?id=${manifest['id']}',
        medium: '$baseUrl/song/url?id=${manifest['id']}&br=192000',
        low: '$baseUrl/song/url?id=${manifest['id']}&br=128000',
      ),
    );
  }

  static Future<List<SiblingType>> fetchSiblings({
    required Track track,
  }) async {
    final query = SourcedTrack.getSearchTerm(track);

    final client = getClient();
    final resp = await client.get(
      '/search?keywords=${Uri.encodeComponent(query)}&realIP=${await NeteaseSourcedTrack.lookupRealIp()}',
    );
    if (resp.body?['code'] == 405) throw TrackNotFoundError(track);
    final results = resp.body['result']['songs'];

    // We can just trust netease music for now
    // If we need to check is the result correct, refer to this code
    // https://github.com/KRTirtho/spotube/blob/9b024120601c0d381edeab4460cb22f87149d0f8/lib/services/sourced_track/sources/jiosaavn.dart#L129
    final matchedResults = results.map(toSiblingType).toList();

    return matchedResults.cast<SiblingType>();
  }

  @override
  Future<NeteaseSourcedTrack> copyWithSibling() async {
    if (siblings.isNotEmpty) {
      return this;
    }
    final fetchedSiblings = await fetchSiblings(track: this);

    return NeteaseSourcedTrack(
      siblings: fetchedSiblings
          .where((s) => s.info.id != sourceInfo.id)
          .map((s) => s.info)
          .toList(),
      source: source,
      sourceInfo: sourceInfo,
      track: this,
    );
  }

  @override
  Future<SourcedTrack?> swapWithSibling(SourceInfo sibling) async {
    if (sibling is! NeteaseSourceInfo) {
      return reRoutineSwapSiblings(sibling);
    }

    if (sibling.id == sourceInfo.id) {
      return null;
    }

    // a sibling source that was fetched from the search results
    final isStepSibling = siblings.none((s) => s.id == sibling.id);

    final newSourceInfo = isStepSibling
        ? sibling
        : siblings.firstWhere((s) => s.id == sibling.id);
    final newSiblings = siblings.where((s) => s.id != sibling.id).toList()
      ..insert(0, sourceInfo);

    final client = getClient();
    final resp = await client.get('/song/detail?ids=${newSourceInfo.id}');
    final item = (resp.body['songs'] as List<dynamic>).first;

    final (:info, :source) = toSiblingType(item);

    final db = Get.find<DatabaseProvider>();
    await db.database.into(db.database.sourceMatchTable).insert(
          SourceMatchTableCompanion.insert(
            trackId: id!,
            sourceId: info.id,
            sourceType: const Value(SourceType.netease),
            // Because we're sorting by createdAt in the query
            // we have to update it to indicate priority
            createdAt: Value(DateTime.now()),
          ),
          mode: InsertMode.replace,
        );

    return NeteaseSourcedTrack(
      siblings: newSiblings,
      source: source!,
      sourceInfo: info,
      track: this,
    );
  }

  static NeteaseSourceInfo toSourceInfo(dynamic item) {
    final firstArtist = item['ar'] != null ? item['ar'][0] : item['artists'][0];

    return NeteaseSourceInfo(
      id: item['id'].toString(),
      artist: item['ar'] != null
          ? item['ar'].map((x) => x['name']).join(',')
          : item['artists'].map((x) => x['name']).toString(),
      artistUrl: 'https://music.163.com/#/artist?id=${firstArtist['id']}',
      pageUrl: 'https://music.163.com/#/song?id=${item['id']}',
      thumbnail: item['al']?['picUrl'] ??
          'https://p1.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg',
      title: item['name'],
      duration: item['dt'] != null
          ? Duration(milliseconds: item['dt'])
          : Duration(milliseconds: item['duration']),
      album: item['al']?['name'],
    );
  }

  static SiblingType toSiblingType(dynamic item) {
    final SiblingType sibling = (
      info: toSourceInfo(item),
      source: toSourceMap(item),
    );

    return sibling;
  }
}
