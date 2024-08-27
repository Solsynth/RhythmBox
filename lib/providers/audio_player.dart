import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:get/get.dart' hide Value;
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:rhythm_box/providers/database.dart';
import 'package:rhythm_box/services/audio_player/state.dart';
import 'package:rhythm_box/services/database/database.dart';
import 'package:spotify/spotify.dart' hide Playlist;
import 'package:rhythm_box/services/audio_player/audio_player.dart';

class AudioPlayerProvider extends GetxController {
  RxBool isPlaying = false.obs;

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
    _subscriptions = [
      audioPlayer.playingStream.listen((playing) async {
        state.value = state.value.copyWith(playing: playing);
        await _updatePlayerState(
          AudioPlayerStateTableCompanion(
            playing: Value(playing),
          ),
        );
      }),
      audioPlayer.loopModeStream.listen((loopMode) async {
        state.value = state.value.copyWith(loopMode: loopMode);
        await _updatePlayerState(
          AudioPlayerStateTableCompanion(
            loopMode: Value(loopMode),
          ),
        );
      }),
      audioPlayer.shuffledStream.listen((shuffled) async {
        state.value = state.value.copyWith(shuffled: shuffled);
        await _updatePlayerState(
          AudioPlayerStateTableCompanion(
            shuffled: Value(shuffled),
          ),
        );
      }),
      audioPlayer.playlistStream.listen((playlist) async {
        state.value = state.value.copyWith(playlist: playlist);
        await _updatePlaylist(playlist);
      }),
    ];

    _readSavedState();

    audioPlayer.playingStream.listen((playing) {
      isPlaying.value = playing;
    });

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

  Future<void> _readSavedState() async {
    final database = Get.find<DatabaseProvider>().database;

    var playerState =
        await database.select(database.audioPlayerStateTable).getSingleOrNull();

    if (playerState == null) {
      await database.into(database.audioPlayerStateTable).insert(
            AudioPlayerStateTableCompanion.insert(
              playing: audioPlayer.isPlaying,
              loopMode: audioPlayer.loopMode,
              shuffled: audioPlayer.isShuffled,
              collections: <String>[],
              id: const Value(0),
            ),
          );

      playerState =
          await database.select(database.audioPlayerStateTable).getSingle();
    } else {
      await audioPlayer.setLoopMode(playerState.loopMode);
      await audioPlayer.setShuffle(playerState.shuffled);
    }

    var playlist =
        await database.select(database.playlistTable).getSingleOrNull();
    var medias = await database.select(database.playlistMediaTable).get();

    if (playlist == null) {
      await database.into(database.playlistTable).insert(
            PlaylistTableCompanion.insert(
              audioPlayerStateId: 0,
              index: audioPlayer.playlist.index,
              id: const Value(0),
            ),
          );

      playlist = await database.select(database.playlistTable).getSingle();
    }

    if (medias.isEmpty && audioPlayer.playlist.medias.isNotEmpty) {
      await database.batch((batch) {
        batch.insertAll(
          database.playlistMediaTable,
          [
            for (final media in audioPlayer.playlist.medias)
              PlaylistMediaTableCompanion.insert(
                playlistId: playlist!.id,
                uri: media.uri,
                extras: Value(media.extras),
                httpHeaders: Value(media.httpHeaders),
              ),
          ],
        );
      });
    } else if (medias.isNotEmpty) {
      await audioPlayer.openPlaylist(
        medias
            .map(
              (media) => RhythmMedia.fromMedia(
                Media(
                  media.uri,
                  extras: media.extras,
                  httpHeaders: media.httpHeaders,
                ),
              ),
            )
            .toList(),
        initialIndex: playlist.index,
        autoPlay: false,
      );
    }

    if (playerState.collections.isNotEmpty) {
      state.value = state.value.copyWith(
        collections: playerState.collections,
      );
    }
  }

  Future<void> _updatePlayerState(
    AudioPlayerStateTableCompanion companion,
  ) async {
    final database = Get.find<DatabaseProvider>().database;

    await (database.update(database.audioPlayerStateTable)
          ..where((tb) => tb.id.equals(0)))
        .write(companion);
  }

  Future<void> _updatePlaylist(
    Playlist playlist,
  ) async {
    final database = Get.find<DatabaseProvider>().database;

    await database.batch((batch) {
      batch.update(
        database.playlistTable,
        PlaylistTableCompanion(index: Value(playlist.index)),
        where: (tb) => tb.id.equals(0),
      );

      batch.deleteAll(database.playlistMediaTable);

      if (playlist.medias.isEmpty) return;
      batch.insertAll(
        database.playlistMediaTable,
        [
          for (final media in playlist.medias)
            PlaylistMediaTableCompanion.insert(
              playlistId: 0,
              uri: media.uri,
              extras: Value(media.extras),
              httpHeaders: Value(media.httpHeaders),
            ),
        ],
      );
    });
  }

  Future<void> addCollections(List<String> collectionIds) async {
    state.value = state.value.copyWith(collections: [
      ...state.value.collections,
      ...collectionIds,
    ]);

    await _updatePlayerState(
      AudioPlayerStateTableCompanion(
        collections: Value(state.value.collections),
      ),
    );
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

    await _updatePlayerState(
      AudioPlayerStateTableCompanion(
        collections: Value(state.value.collections),
      ),
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
    // final intendedActiveTrack = medias.elementAt(initialIndex);
    // if (intendedActiveTrack.track is! LocalTrack) {
    //   await Get.find<SourcedTrackProvider>()
    //       .fetch(RhythmMedia(intendedActiveTrack.track));
    // }

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

    final item = state.value.playlist.medias.removeAt(oldIndex);

    state.value = state.value.copyWith(
      playlist: state.value.playlist.copyWith(
        medias: state.value.playlist.medias
          ..insert(oldIndex < newIndex ? newIndex - 1 : 0, item),
      ),
    );

    await audioPlayer.moveTrack(oldIndex, newIndex);
  }

  Future<void> stop() async {
    await audioPlayer.stop();
  }
}
