library database;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:encrypt/encrypt.dart';
import 'package:media_kit/media_kit.dart' hide Track;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rhythm_box/services/color.dart';
import 'package:rhythm_box/services/lyrics/model.dart';
import 'package:spotify/spotify.dart' hide Playlist;
import 'package:rhythm_box/services/kv_store/encrypted_kv_store.dart';
import 'package:rhythm_box/services/kv_store/kv_store.dart';
import 'package:rhythm_box/services/sourced_track/enums.dart';
import 'package:flutter/material.dart' hide Table, Key, View;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'database.g.dart';

part 'tables/authentication.dart';
part 'tables/preferences.dart';
part 'tables/scrobbler.dart';
part 'tables/skip_segment.dart';
part 'tables/source_match.dart';
part 'tables/history.dart';
part 'tables/lyrics.dart';
part 'tables/audio_player_state.dart';

part 'typeconverters/color.dart';
part 'typeconverters/locale.dart';
part 'typeconverters/string_list.dart';
part 'typeconverters/encrypted_text.dart';
part 'typeconverters/map.dart';
part 'typeconverters/subtitle.dart';

@DriftDatabase(
  tables: [
    AuthenticationTable,
    PreferencesTable,
    ScrobblerTable,
    SkipSegmentTable,
    SourceMatchTable,
    HistoryTable,
    LyricsTable,
    AudioPlayerStateTable,
    PlaylistTable,
    PlaylistMediaTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(preferencesTable, preferencesTable.playerWakelock);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(join(dbFolder.path, 'db.sqlite'));

    // Also work around limitations on old Android versions
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    // Make sqlite3 pick a more suitable location for temporary files - the
    // one from the system may be inaccessible due to sandboxing.
    final cacheBase = (await getTemporaryDirectory()).path;
    // We can't access /tmp on Android, which sqlite3 would try by default.
    // Explicitly tell it about the correct temporary directory.
    sqlite3.tempDirectory = cacheBase;

    return NativeDatabase.createInBackground(file);
  });
}
