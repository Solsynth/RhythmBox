import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/user_preferences.dart';
import 'package:rhythm_box/services/database/database.dart';
import 'package:rhythm_box/services/sourced_track/sources/netease.dart';
import 'package:rhythm_box/services/utils.dart';
import 'package:spotify/spotify.dart';

import 'package:rhythm_box/services/sourced_track/enums.dart';
import 'package:rhythm_box/services/sourced_track/exceptions.dart';
import 'package:rhythm_box/services/sourced_track/models/source_info.dart';
import 'package:rhythm_box/services/sourced_track/models/source_map.dart';
import 'package:rhythm_box/services/sourced_track/sources/piped.dart';
import 'package:rhythm_box/services/sourced_track/sources/youtube.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

abstract class SourcedTrack extends Track {
  final SourceMap source;
  final List<SourceInfo> siblings;
  final SourceInfo sourceInfo;

  SourcedTrack({
    required this.source,
    required this.siblings,
    required this.sourceInfo,
    required Track track,
  }) {
    id = track.id;
    name = track.name;
    artists = track.artists;
    album = track.album;
    durationMs = track.durationMs;
    discNumber = track.discNumber;
    explicit = track.explicit;
    externalIds = track.externalIds;
    href = track.href;
    isPlayable = track.isPlayable;
    linkedFrom = track.linkedFrom;
    popularity = track.popularity;
    previewUrl = track.previewUrl;
    trackNumber = track.trackNumber;
    type = track.type;
    uri = track.uri;
  }

  static SourcedTrack fromJson(Map<String, dynamic> json) {
    final preferences = Get.find<UserPreferencesProvider>().state.value;
    final audioSource = preferences.audioSource;

    final sourceInfo = SourceInfo.fromJson(json);
    final source = SourceMap.fromJson(json);
    final track = Track.fromJson(json);
    final siblings = (json['siblings'] as List)
        .map((sibling) => SourceInfo.fromJson(sibling))
        .toList()
        .cast<SourceInfo>();

    return switch (audioSource) {
      AudioSource.netease => NeteaseSourcedTrack(
          source: source,
          siblings: siblings,
          sourceInfo: sourceInfo,
          track: track,
        ),
      AudioSource.piped => PipedSourcedTrack(
          source: source,
          siblings: siblings,
          sourceInfo: sourceInfo,
          track: track,
        ),
      _ => YoutubeSourcedTrack(
          source: source,
          siblings: siblings,
          sourceInfo: sourceInfo,
          track: track,
        ),
    };
  }

  static String getSearchTerm(Track track) {
    final artists = (track.artists ?? [])
        .map((ar) => ar.name)
        .toList()
        .whereNotNull()
        .toList();

    final title = ServiceUtils.getTitle(
      track.name!,
      artists: artists,
      onlyCleanArtist: true,
    ).trim();

    return "$title - ${artists.join(", ")}";
  }

  static Future<SourcedTrack> fetchFromTrack({
    required Track track,
  }) async {
    final preferences = Get.find<UserPreferencesProvider>().state.value;
    final audioSource = preferences.audioSource;

    try {
      return switch (audioSource) {
        AudioSource.netease =>
          await NeteaseSourcedTrack.fetchFromTrack(track: track),
        AudioSource.piped =>
          await PipedSourcedTrack.fetchFromTrack(track: track),
        _ => await YoutubeSourcedTrack.fetchFromTrack(track: track),
      };
    } on TrackNotFoundError catch (_) {
      return switch (preferences.audioSource) {
        AudioSource.piped ||
        AudioSource.youtube =>
          await NeteaseSourcedTrack.fetchFromTrack(track: track),
        AudioSource.netease =>
          await YoutubeSourcedTrack.fetchFromTrack(track: track),
      };
    } on HttpClientClosedException catch (_) {
      return await PipedSourcedTrack.fetchFromTrack(track: track);
    } on VideoUnplayableException catch (_) {
      return await PipedSourcedTrack.fetchFromTrack(track: track);
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<SiblingType>> fetchSiblings({
    required Track track,
  }) {
    final preferences = Get.find<UserPreferencesProvider>().state.value;
    final audioSource = preferences.audioSource;

    return switch (audioSource) {
      AudioSource.piped => PipedSourcedTrack.fetchSiblings(track: track),
      _ => YoutubeSourcedTrack.fetchSiblings(track: track),
    };
  }

  Future<SourcedTrack> copyWithSibling();

  Future<SourcedTrack?> swapWithSibling(SourceInfo sibling);

  Future<SourcedTrack?> swapWithSiblingOfIndex(int index) {
    return swapWithSibling(siblings[index]);
  }

  String get url {
    final preferences = Get.find<UserPreferencesProvider>().state.value;
    final streamMusicCodec = preferences.streamMusicCodec;

    return getUrlOfCodec(streamMusicCodec);
  }

  String getUrlOfCodec(SourceCodecs codec) {
    final preferences = Get.find<UserPreferencesProvider>().state.value;
    final audioQuality = preferences.audioQuality;

    return source[codec]?[audioQuality] ??
        // this will ensure playback doesn't break
        source[codec == SourceCodecs.m4a ? SourceCodecs.weba : SourceCodecs.m4a]
            [audioQuality];
  }

  SourceCodecs get codec {
    final preferences = Get.find<UserPreferencesProvider>().state.value;
    final streamMusicCodec = preferences.streamMusicCodec;

    return streamMusicCodec;
  }
}
