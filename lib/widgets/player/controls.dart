import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';
import 'package:rhythm_box/widgets/tracks/querying_track_info.dart';

class PlayerControls extends StatefulWidget {
  const PlayerControls({super.key});

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  late final AudioPlayerProvider _playback = Get.find();
  late final QueryingTrackInfoProvider _query = Get.find();

  bool get _isPlaying => _playback.isPlaying.value;
  bool get _isFetchingActiveTrack => _query.isQueryingTrackInfo.value;

  Future<void> _togglePlayState() async {
    if (!audioPlayer.isPlaying) {
      await audioPlayer.resume();
    } else {
      await audioPlayer.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MediaQuery.of(context).size.width >= 720
            ? MainAxisAlignment.center
            : MainAxisAlignment.end,
        children: [
          if (MediaQuery.of(context).size.width >= 720)
            IconButton(
              icon: const Icon(Icons.skip_previous),
              onPressed:
                  _isFetchingActiveTrack ? null : audioPlayer.skipToPrevious,
            )
          else
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: _isFetchingActiveTrack ? null : audioPlayer.skipToNext,
            ),
          IconButton.filled(
            icon: (_isFetchingActiveTrack && _isPlaying)
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    !_isPlaying ? Icons.play_arrow : Icons.pause,
                  ),
            onPressed: _togglePlayState,
          ),
          if (MediaQuery.of(context).size.width >= 720)
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: _isFetchingActiveTrack ? null : audioPlayer.skipToNext,
            )
        ],
      ),
    );
  }
}
