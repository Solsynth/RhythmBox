import 'dart:async';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/providers/history.dart';
import 'package:rhythm_box/providers/scrobbler.dart';
import 'package:rhythm_box/providers/skip_segments.dart';
import 'package:rhythm_box/providers/user_preferences.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';
import 'package:rhythm_box/services/audio_services/audio_services.dart';
import 'package:rhythm_box/services/audio_services/image.dart';
import 'package:rhythm_box/services/local_track.dart';
import 'package:rhythm_box/services/server/sourced_track.dart';
import 'package:rhythm_box/widgets/auto_cache_image.dart';

class AudioPlayerStreamProvider extends GetxController {
  late final AudioServices notificationService;
  final Rxn<PaletteGenerator?> palette = Rxn<PaletteGenerator?>();

  List<StreamSubscription>? _subscriptions;

  @override
  void onInit() {
    super.onInit();
    AudioServices.create().then(
      (value) => notificationService = value,
    );

    _subscriptions = [
      subscribeToPlaylist(),
      subscribeToSkipSponsor(),
      subscribeToScrobbleChanged(),
      subscribeToPosition(),
      subscribeToPlayerError(),
    ];
  }

  @override
  void dispose() {
    if (_subscriptions != null) {
      for (final subscription in _subscriptions!) {
        subscription.cancel();
      }
    }
    super.dispose();
  }

  Future<void> updatePalette() async {
    if (!Get.find<UserPreferences>().albumColorSync) {
      if (palette.value != null) {
        palette.value = null;
      }
      return;
    }

    final AudioPlayerProvider playback = Get.find();
    final activeTrack = playback.state.value.activeTrack;
    if (activeTrack == null) return;

    if (activeTrack.album?.images != null) {
      final newPalette = await PaletteGenerator.fromImageProvider(
        AutoCacheImage.provider(
          (activeTrack.album?.images).asUrlString()!,
        ),
      );
      palette.value = newPalette;
    }
  }

  StreamSubscription subscribeToPlaylist() {
    final AudioPlayerProvider playback = Get.find();
    return audioPlayer.playlistStream.listen((mpvPlaylist) {
      final activeTrack = playback.state.value.activeTrack;
      if (activeTrack != null) {
        notificationService.addTrack(activeTrack);
        updatePalette();
      }
    });
  }

  StreamSubscription subscribeToSkipSponsor() {
    return audioPlayer.positionStream.listen((position) async {
      final currentSegments =
          await Get.find<SegmentsProvider>().fetchSegments();

      if (currentSegments?.segments.isNotEmpty != true ||
          position < const Duration(seconds: 3)) return;

      for (final segment in currentSegments!.segments) {
        final seconds = position.inSeconds;

        if (seconds < segment.start || seconds >= segment.end) continue;

        await audioPlayer.seek(Duration(seconds: segment.end + 1));
      }
    });
  }

  StreamSubscription subscribeToScrobbleChanged() {
    String? lastScrobbled;
    return audioPlayer.positionStream.listen((position) {
      try {
        final AudioPlayerProvider playback = Get.find();
        final uid = playback.state.value.activeTrack is LocalTrack
            ? (playback.state.value.activeTrack as LocalTrack).path
            : playback.state.value.activeTrack?.id;

        if (playback.state.value.activeTrack == null ||
            lastScrobbled == uid ||
            position.inSeconds < 30) {
          return;
        }

        Get.find<ScrobblerProvider>()
            .scrobble(playback.state.value.activeTrack!);
        Get.find<PlaybackHistoryProvider>()
            .addTrack(playback.state.value.activeTrack!);
        lastScrobbled = uid;
      } catch (e, stack) {
        log('[Scrobbler] Error: $e; Trace:\n$stack');
      }
    });
  }

  StreamSubscription subscribeToPosition() {
    String lastTrack = ''; // used to prevent multiple calls to the same track
    final AudioPlayerProvider playback = Get.find();
    return audioPlayer.positionStream.listen((event) async {
      if (event < const Duration(seconds: 3) ||
          audioPlayer.playlist.index == -1 ||
          audioPlayer.playlist.index ==
              playback.state.value.tracks.length - 1) {
        return;
      }
      final nextTrack = RhythmMedia.fromMedia(
        audioPlayer.playlist.medias.elementAt(audioPlayer.playlist.index + 1),
      );

      if (lastTrack == nextTrack.track.id || nextTrack.track is LocalTrack) {
        return;
      }

      try {
        await Get.find<SourcedTrackProvider>().fetch(nextTrack);
      } finally {
        lastTrack = nextTrack.track.id!;
      }
    });
  }

  StreamSubscription subscribeToPlayerError() {
    return audioPlayer.errorStream.listen((event) {
      // Handle player error events here
    });
  }
}
