import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/widgets/tracks/track_tile.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:spotify/spotify.dart';

class PlaylistTrackList extends StatelessWidget {
  final String playlistId;
  final List<Track>? tracks;

  final bool isLoading;

  const PlaylistTrackList({
    super.key,
    this.isLoading = false,
    required this.playlistId,
    required this.tracks,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.sliver(
      enabled: isLoading,
      child: SliverList.builder(
        itemCount: tracks?.length ?? 3,
        itemBuilder: (context, idx) {
          final item = tracks?[idx];
          return TrackTile(
            item: item,
            onTap: () {
              if (item == null) return;
              Get.find<AudioPlayerProvider>()
                ..load(
                  tracks!,
                  initialIndex: idx,
                  autoPlay: true,
                )
                ..addCollection(playlistId);
            },
          );
        },
      ),
    );
  }
}
