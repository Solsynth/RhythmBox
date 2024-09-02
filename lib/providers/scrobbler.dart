import 'dart:async';
import 'package:drift/drift.dart';
import 'package:get/get.dart' hide Value;
import 'package:rhythm_box/providers/database.dart';
import 'package:rhythm_box/providers/error_notifier.dart';
import 'package:rhythm_box/services/artist.dart';
import 'package:rhythm_box/services/database/database.dart';
import 'package:scrobblenaut/scrobblenaut.dart';
import 'package:spotify/spotify.dart';

class ScrobblerProvider extends GetxController {
  final StreamController<Track> _scrobbleController =
      StreamController<Track>.broadcast();
  final Rxn<Scrobblenaut?> scrobbler = Rxn<Scrobblenaut?>(null);
  late StreamSubscription _databaseSubscription;
  late StreamSubscription _scrobbleSubscription;

  static String apiKey = 'd2a75393e1141d0c9486eb77cc7b8892';
  static String apiSecret = '3ac3a5231a2e8a0dc98577c246101b78';

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    final database = Get.find<DatabaseProvider>().database;

    final loginInfo = await (database.select(database.scrobblerTable)
          ..where((t) => t.id.equals(0)))
        .getSingleOrNull();

    _databaseSubscription =
        database.select(database.scrobblerTable).watch().listen((event) async {
      if (event.isNotEmpty) {
        try {
          scrobbler.value = Scrobblenaut(
            lastFM: await LastFM.authenticateWithPasswordHash(
              apiKey: apiKey,
              apiSecret: apiSecret,
              username: event.first.username,
              passwordHash: event.first.passwordHash.value,
            ),
          );
        } catch (e, stack) {
          Get.find<ErrorNotifier>()
              .logError('[Scrobbler] Error: $e', trace: stack);
          scrobbler.value = null;
        }
      } else {
        scrobbler.value = null;
      }
    });

    _scrobbleSubscription = _scrobbleController.stream.listen((track) async {
      try {
        await scrobbler.value?.track.scrobble(
          artist: track.artists!.first.name!,
          track: track.name!,
          album: track.album!.name!,
          chosenByUser: true,
          duration: track.duration,
          timestamp: DateTime.now().toUtc(),
          trackNumber: track.trackNumber,
        );
      } catch (e, stack) {
        Get.find<ErrorNotifier>()
            .logError('[Scrobbler] Error: $e', trace: stack);
      }
    });

    if (loginInfo == null) {
      scrobbler.value = null;
      return;
    }

    scrobbler.value = Scrobblenaut(
      lastFM: await LastFM.authenticateWithPasswordHash(
        apiKey: apiKey,
        apiSecret: apiSecret,
        username: loginInfo.username,
        passwordHash: loginInfo.passwordHash.value,
      ),
    );
  }

  Future<void> login(String username, String password) async {
    final database = Get.find<DatabaseProvider>().database;

    final lastFm = await LastFM.authenticate(
      apiKey: apiKey,
      apiSecret: apiSecret,
      username: username,
      password: password,
    );

    if (!lastFm.isAuth) throw Exception('Invalid credentials');

    await database.into(database.scrobblerTable).insert(
          ScrobblerTableCompanion.insert(
            id: const Value(0),
            username: username,
            passwordHash: DecryptedText(lastFm.passwordHash!),
          ),
        );

    scrobbler.value = Scrobblenaut(lastFM: lastFm);
  }

  Future<void> logout() async {
    scrobbler.value = null;
    final database = Get.find<DatabaseProvider>().database;
    await database.delete(database.scrobblerTable).go();
  }

  void scrobble(Track track) {
    _scrobbleController.add(track);
  }

  Future<void> love(Track track) async {
    await scrobbler.value?.track.love(
      artist: track.artists!.asString(),
      track: track.name!,
    );
  }

  Future<void> unlove(Track track) async {
    await scrobbler.value?.track.unLove(
      artist: track.artists!.asString(),
      track: track.name!,
    );
  }

  @override
  void onClose() {
    _databaseSubscription.cancel();
    _scrobbleSubscription.cancel();
    _scrobbleController.close();
    super.onClose();
  }
}
