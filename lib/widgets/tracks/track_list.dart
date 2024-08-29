import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/widgets/tracks/track_tile.dart';
import 'package:spotify/spotify.dart';

class TrackSliverList extends StatelessWidget {
  final List<Track> tracks;

  const TrackSliverList({
    super.key,
    required this.tracks,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: tracks.length,
      itemBuilder: (context, idx) {
        final item = tracks[idx];
        return TrackTile(
          item: item,
          onTap: () {
            Get.find<AudioPlayerProvider>().load(
              [item],
              autoPlay: true,
            );
          },
        );
      },
    );
  }
}
