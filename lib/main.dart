import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/providers/spotify.dart';
import 'package:rhythm_box/router.dart';
import 'package:rhythm_box/services/server/active_sourced_track.dart';
import 'package:rhythm_box/services/server/routes/playback.dart';
import 'package:rhythm_box/services/server/server.dart';
import 'package:rhythm_box/services/server/sourced_track.dart';
import 'package:rhythm_box/translations.dart';

void main() {
  MediaKit.ensureInitialized();

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
    Get.lazyPut(() => ActiveSourcedTrackProvider());
    Get.lazyPut(() => SourcedTrackProvider());

    Get.put(AudioPlayerProvider());
    Get.put(ServerPlaybackRoutesProvider());
    Get.put(PlaybackServerProvider());
  }
}
