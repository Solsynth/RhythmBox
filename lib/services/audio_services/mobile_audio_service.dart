import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:rhythm_box/services/audio_player/state.dart';

class MobileAudioService extends BaseAudioHandler {
  AudioSession? session;
  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
  AudioPlayerState get playlist => Get.find<AudioPlayerProvider>().state.value;

  MobileAudioService() {
    AudioSession.instance.then((s) {
      session = s;
      session?.configure(const AudioSessionConfiguration.music());

      bool wasPausedByBeginEvent = false;

      s.interruptionEventStream.listen((event) async {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              await audioPlayer.setVolume(0.5);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              {
                wasPausedByBeginEvent = audioPlayer.isPlaying;
                await audioPlayer.pause();
                break;
              }
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              await audioPlayer.setVolume(1.0);
              break;
            case AudioInterruptionType.pause when wasPausedByBeginEvent:
            case AudioInterruptionType.unknown when wasPausedByBeginEvent:
              await audioPlayer.resume();
              wasPausedByBeginEvent = false;
              break;
            default:
              break;
          }
        }
      });

      s.becomingNoisyEventStream.listen((_) {
        audioPlayer.pause();
      });
    });
    audioPlayer.playerStateStream.listen((state) async {
      playbackState.add(await _transformEvent());
    });

    audioPlayer.positionStream.listen((pos) async {
      playbackState.add(await _transformEvent());
    });
    audioPlayer.bufferedPositionStream.listen((pos) async {
      playbackState.add(await _transformEvent());
    });
  }

  void addItem(MediaItem item) {
    session?.setActive(true);
    mediaItem.add(item);
  }

  @override
  Future<void> play() => audioPlayer.resume();

  @override
  Future<void> pause() => audioPlayer.pause();

  @override
  Future<void> seek(Duration position) => audioPlayer.seek(position);

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await super.setShuffleMode(shuffleMode);

    audioPlayer.setShuffle(shuffleMode == AudioServiceShuffleMode.all);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    super.setRepeatMode(repeatMode);
    audioPlayer.setLoopMode(switch (repeatMode) {
      AudioServiceRepeatMode.all ||
      AudioServiceRepeatMode.group =>
        PlaylistMode.loop,
      AudioServiceRepeatMode.one => PlaylistMode.single,
      _ => PlaylistMode.none,
    });
  }

  @override
  Future<void> stop() async {
    await Get.find<AudioPlayerProvider>().stop();
  }

  @override
  Future<void> skipToNext() async {
    await audioPlayer.skipToNext();
    await super.skipToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    await audioPlayer.skipToPrevious();
    await super.skipToPrevious();
  }

  @override
  Future<void> onTaskRemoved() async {
    await Get.find<AudioPlayerProvider>().stop();
    return super.onTaskRemoved();
  }

  Future<PlaybackState> _transformEvent() async {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        audioPlayer.isPlaying ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: {
        MediaAction.seek,
      },
      androidCompactActionIndices: const [0, 1, 2],
      playing: audioPlayer.isPlaying,
      updatePosition: audioPlayer.position,
      bufferedPosition: audioPlayer.bufferedPosition,
      shuffleMode: audioPlayer.isShuffled == true
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
      repeatMode: switch (audioPlayer.loopMode) {
        PlaylistMode.loop => AudioServiceRepeatMode.all,
        PlaylistMode.single => AudioServiceRepeatMode.one,
        _ => AudioServiceRepeatMode.none,
      },
      processingState: audioPlayer.isBuffering
          ? AudioProcessingState.loading
          : AudioProcessingState.ready,
    );
  }
}
