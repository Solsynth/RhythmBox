import 'package:get/get.dart';
import 'package:rhythm_box/providers/database.dart';
import 'package:rhythm_box/services/database/database.dart';
import 'package:spotify/spotify.dart';

class PlaybackHistoryProvider extends GetxController {
  final AppDatabase _db = Get.find<DatabaseProvider>().database;

  Future<void> _batchInsertHistoryEntries(
      List<HistoryTableCompanion> entries) async {
    await _db.batch((batch) {
      batch.insertAll(_db.historyTable, entries);
    });
  }

  Future<void> addPlaylists(List<PlaylistSimple> playlists) async {
    await _batchInsertHistoryEntries([
      for (final playlist in playlists)
        HistoryTableCompanion.insert(
          type: HistoryEntryType.playlist,
          itemId: playlist.id!,
          data: playlist.toJson(),
        ),
    ]);
  }

  Future<void> addAlbums(List<AlbumSimple> albums) async {
    await _batchInsertHistoryEntries([
      for (final album in albums)
        HistoryTableCompanion.insert(
          type: HistoryEntryType.album,
          itemId: album.id!,
          data: album.toJson(),
        ),
    ]);
  }

  Future<void> addTracks(List<Track> tracks) async {
    await _batchInsertHistoryEntries([
      for (final track in tracks)
        HistoryTableCompanion.insert(
          type: HistoryEntryType.track,
          itemId: track.id!,
          data: track.toJson(),
        ),
    ]);
  }

  Future<void> addTrack(Track track) async {
    await _db.into(_db.historyTable).insert(
          HistoryTableCompanion.insert(
            type: HistoryEntryType.track,
            itemId: track.id!,
            data: track.toJson(),
          ),
        );
  }

  Future<void> clear() async {
    await _db.delete(_db.historyTable).go();
  }
}
