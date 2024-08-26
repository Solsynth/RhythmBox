import 'dart:math';

import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:rhythm_box/services/audio_player/state.dart';
import 'package:rhythm_box/services/local_track.dart';
import 'package:rhythm_box/services/sourced_track/sourced_track.dart';
import 'package:spotify/spotify.dart' hide Playlist;
import 'package:rhythm_box/services/audio_player/audio_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioPlayerProvider extends GetxController {
  late final SharedPreferences _prefs;

  Rx<AudioPlayerState> state = Rx(AudioPlayerState(
    playing: false,
    shuffled: false,
    loopMode: PlaylistMode.none,
    playlist: const Playlist([]),
    collections: [],
  ));

  AudioPlayerProvider() {
    SharedPreferences.getInstance().then((ins) {
      _prefs = ins;
    });
  }

  Future<void> _syncSavedState() async {
    final data = _prefs.getBool("player_state");
    if (data == null) return;

    // TODO Serilize and deserilize this state

    // TODO Sync saved playlist
  }

  Future<void> load(
    List<Track> tracks, {
    int initialIndex = 0,
    bool autoPlay = false,
  }) async {
    final medias = tracks.map((x) => RhythmMedia(x)).toList();

    // Giving the initial track a boost so MediaKit won't skip
    // because of timeout
    final intendedActiveTrack = medias.elementAt(initialIndex);
    if (intendedActiveTrack.track is! LocalTrack) {
      await SourcedTrack.fetchFromTrack(track: intendedActiveTrack.track);
    }

    if (medias.isEmpty) return;

    await audioPlayer.openPlaylist(
      medias.map((s) => s as Media).toList(),
      initialIndex: initialIndex,
      autoPlay: autoPlay,
    );
  }

  Future<void> addTracksAtFirst(Iterable<Track> tracks) async {
    if (state.value.tracks.length == 1) {
      return addTracks(tracks);
    }

    for (int i = 0; i < tracks.length; i++) {
      final track = tracks.elementAt(i);

      await audioPlayer.addTrackAt(
        RhythmMedia(track),
        max(state.value.playlist.index, 0) + i + 1,
      );
    }
  }

  Future<void> addTrack(Track track) async {
    await audioPlayer.addTrack(RhythmMedia(track));
  }

  Future<void> addTracks(Iterable<Track> tracks) async {
    for (final track in tracks) {
      await audioPlayer.addTrack(RhythmMedia(track));
    }
  }

  Future<void> removeTrack(String trackId) async {
    final index =
        state.value.tracks.indexWhere((element) => element.id == trackId);

    if (index == -1) return;

    await audioPlayer.removeTrack(index);
  }

  Future<void> removeTracks(Iterable<String> trackIds) async {
    for (final trackId in trackIds) {
      await removeTrack(trackId);
    }
  }

  Future<void> jumpToTrack(Track track) async {
    final index = state.value.tracks
        .toList()
        .indexWhere((element) => element.id == track.id);
    if (index == -1) return;
    await audioPlayer.jumpTo(index);
  }

  Future<void> moveTrack(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex ||
        newIndex < 0 ||
        oldIndex < 0 ||
        newIndex > state.value.tracks.length - 1 ||
        oldIndex > state.value.tracks.length - 1) return;

    await audioPlayer.moveTrack(oldIndex, newIndex);
  }

  Future<void> stop() async {
    await audioPlayer.stop();
  }
}
