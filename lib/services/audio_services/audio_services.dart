import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:rhythm_box/platform.dart';
import 'package:rhythm_box/services/audio_services/image.dart';
import 'package:spotify/spotify.dart';
import 'package:rhythm_box/services/audio_services/mobile_audio_service.dart';
import 'package:rhythm_box/services/audio_services/windows_audio_service.dart';
import 'package:rhythm_box/services/sourced_track/sourced_track.dart';
import 'package:rhythm_box/services/artist.dart';

class AudioServices with WidgetsBindingObserver {
  final MobileAudioService? mobile;
  final WindowsAudioService? smtc;

  AudioServices(this.mobile, this.smtc) {
    WidgetsBinding.instance.addObserver(this);
  }

  static Future<AudioServices> create() async {
    final mobile =
        PlatformInfo.isMobile || PlatformInfo.isMacOS || PlatformInfo.isLinux
            ? await AudioService.init(
                builder: () => MobileAudioService(),
                config: AudioServiceConfig(
                  androidNotificationChannelId: PlatformInfo.isLinux
                      ? 'RhythmBox'
                      : 'dev.solsynth.rhythmBox',
                  androidNotificationChannelName: 'RhythmBox',
                  androidNotificationOngoing: false,
                  androidNotificationIcon: "drawable/ic_launcher_monochrome",
                  androidStopForegroundOnPause: false,
                  androidNotificationChannelDescription: "RhythmBox Music",
                ),
              )
            : null;
    final smtc = PlatformInfo.isWindows ? WindowsAudioService() : null;

    return AudioServices(mobile, smtc);
  }

  Future<void> addTrack(Track track) async {
    await smtc?.addTrack(track);
    mobile?.addItem(MediaItem(
      id: track.id!,
      album: track.album?.name ?? "",
      title: track.name!,
      artist: (track.artists)?.asString() ?? "",
      duration: track is SourcedTrack
          ? track.sourceInfo.duration
          : Duration(milliseconds: track.durationMs ?? 0),
      artUri: track.album?.images != null
          ? Uri.parse(
              (track.album?.images).asUrlString()!,
            )
          : null,
      playable: true,
    ));
  }

  void activateSession() {
    mobile?.session?.setActive(true);
  }

  void deactivateSession() {
    mobile?.session?.setActive(false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        deactivateSession();
        mobile?.stop();
        break;
      default:
        break;
    }
  }

  void dispose() {
    smtc?.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }
}
