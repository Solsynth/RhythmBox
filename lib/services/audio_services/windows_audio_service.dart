import 'dart:async';

import 'package:get/get.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/services/audio_services/image.dart';
import 'package:smtc_windows/smtc_windows.dart';
import 'package:spotify/spotify.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';
import 'package:rhythm_box/services/audio_player/playback_state.dart';
import 'package:rhythm_box/services/artist.dart';

class WindowsAudioService {
  final SMTCWindows smtc;

  final subscriptions = <StreamSubscription>[];

  WindowsAudioService() : smtc = SMTCWindows(enabled: false) {
    smtc.setPlaybackStatus(PlaybackStatus.Stopped);
    final buttonStream = smtc.buttonPressStream.listen((event) {
      switch (event) {
        case PressedButton.play:
          audioPlayer.resume();
          break;
        case PressedButton.pause:
          audioPlayer.pause();
          break;
        case PressedButton.next:
          audioPlayer.skipToNext();
          break;
        case PressedButton.previous:
          audioPlayer.skipToPrevious();
          break;
        case PressedButton.stop:
          Get.find<AudioPlayerProvider>().stop();
          break;
        default:
          break;
      }
    });

    final playerStateStream =
        audioPlayer.playerStateStream.listen((state) async {
      switch (state) {
        case AudioPlaybackState.playing:
          await smtc.setPlaybackStatus(PlaybackStatus.Playing);
          break;
        case AudioPlaybackState.paused:
          await smtc.setPlaybackStatus(PlaybackStatus.Paused);
          break;
        case AudioPlaybackState.stopped:
          await smtc.setPlaybackStatus(PlaybackStatus.Stopped);
          break;
        case AudioPlaybackState.completed:
          await smtc.setPlaybackStatus(PlaybackStatus.Changing);
          break;
        default:
          break;
      }
    });

    final positionStream = audioPlayer.positionStream.listen((pos) async {
      await smtc.setPosition(pos);
    });

    final durationStream = audioPlayer.durationStream.listen((duration) async {
      await smtc.setEndTime(duration);
    });

    subscriptions.addAll([
      buttonStream,
      playerStateStream,
      positionStream,
      durationStream,
    ]);
  }

  Future<void> addTrack(Track track) async {
    if (!smtc.enabled) {
      await smtc.enableSmtc();
    }
    await smtc.updateMetadata(
      MusicMetadata(
        title: track.name!,
        albumArtist: track.artists?.firstOrNull?.name ?? "Unknown",
        artist: track.artists?.asString() ?? "Unknown",
        album: track.album?.name ?? "Unknown",
        thumbnail: (track.album?.images).asUrlString(),
      ),
    );
  }

  void dispose() {
    smtc.disableSmtc();
    smtc.dispose();
    for (var element in subscriptions) {
      element.cancel();
    }
  }
}
