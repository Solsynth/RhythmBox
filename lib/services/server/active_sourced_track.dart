import 'package:get/get.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/providers/error_notifier.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';
import 'package:rhythm_box/services/sourced_track/models/source_info.dart';
import 'package:rhythm_box/services/sourced_track/sourced_track.dart';
import 'package:rhythm_box/widgets/tracks/querying_track_info.dart';

class ActiveSourcedTrackProvider extends GetxController {
  Rx<SourcedTrack?> state = Rx(null);

  void updateTrack(SourcedTrack? sourcedTrack) {
    state.value = sourcedTrack;
  }

  Future<void> populateSibling() async {
    if (state.value == null) return;
    state.value = await state.value!.copyWithSibling();
  }

  Future<void> swapSibling(SourceInfo sibling) async {
    final query = Get.find<QueryingTrackInfoProvider>();
    query.isQueryingTrackInfo.value = true;

    try {
      if (state.value == null) return;
      await audioPlayer.pause();
      await populateSibling();
      final newTrack = await state.value!.swapWithSibling(sibling);
      if (newTrack == null) return;

      state.value = newTrack;

      final playback = Get.find<AudioPlayerProvider>();
      final oldActiveIndex = audioPlayer.currentIndex;

      await playback.addTracksAtFirst([newTrack]);
      await Future.delayed(const Duration(milliseconds: 30));

      await audioPlayer.removeTrack(oldActiveIndex);
      await playback.jumpToTrack(newTrack);
    } catch (e, stack) {
      Get.find<ErrorNotifier>().logError(
          '[Playback] Failed to swap with siblings. Error: $e',
          trace: stack);
    } finally {
      query.isQueryingTrackInfo.value = false;
      await audioPlayer.resume();
    }
  }
}
