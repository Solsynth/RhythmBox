import 'dart:io';

import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:flutter/foundation.dart';
import 'package:rhythm_box/platform.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/providers/error_notifier.dart';
import 'package:rhythm_box/services/local_track.dart';
import 'package:rhythm_box/services/server/server.dart';
import 'package:rhythm_box/widgets/tracks/querying_track_info.dart';
import 'package:spotify/spotify.dart' hide Playlist;
import 'package:rhythm_box/services/audio_player/custom_player.dart';
import 'dart:async';

import 'package:media_kit/media_kit.dart' as mk;

import 'package:rhythm_box/services/audio_player/playback_state.dart';
import 'package:rhythm_box/services/sourced_track/sourced_track.dart';

part 'audio_players_streams_mixin.dart';
part 'audio_player_impl.dart';

class RhythmMedia extends mk.Media {
  final Track track;

  static int get serverPort => Get.find<PlaybackServerProvider>().port;

  RhythmMedia(
    this.track, {
    Map<String, dynamic>? extras,
    super.httpHeaders,
  }) : super(
          track is LocalTrack
              ? track.path
              : "http://${PlatformInfo.isWindows ? "localhost" : InternetAddress.anyIPv4.address}:$serverPort/stream/${track.id}",
          extras: {
            ...?extras,
            'track': switch (track) {
              LocalTrack() => track.toJson(),
              SourcedTrack() => track.toJson(),
              _ => track.toJson(),
            },
          },
        );

  @override
  String get uri {
    return switch (track) {
      /// [super.uri] must be used instead of [track.path] to prevent wrong
      /// path format exceptions in Windows causing [extras] to be null
      LocalTrack() => super.uri,
      _ =>
        "http://${PlatformInfo.isWindows ? "localhost" : InternetAddress.anyIPv4.address}:"
            '$serverPort/stream/${track.id}',
    };
  }

  factory RhythmMedia.fromMedia(mk.Media media) {
    final track = media.uri.startsWith('http')
        ? Track.fromJson(media.extras?['track'])
        : LocalTrack.fromJson(media.extras?['track']);
    return RhythmMedia(
      track,
      extras: media.extras,
      httpHeaders: media.httpHeaders,
    );
  }

  // @override
  // operator ==(Object other) {
  //   if (other is! RhythmMedia) return false;

  //   final isLocal = track is LocalTrack && other.track is LocalTrack;
  //   return isLocal
  //       ? (other.track as LocalTrack).path == (track as LocalTrack).path
  //       : other.track.id == track.id;
  // }

  // @override
  // int get hashCode => track is LocalTrack
  //     ? (track as LocalTrack).path.hashCode
  //     : track.id.hashCode;
}

abstract class AudioPlayerInterface {
  final CustomPlayer _mkPlayer;

  AudioPlayerInterface()
      : _mkPlayer = CustomPlayer(
          configuration: const mk.PlayerConfiguration(
            title: 'Rhythm',
            logLevel: kDebugMode ? mk.MPVLogLevel.info : mk.MPVLogLevel.error,
          ),
        ) {
    _mkPlayer.stream.error.listen((event) {
      Get.find<ErrorNotifier>().logError('[Playback][Player] Error: $event');
    });
  }

  /// Whether the current platform supports the audioplayers plugin
  static const bool _mkSupportedPlatform = true;

  bool get mkSupportedPlatform => _mkSupportedPlatform;

  Duration get duration {
    return _mkPlayer.state.duration;
  }

  Playlist get playlist {
    return _mkPlayer.state.playlist;
  }

  Duration get position {
    return _mkPlayer.state.position;
  }

  Duration get bufferedPosition {
    return _mkPlayer.state.buffer;
  }

  Future<mk.AudioDevice> get selectedDevice async {
    return _mkPlayer.state.audioDevice;
  }

  Future<List<mk.AudioDevice>> get devices async {
    return _mkPlayer.state.audioDevices;
  }

  bool get hasSource {
    return _mkPlayer.state.playlist.medias.isNotEmpty;
  }

  // states
  bool get isPlaying {
    return _mkPlayer.state.playing;
  }

  bool get isPaused {
    return !_mkPlayer.state.playing;
  }

  bool get isStopped {
    return !hasSource;
  }

  Future<bool> get isCompleted async {
    return _mkPlayer.state.completed;
  }

  bool get isShuffled {
    return _mkPlayer.shuffled;
  }

  PlaylistMode get loopMode {
    return _mkPlayer.state.playlistMode;
  }

  /// Returns the current volume of the player, between 0 and 1
  double get volume {
    return _mkPlayer.state.volume / 100;
  }

  bool get isBuffering {
    return _mkPlayer.state.buffering;
  }
}
