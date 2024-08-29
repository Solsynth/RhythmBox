import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:rhythm_box/platform.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/providers/audio_player_stream.dart';
import 'package:rhythm_box/providers/auth.dart';
import 'package:rhythm_box/providers/database.dart';
import 'package:rhythm_box/providers/endless_playback.dart';
import 'package:rhythm_box/providers/history.dart';
import 'package:rhythm_box/providers/palette.dart';
import 'package:rhythm_box/providers/scrobbler.dart';
import 'package:rhythm_box/providers/skip_segments.dart';
import 'package:rhythm_box/providers/spotify.dart';
import 'package:rhythm_box/providers/user_preferences.dart';
import 'package:rhythm_box/router.dart';
import 'package:rhythm_box/services/kv_store/encrypted_kv_store.dart';
import 'package:rhythm_box/services/kv_store/kv_store.dart';
import 'package:rhythm_box/services/lyrics/provider.dart';
import 'package:rhythm_box/services/server/active_sourced_track.dart';
import 'package:rhythm_box/services/server/routes/playback.dart';
import 'package:rhythm_box/services/server/server.dart';
import 'package:rhythm_box/services/server/sourced_track.dart';
import 'package:rhythm_box/translations.dart';
import 'package:rhythm_box/widgets/tracks/querying_track_info.dart';
import 'package:smtc_windows/smtc_windows.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main(List<String> rawArgs) async {
  if (rawArgs.contains('web_view_title_bar')) {
    WidgetsFlutterBinding.ensureInitialized();
    if (runWebViewTitleBarWidget(rawArgs)) {
      return;
    }
  }

  MediaKit.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  if (PlatformInfo.isDesktop) {
    await windowManager.setPreventClose(true);
  }
  if (PlatformInfo.isWindows) {
    await SMTCWindows.initialize();
  }

  await KVStoreService.initialize();
  await EncryptedKvStoreService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp.router(
      title: 'DietaryGuard',
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
      backButtonDispatcher: router.backButtonDispatcher,
      locale: Get.deviceLocale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      translations: AppTranslations(),
      onInit: () => _initializeProviders(context),
    );
  }

  void _initializeProviders(BuildContext context) async {
    Get.lazyPut(() => SpotifyProvider());
    Get.lazyPut(() => SyncedLyricsProvider());

    Get.put(DatabaseProvider());
    Get.put(AuthenticationProvider());

    Get.put(AudioPlayerProvider());
    Get.put(ActiveSourcedTrackProvider());
    Get.put(AudioPlayerStreamProvider());

    Get.put(PlaybackHistoryProvider());
    Get.put(SegmentsProvider());
    Get.put(PaletteProvider());
    Get.put(ScrobblerProvider());
    Get.put(UserPreferencesProvider());

    Get.put(QueryingTrackInfoProvider());
    Get.put(SourcedTrackProvider());
    Get.put(EndlessPlaybackProvider());

    Get.put(ServerPlaybackRoutesProvider());
    Get.put(PlaybackServerProvider());
  }
}
