import 'dart:async';

import 'package:get/get.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/providers/auth.dart';
import 'package:rhythm_box/providers/spotify.dart';
import 'package:rhythm_box/providers/user_preferences.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';
import 'package:spotify/spotify.dart';

import 'error_notifier.dart';

class EndlessPlaybackProvider extends GetxController {
  late final _auth = Get.find<AuthenticationProvider>();
  late final _playback = Get.find<AudioPlayerProvider>();
  late final _spotify = Get.find<SpotifyProvider>().api;
  late final _preferences = Get.find<UserPreferencesProvider>();

  bool get isEndlessPlayback => _preferences.state.value.endlessPlayback;

  late final StreamSubscription _subscription;

  StreamSubscription? _idxSubscription;

  @override
  void onInit() {
    super.onInit();

    _initPlayback();

    _subscription = _preferences.state.listen((value) {
      if (value.endlessPlayback && _idxSubscription == null) {
        _initPlayback();
      } else if (!value.endlessPlayback && _idxSubscription != null) {
        _idxSubscription!.cancel();
        _idxSubscription = null;
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _initPlayback() {
    if (!isEndlessPlayback || _auth.auth.value == null) return;

    void listener(int index) async {
      try {
        final playState = _playback.state.value;
        if (index != playState.tracks.length - 1) return;

        final track = playState.tracks.last;

        final query = '${track.name} Radio';
        final pages = await _spotify.search
            .get(query, types: [SearchType.playlist]).first();

        final radios = pages
            .expand((e) => e.items?.toList() ?? <PlaylistSimple>[])
            .toList()
            .cast<PlaylistSimple>();

        final artists = track.artists!.map((e) => e.name);

        final radio = radios.firstWhere(
          (e) {
            final validPlaylists =
                artists.where((a) => e.description!.contains(a!));
            return e.name == '${track.name} Radio' &&
                (validPlaylists.length >= 2 ||
                    validPlaylists.length == artists.length) &&
                e.owner?.displayName != 'Spotify';
          },
          orElse: () => radios.first,
        );

        final tracks =
            await _spotify.playlists.getTracksByPlaylistId(radio.id!).all();

        await _playback.addTracks(
          tracks.toList()
            ..removeWhere((e) {
              final isDuplicate =
                  _playback.state.value.tracks.any((t) => t.id == e.id);
              return e.id == track.id || isDuplicate;
            }),
        );
      } catch (e, stack) {
        Get.find<ErrorNotifier>()
            .logError('[EndlessPlayback] Error: $e', trace: stack);
      }
    }

    if (_playback.state.value.playlist.index ==
            _playback.state.value.playlist.medias.length - 1 &&
        _playback.isPlaying.value) {
      listener(_playback.state.value.playlist.index);
    }

    _idxSubscription = audioPlayer.currentIndexChangedStream.listen(listener);
  }
}
