import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/widgets/auto_cache_image.dart';
import 'package:spotify/spotify.dart';
import 'package:rhythm_box/services/artist.dart';

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
        return ListTile(
          leading: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: AutoCacheImage(
              item.album!.images!.first.url!,
              width: 64.0,
              height: 64.0,
            ),
          ),
          title: Text(item.name ?? 'Loading...'),
          subtitle: Text(
            item.artists?.asString() ?? 'Please stand by...',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
