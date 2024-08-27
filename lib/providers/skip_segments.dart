import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/database.dart';
import 'package:rhythm_box/providers/user_preferences.dart';
import 'package:rhythm_box/services/database/database.dart';
import 'package:rhythm_box/services/server/active_sourced_track.dart';

class SourcedSegments {
  final String source;
  final List<SkipSegmentTableData> segments;

  SourcedSegments({required this.source, required this.segments});
}

Future<List<SkipSegmentTableData>> getAndCacheSkipSegments(String id) async {
  final database = Get.find<DatabaseProvider>().database;
  try {
    final cached = await (database.select(database.skipSegmentTable)
          ..where((s) => s.trackId.equals(id)))
        .get();

    if (cached.isNotEmpty) {
      return cached;
    }

    final res = await Dio().getUri(
      Uri(
        scheme: 'https',
        host: 'sponsor.ajay.app',
        path: '/api/skipSegments',
        queryParameters: {
          'videoID': id,
          'category': [
            'sponsor',
            'selfpromo',
            'interaction',
            'intro',
            'outro',
            'music_offtopic'
          ],
          'actionType': 'skip'
        },
      ),
      options: Options(
        responseType: ResponseType.json,
        validateStatus: (status) => (status ?? 0) < 500,
      ),
    );

    if (res.data == 'Not Found') {
      return List.castFrom<dynamic, SkipSegmentTableData>([]);
    }

    final data = res.data as List;
    final segments = data.map((obj) {
      final start = obj['segment'].first.toInt();
      final end = obj['segment'].last.toInt();
      return SkipSegmentTableCompanion.insert(
        trackId: id,
        start: start,
        end: end,
      );
    }).toList();

    await database.batch((b) {
      b.insertAll(database.skipSegmentTable, segments);
    });

    return await (database.select(database.skipSegmentTable)
          ..where((s) => s.trackId.equals(id)))
        .get();
  } catch (e, stack) {
    log('[SkipSegment] Error: $e; Trace:\n$stack');
    return List.castFrom<dynamic, SkipSegmentTableData>([]);
  }
}

class SegmentsProvider extends GetxController {
  final Rx<SourcedSegments?> segments = Rx<SourcedSegments?>(null);

  Future<SourcedSegments?> fetchSegments() async {
    final track = Get.find<ActiveSourcedTrackProvider>().state.value;
    if (track == null) {
      segments.value = null;
      return null;
    }

    final userPreferences = Get.find<UserPreferencesProvider>().state.value;
    final skipNonMusic = userPreferences.skipNonMusic &&
        !(userPreferences.audioSource == AudioSource.piped &&
            userPreferences.searchMode == SearchMode.youtubeMusic);

    if (!skipNonMusic) {
      segments.value = SourcedSegments(
        segments: [],
        source: track.sourceInfo.id,
      );
      return null;
    }

    final fetchedSegments = await getAndCacheSkipSegments(track.sourceInfo.id);
    segments.value = SourcedSegments(
      source: track.sourceInfo.id,
      segments: fetchedSegments,
    );

    return segments.value!;
  }

  @override
  void onInit() {
    super.onInit();
    fetchSegments(); // Automatically load segments when controller is initialized
  }
}
