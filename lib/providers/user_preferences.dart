import 'package:get/get.dart' hide Value;
import 'package:drift/drift.dart';
import 'package:rhythm_box/platform.dart';
import 'package:rhythm_box/providers/audio_player_stream.dart';
import 'package:rhythm_box/providers/database.dart';
import 'package:rhythm_box/providers/palette.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';
import 'package:rhythm_box/services/color.dart';
import 'package:rhythm_box/services/database/database.dart';
import 'package:rhythm_box/services/sourced_track/enums.dart';
import 'package:spotify/spotify.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

typedef UserPreferences = PreferencesTableData;

class UserPreferencesProvider extends GetxController {
  final Rx<UserPreferences> state = PreferencesTable.defaults().obs;
  late final AppDatabase db;

  @override
  void onInit() {
    super.onInit();
    db = Get.find<DatabaseProvider>().database;
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    var result = await (db.select(db.preferencesTable)
          ..where((tbl) => tbl.id.equals(0)))
        .getSingleOrNull();
    if (result == null) {
      await db.into(db.preferencesTable).insert(
            PreferencesTableCompanion.insert(
              id: const Value(0),
              downloadLocation: Value(await _getDefaultDownloadDirectory()),
            ),
          );
    }
    state.value = await (db.select(db.preferencesTable)
          ..where((tbl) => tbl.id.equals(0)))
        .getSingle();

    // Subscribe to updates
    (db.select(db.preferencesTable)..where((tbl) => tbl.id.equals(0)))
        .watchSingle()
        .listen((event) async {
      state.value = event;

      await WakelockPlus.toggle(enable: state.value.playerWakelock);

      await audioPlayer.setAudioNormalization(state.value.normalizeAudio);
    });
  }

  Future<String> _getDefaultDownloadDirectory() async {
    if (PlatformInfo.isAndroid) return '/storage/emulated/0/Download/RhythmBox';

    if (PlatformInfo.isMacOS) {
      return join((await getLibraryDirectory()).path, 'Caches');
    }

    return getDownloadsDirectory().then((dir) {
      return join(dir!.path, 'RhythmBox');
    });
  }

  Future<void> setData(PreferencesTableCompanion data) async {
    await (db.update(db.preferencesTable)..where((t) => t.id.equals(0)))
        .write(data);
  }

  Future<void> reset() async {
    await (db.update(db.preferencesTable)..where((t) => t.id.equals(0)))
        .replace(PreferencesTableCompanion.insert());
  }

  void setStreamMusicCodec(SourceCodecs codec) {
    setData(PreferencesTableCompanion(streamMusicCodec: Value(codec)));
  }

  void setDownloadMusicCodec(SourceCodecs codec) {
    setData(PreferencesTableCompanion(downloadMusicCodec: Value(codec)));
  }

  void setThemeMode(ThemeMode mode) {
    setData(PreferencesTableCompanion(themeMode: Value(mode)));
  }

  void setRecommendationMarket(Market country) {
    setData(PreferencesTableCompanion(market: Value(country)));
  }

  void setAccentColorScheme(RhythmColor color) {
    setData(PreferencesTableCompanion(accentColorScheme: Value(color)));
  }

  void setAlbumColorSync(bool sync) {
    setData(PreferencesTableCompanion(albumColorSync: Value(sync)));

    if (!sync) {
      Get.find<PaletteProvider>().clear();
    } else {
      Get.find<AudioPlayerStreamProvider>().updatePalette();
    }
  }

  void setCheckUpdate(bool check) {
    setData(PreferencesTableCompanion(checkUpdate: Value(check)));
  }

  void setAudioQuality(SourceQualities quality) {
    setData(PreferencesTableCompanion(audioQuality: Value(quality)));
  }

  void setDownloadLocation(String downloadDir) {
    if (downloadDir.isEmpty) return;
    setData(PreferencesTableCompanion(downloadLocation: Value(downloadDir)));
  }

  void setLocalLibraryLocation(List<String> localLibraryDirs) {
    setData(PreferencesTableCompanion(
        localLibraryLocation: Value(localLibraryDirs)));
  }

  void setLayoutMode(LayoutMode mode) {
    setData(PreferencesTableCompanion(layoutMode: Value(mode)));
  }

  void setCloseBehavior(CloseBehavior behavior) {
    setData(PreferencesTableCompanion(closeBehavior: Value(behavior)));
  }

  void setShowSystemTrayIcon(bool show) {
    setData(PreferencesTableCompanion(showSystemTrayIcon: Value(show)));
  }

  void setLocale(Locale locale) {
    setData(PreferencesTableCompanion(locale: Value(locale)));
  }

  void setNeteaseApiInstance(String instance) {
    setData(PreferencesTableCompanion(neteaseApiInstance: Value(instance)));
  }

  void setPipedInstance(String instance) {
    setData(PreferencesTableCompanion(pipedInstance: Value(instance)));
  }

  void setSearchMode(SearchMode mode) {
    setData(PreferencesTableCompanion(searchMode: Value(mode)));
  }

  void setSkipNonMusic(bool skip) {
    setData(PreferencesTableCompanion(skipNonMusic: Value(skip)));
  }

  void setAudioSource(AudioSource type) {
    setData(PreferencesTableCompanion(audioSource: Value(type)));
  }

  void setSystemTitleBar(bool isSystemTitleBar) {
    setData(PreferencesTableCompanion(systemTitleBar: Value(isSystemTitleBar)));
  }

  void setNormalizeAudio(bool normalize) {
    setData(PreferencesTableCompanion(normalizeAudio: Value(normalize)));
    audioPlayer.setAudioNormalization(normalize);
  }

  void setEndlessPlayback(bool endless) {
    setData(PreferencesTableCompanion(endlessPlayback: Value(endless)));
  }

  void setPlayerWakelock(bool wakelock) {
    setData(PreferencesTableCompanion(playerWakelock: Value(wakelock)));
    WakelockPlus.toggle(enable: wakelock);
  }

  void setOverrideCacheProvider(bool override) {
    setData(PreferencesTableCompanion(overrideCacheProvider: Value(override)));
  }
}
