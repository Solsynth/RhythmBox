import 'package:get/get.dart';
import 'package:spotify/spotify.dart';

class SpotifyProvider extends GetxController {
  late final SpotifyApi api;

  @override
  void onInit() {
    api = SpotifyApi(
      SpotifyApiCredentials(
        "f73d4bff91d64d89be9930036f553534",
        "5cbec0b928d247cd891d06195f07b8c9",
      ),
    );
    super.onInit();
  }
}
