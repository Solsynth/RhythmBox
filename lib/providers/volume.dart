import 'dart:async';
import 'package:get/get.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';
import 'package:rhythm_box/services/kv_store/kv_store.dart';

class VolumeProvider extends GetxController {
  RxDouble volume = KVStoreService.volume.obs;

  @override
  void onInit() {
    super.onInit();
    audioPlayer.setVolume(volume.value);
  }

  Future<void> setVolume(double newVolume) async {
    volume.value = newVolume;
    await audioPlayer.setVolume(newVolume);
    KVStoreService.setVolume(newVolume);
  }
}
