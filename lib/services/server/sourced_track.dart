import 'package:get/get.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';
import 'package:rhythm_box/services/local_track.dart';
import 'package:rhythm_box/services/sourced_track/sourced_track.dart';

class SourcedTrackProvider extends GetxController {
  Future<SourcedTrack?> fetch(RhythmMedia? media) async {
    final track = media?.track;
    if (track == null || track is LocalTrack) {
      return null;
    }

    final sourcedTrack = await SourcedTrack.fetchFromTrack(track: track);

    return sourcedTrack;
  }
}
