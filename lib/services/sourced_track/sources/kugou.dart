import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:crypto/crypto.dart';
import 'package:get/get.dart' hide Value;
import 'package:rhythm_box/providers/database.dart';
import 'package:rhythm_box/services/database/database.dart';
import 'package:spotify/spotify.dart';
import 'package:rhythm_box/services/sourced_track/enums.dart';
import 'package:rhythm_box/services/sourced_track/exceptions.dart';
import 'package:rhythm_box/services/sourced_track/models/source_info.dart';
import 'package:rhythm_box/services/sourced_track/models/source_map.dart';
import 'package:rhythm_box/services/sourced_track/sourced_track.dart';

class KugouSourceInfo extends SourceInfo {
  KugouSourceInfo({
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

class KugouSourcedTrack extends SourcedTrack {
  KugouSourcedTrack({
    required super.source,
    required super.siblings,
    required super.sourceInfo,
    required super.track,
  });

  static String unescapeUrl(String src) {
    return src.replaceAll('\\/', '/');
  }

  static String getBaseUrl() {
    return 'http://mobilecdn.kugou.com';
  }

  static GetConnect getClient() {
    final client = GetConnect(
      withCredentials: true,
      timeout: const Duration(seconds: 30),
    );
    client.baseUrl = getBaseUrl();
    return client;
  }

  static Future<KugouSourcedTrack> fetchFromTrack({
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

    if (cachedSource == null || cachedSource.sourceType != SourceType.kugou) {
      final siblings = await fetchSiblings(track: track);
      if (siblings.isEmpty) {
        throw TrackNotFoundError(track);
      }

      await db.database.into(db.database.sourceMatchTable).insert(
            SourceMatchTableCompanion.insert(
              trackId: track.id!,
              sourceId: siblings.first.info.id,
              sourceType: const Value(SourceType.kugou),
            ),
          );

      return KugouSourcedTrack(
        siblings: siblings.map((s) => s.info).skip(1).toList(),
        source: siblings.first.source as SourceMap,
        sourceInfo: siblings.first.info,
        track: track,
      );
    }

    return KugouSourcedTrack(
      siblings: [],
      source: toSourceMap(cachedSource),
      sourceInfo: KugouSourceInfo(
        id: cachedSource.sourceId,
        artist: 'unknown',
        artistUrl: '#',
        pageUrl: '#',
        thumbnail: '#',
        title: 'unknown',
        duration: Duration.zero,
        album: 'unknown',
      ),
      track: track,
    );
  }

  static SourceMap toSourceMap(dynamic manifest) {
    const baseUrl = 'http://trackercdn.kugou.com/i/v2';

    final hash = manifest is SourceMatchTableData
        ? manifest.sourceId
        : manifest is KugouSourceInfo
            ? manifest.id
            : manifest?['hash'];
    final key = md5.convert(utf8.encode('${hash}kgcloudv2')).toString();
    final url =
        '$baseUrl/song/url?key=$key&hash=$hash&appid=1005&pid=2&cmd=25&behavior=play';

    return SourceMap(
      m4a: SourceQualityMap(
        high: url,
        medium: url,
        low: url,
      ),
      weba: SourceQualityMap(
        high: url,
        medium: url,
        low: url,
      ),
    );
  }

  static Future<List<SiblingType>> fetchSiblings({
    required Track track,
  }) async {
    final query = SourcedTrack.getSearchTerm(track);

    final client = getClient();
    final resp = await client.get(
      '/api/v3/search/song?keyword=${Uri.encodeComponent(query)}&page=1&pagesize=10',
    );
    final results = jsonDecode(resp.body)['data']['info'];

    // We can just trust kugou music for now
    // If we need to check is the result correct, refer to this code
    // https://github.com/KRTirtho/spotube/blob/9b024120601c0d381edeab4460cb22f87149d0f8/lib/services/sourced_track/sources/jiosaavn.dart#L129
    final matchedResults =
        results.where((x) => x['pay_type'] == 0).map(toSiblingType).toList();

    return matchedResults.cast<SiblingType>();
  }

  @override
  Future<KugouSourcedTrack> copyWithSibling() async {
    if (siblings.isNotEmpty) {
      return this;
    }
    final fetchedSiblings = await fetchSiblings(track: this);

    return KugouSourcedTrack(
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
    if (sibling is! KugouSourceInfo) {
      return (SourcedTrack.getTrackBySourceInfo(sibling) as SourcedTrack)
          .swapWithSibling(sibling);
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

    final info = newSourceInfo as KugouSourceInfo;
    final source = toSourceMap(newSourceInfo);

    final db = Get.find<DatabaseProvider>();
    await db.database.into(db.database.sourceMatchTable).insert(
          SourceMatchTableCompanion.insert(
            trackId: id!,
            sourceId: info.id,
            sourceType: const Value(SourceType.kugou),
            // Because we're sorting by createdAt in the query
            // we have to update it to indicate priority
            createdAt: Value(DateTime.now()),
          ),
          mode: InsertMode.replace,
        );

    return KugouSourcedTrack(
      siblings: newSiblings,
      source: source,
      sourceInfo: info,
      track: this,
    );
  }

  static KugouSourceInfo toSourceInfo(dynamic item) {
    return KugouSourceInfo(
      id: item['hash'],
      artist: item['singername'],
      artistUrl: '#',
      pageUrl: '#',
      thumbnail: unescapeUrl(item['trans_param']['union_cover'])
          .replaceFirst('/{size}', ''),
      title: item['songname'],
      duration: Duration(seconds: item['duration']),
      album: item['album_name'],
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
