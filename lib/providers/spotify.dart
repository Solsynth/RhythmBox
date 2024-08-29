import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:rhythm_box/providers/auth.dart';
import 'package:spotify/spotify.dart';

class SpotifyProvider extends GetxController {
  late SpotifyApi api;

  List<StreamSubscription>? _subscriptions;

  @override
  void onInit() {
    final AuthenticationProvider authenticate = Get.find();
    if (authenticate.auth.value == null) {
      api = _initApiWithClientCredentials();
    } else {
      api = _initApiWithUserCredentials();
    }
    _subscriptions = [
      authenticate.auth.listen((value) {
        if (value == null) {
          api = _initApiWithClientCredentials();
        } else {
          api = _initApiWithUserCredentials();
        }
      }),
    ];
    super.onInit();
  }

  SpotifyApi _initApiWithClientCredentials() {
    log('[SpotifyApi] Using client credentials...');
    return SpotifyApi(
      SpotifyApiCredentials(
        'f73d4bff91d64d89be9930036f553534',
        '5cbec0b928d247cd891d06195f07b8c9',
      ),
    );
  }

  SpotifyApi _initApiWithUserCredentials() {
    log('[SpotifyApi] Using user credentials...');
    final AuthenticationProvider authenticate = Get.find();
    return SpotifyApi.withAccessToken(
        authenticate.auth.value!.accessToken.value);
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
}
