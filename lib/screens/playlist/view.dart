import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rhythm_box/providers/spotify.dart';
import 'package:rhythm_box/widgets/auto_cache_image.dart';
import 'package:rhythm_box/widgets/tracks/playlist_track_list.dart';
import 'package:spotify/spotify.dart';

class PlaylistViewScreen extends StatefulWidget {
  final String playlistId;
  final Playlist? playlist;

  const PlaylistViewScreen({
    super.key,
    required this.playlistId,
    this.playlist,
  });

  @override
  State<PlaylistViewScreen> createState() => _PlaylistViewScreenState();
}

class _PlaylistViewScreenState extends State<PlaylistViewScreen> {
  late final SpotifyProvider _spotify = Get.find();

  bool _isLoading = true;

  Playlist? _playlist;

  Future<void> _pullPlaylist() async {
    _playlist = await _spotify.api.playlists.get(widget.playlistId);
    setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    _pullPlaylist();
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(8));

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Playlist'),
        ),
        body: Builder(
          builder: (context) {
            if (_isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Material(
                            borderRadius: radius,
                            elevation: 2,
                            child: ClipRRect(
                              borderRadius: radius,
                              child: Hero(
                                tag: Key('playlist-cover-${_playlist!.id}'),
                                child: AutoCacheImage(
                                  _playlist!.images!.first.url!,
                                  width: 160.0,
                                  height: 160.0,
                                ),
                              ),
                            ),
                          ),
                          const Gap(24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _playlist!.name ?? 'Playlist',
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.fade,
                                ),
                                Text(
                                  _playlist!.description ?? 'A Playlist',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Gap(8),
                                Text(
                                  "${NumberFormat.compactCurrency(symbol: '', decimalDigits: 2).format(_playlist!.followers!.total!)} saves",
                                ),
                                Text(
                                  '#${_playlist!.id}',
                                  style: GoogleFonts.robotoMono(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ).paddingOnly(left: 24, right: 24, top: 24),
                      const Gap(8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow_outlined),
                            label: const Text('Play'),
                            onPressed: () {},
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.shuffle),
                            label: const Text('Shuffle'),
                            onPressed: () {},
                          ),
                        ],
                      ).paddingSymmetric(horizontal: 24),
                      const Gap(24),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Text(
                    'Songs (${_playlist!.tracks!.total})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ).paddingOnly(left: 28, right: 28, bottom: 4),
                ),
                PlaylistTrackList(playlistId: widget.playlistId),
              ],
            );
          },
        ),
      ),
    );
  }
}
