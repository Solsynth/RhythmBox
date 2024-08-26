import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:rhythm_box/services/audio_player/state.dart';
import 'package:rhythm_box/services/local_track.dart';
import 'package:rhythm_box/services/server/sourced_track.dart';
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

  List<StreamSubscription<Object>>? _subscriptions;

  @override
  void onInit() {
    SharedPreferences.getInstance().then((ins) {
      _prefs = ins;
      _syncSavedState();
    });

    _subscriptions = [
      audioPlayer.playingStream.listen((playing) async {
        state.value = state.value.copyWith(playing: playing);
      }),
      audioPlayer.loopModeStream.listen((loopMode) async {
        state.value = state.value.copyWith(loopMode: loopMode);
      }),
      audioPlayer.shuffledStream.listen((shuffled) async {
        state.value = state.value.copyWith(shuffled: shuffled);
      }),
      audioPlayer.playlistStream.listen((playlist) async {
        state.value = state.value.copyWith(playlist: playlist);
      }),
    ];

    state.value = AudioPlayerState(
      loopMode: audioPlayer.loopMode,
      playing: audioPlayer.isPlaying,
      playlist: audioPlayer.playlist,
      shuffled: audioPlayer.isShuffled,
      collections: [],
    );

    super.onInit();
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

  Future<void> _syncSavedState() async {
    final data = _prefs.getBool("player_state");
    if (data == null) return;

    // TODO Serilize and deserilize this state

    // TODO Sync saved playlist
  }

  Future<void> addCollections(List<String> collectionIds) async {
    state.value = state.value.copyWith(collections: [
      ...state.value.collections,
      ...collectionIds,
    ]);
  }

  Future<void> addCollection(String collectionId) async {
    await addCollections([collectionId]);
  }

  Future<void> removeCollections(List<String> collectionIds) async {
    state.value = state.value.copyWith(
      collections: state.value.collections
          .where((element) => !collectionIds.contains(element))
          .toList(),
    );
  }

  Future<void> removeCollection(String collectionId) async {
    await removeCollections([collectionId]);
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
      await Get.find<SourcedTrackProvider>()
          .fetch(RhythmMedia(intendedActiveTrack.track));
    }

    if (medias.isEmpty) return;

    await removeCollections(state.value.collections);

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
