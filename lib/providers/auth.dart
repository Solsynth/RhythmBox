import 'dart:async';
import 'dart:io';

import 'package:dio/io.dart';
import 'package:drift/drift.dart';
import 'package:get/get.dart' hide Value;
import 'package:dio/dio.dart';
import 'package:rhythm_box/providers/database.dart';
import 'package:rhythm_box/services/database/database.dart';

extension ExpirationAuthenticationTableData on AuthenticationTableData {
  bool get isExpired => DateTime.now().isAfter(expiration);

  String? getCookie(String key) => cookie.value
      .split('; ')
      .firstWhereOrNull((c) => c.trim().startsWith('$key='))
      ?.trim()
      .split('=')
      .last
      .replaceAll(';', '');
}

class AuthenticationProvider extends GetxController {
  static final Dio dio = () {
    final dio = Dio();

    (dio.httpClientAdapter as IOHttpClientAdapter)
        .createHttpClient = () => HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return host.endsWith('spotify.com') && port == 443;
      };

    return dio;
  }();

  var auth = Rxn<AuthenticationTableData?>();
  Timer? refreshTimer;

  @override
  void onInit() {
    super.onInit();
    loadAuthenticationData();
  }

  Future<void> loadAuthenticationData() async {
    final database = Get.find<DatabaseProvider>().database;
    final data = await (database.select(database.authenticationTable)
          ..where((s) => s.id.equals(0)))
        .getSingleOrNull();

    auth.value = data;
    _setRefreshTimer();
  }

  void _setRefreshTimer() {
    refreshTimer?.cancel();
    if (auth.value != null && auth.value!.isExpired) {
      refreshCredentials();
    }
    refreshTimer = Timer(
      auth.value!.expiration.difference(DateTime.now()),
      () => refreshCredentials(),
    );
  }

  Future<void> refreshCredentials() async {
    final database = Get.find<DatabaseProvider>().database;
    final refreshedCredentials =
        await credentialsFromCookie(auth.value!.cookie.value);

    await database
        .update(database.authenticationTable)
        .replace(refreshedCredentials);
    loadAuthenticationData(); // Reload data after refreshing
  }

  Future<void> login(String cookie) async {
    final database = Get.find<DatabaseProvider>().database;
    final refreshedCredentials = await credentialsFromCookie(cookie);

    await database
        .into(database.authenticationTable)
        .insert(refreshedCredentials, mode: InsertMode.replace);
    loadAuthenticationData(); // Reload data after login
  }

  Future<AuthenticationTableCompanion> credentialsFromCookie(
      String cookie) async {
    try {
      final spDc = cookie
          .split('; ')
          .firstWhereOrNull((c) => c.trim().startsWith('sp_dc='))
          ?.trim();
      final res = await dio.getUri(
        Uri.parse(
            'https://open.spotify.com/get_access_token?reason=transport&productType=web_player'),
        options: Options(
          headers: {
            'Cookie': spDc ?? '',
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          },
          validateStatus: (status) => true,
        ),
      );
      final body = res.data;

      if ((res.statusCode ?? 500) >= 400) {
        throw Exception(
            "Failed to get access token: ${body['error'] ?? res.statusMessage}");
      }

      return AuthenticationTableCompanion.insert(
        id: const Value(0),
        cookie: DecryptedText("${res.headers["set-cookie"]?.join(";")}; $spDc"),
        accessToken: DecryptedText(body['accessToken']),
        expiration: DateTime.fromMillisecondsSinceEpoch(
            body['accessTokenExpirationTimestampMs']),
      );
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> logout() async {
    auth.value = null;
    final database = Get.find<DatabaseProvider>().database;
    await (database.delete(database.authenticationTable)
          ..where((s) => s.id.equals(0)))
        .go();
    // Additional cleanup if necessary
  }

  @override
  void onClose() {
    refreshTimer?.cancel();
    super.onClose();
  }
}
