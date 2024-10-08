import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';
import 'package:rhythm_box/services/local_track.dart';
import 'package:rhythm_box/services/sourced_track/sourced_track.dart';
import 'package:rhythm_box/widgets/tracks/querying_track_info.dart';
import 'package:spotify/spotify.dart';

class SourcedTrackProvider extends GetxController {
  Rx<SourcedTrack?> sourcedTrack = Rx(null);

  Future<SourcedTrack?> fetch(RhythmMedia? media) async {
    final track = media?.track;
    if (track == null || track is LocalTrack) {
      sourcedTrack.value = null;
      return null;
    }

    final AudioPlayerProvider playback = Get.find();
    final QueryingTrackInfoProvider query = Get.find();

    ever(playback.state.value.tracks.obs, (List<Track> tracks) {
      if (tracks.isEmpty || tracks.none((element) => element.id == track.id)) {
        invalidate();
      }
    });

    final isCurrentTrack = playback.state.value.activeTrack?.id == track.id;

    if (isCurrentTrack) query.isQueryingTrackInfo.value = true;

    sourcedTrack.value = await SourcedTrack.fetchFromTrack(track: track);

    query.isQueryingTrackInfo.value = false;

    return sourcedTrack.value;
  }

  void invalidate() {
    sourcedTrack.value = null;
    fetch(null);
  }
}
