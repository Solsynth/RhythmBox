import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/providers/spotify.dart';
import 'package:rhythm_box/widgets/auto_cache_image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:spotify/spotify.dart';

class PlaylistTrackList extends StatefulWidget {
  final String playlistId;

  const PlaylistTrackList({super.key, required this.playlistId});

  @override
  State<PlaylistTrackList> createState() => _PlaylistTrackListState();
}

class _PlaylistTrackListState extends State<PlaylistTrackList> {
  late final SpotifyProvider _spotify = Get.find();

  bool _isLoading = true;

  List<Track>? _tracks;

  Future<void> _pullTracks() async {
    _tracks = (await _spotify.api.playlists
            .getTracksByPlaylistId(widget.playlistId)
            .all())
        .toList();
    setState(() => _isLoading = false);
  }

  @override
  void initState() {
    _pullTracks();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.sliver(
      enabled: _isLoading,
      child: SliverList.builder(
        itemCount: _tracks?.length ?? 3,
        itemBuilder: (context, idx) {
          final item = _tracks?[idx];
          return ListTile(
            leading: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: item != null
                  ? AutoCacheImage(
                      item.album!.images!.first.url!,
                      width: 64.0,
                      height: 64.0,
                    )
                  : const SizedBox(
                      width: 64,
                      height: 64,
                      child: Center(
                        child: Icon(Icons.image),
                      ),
                    ),
            ),
            title: Text(item?.name ?? 'Loading...'),
            subtitle: Text(
              item?.artists!.map((x) => x.name!).join(', ') ??
                  'Please stand by...',
            ),
            onTap: () {
              if (item == null) return;
              Get.find<AudioPlayerProvider>().load([item], autoPlay: true);
            },
          );
        },
      ),
    );
  }
}
