import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/providers/history.dart';
import 'package:rhythm_box/providers/spotify.dart';
import 'package:rhythm_box/services/artist.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';
import 'package:rhythm_box/services/track.dart';
import 'package:rhythm_box/widgets/auto_cache_image.dart';
import 'package:rhythm_box/widgets/sized_container.dart';
import 'package:rhythm_box/widgets/tracks/playlist_track_list.dart';
import 'package:spotify/spotify.dart';

class AlbumViewScreen extends StatefulWidget {
  final String albumId;
  final Playlist? playlist;

  const AlbumViewScreen({
    super.key,
    required this.albumId,
    this.playlist,
  });

  @override
  State<AlbumViewScreen> createState() => _AlbumViewScreenState();
}

class _AlbumViewScreenState extends State<AlbumViewScreen> {
  late final SpotifyProvider _spotify = Get.find();
  late final AudioPlayerProvider _playback = Get.find();

  bool get _isCurrentPlaylist => _album != null
      ? _playback.state.value.containsCollection(_album!.id!)
      : false;

  bool _isLoading = true;
  bool _isLoadingTracks = true;
  bool _isUpdating = false;

  Album? _album;
  List<Track>? _tracks;

  Future<void> _pullPlaylist() async {
    _album = await _spotify.api.albums.get(widget.albumId);
    setState(() => _isLoading = false);
  }

  Future<void> _pullTracks() async {
    _tracks = (await _spotify.api.albums.tracks(widget.albumId).all())
        .map((x) => x.asTrack(_album!))
        .toList();
    setState(() => _isLoadingTracks = false);
  }

  @override
  void initState() {
    super.initState();
    _pullPlaylist();
    _pullTracks();
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(8));

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Playlist'),
          centerTitle: MediaQuery.of(context).size.width >= 720,
        ),
        body: Builder(
          builder: (context) {
            if (_isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return CenteredContainer(
              child: CustomScrollView(
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
                                child: (_album?.images?.isNotEmpty ?? false)
                                    ? AutoCacheImage(
                                        _album!.images!.first.url!,
                                        width: 160.0,
                                        height: 160.0,
                                      )
                                    : const SizedBox(
                                        width: 160,
                                        height: 160,
                                        child: Icon(Icons.image),
                                      ),
                              ),
                            ),
                            const Gap(24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _album!.name ?? 'Playlist',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.fade,
                                  ),
                                  Text(
                                    _album!.artists?.asString() ?? 'A Playlist',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Gap(8),
                                  Text(
                                    "${NumberFormat.compactCurrency(symbol: '', decimalDigits: 2).format(_album!.popularity ?? 0)} views",
                                  ),
                                  Text(
                                    '#${_album!.id}',
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
                            Obx(
                              () => ElevatedButton.icon(
                                icon: (_isCurrentPlaylist &&
                                        _playback.isPlaying.value)
                                    ? const Icon(Icons.pause_outlined)
                                    : const Icon(Icons.play_arrow),
                                label: const Text('Play'),
                                onPressed: _isUpdating
                                    ? null
                                    : () async {
                                        if (_isCurrentPlaylist &&
                                            _playback.isPlaying.value) {
                                          audioPlayer.pause();
                                          return;
                                        } else if (_isCurrentPlaylist &&
                                            !_playback.isPlaying.value) {
                                          audioPlayer.resume();
                                          return;
                                        }

                                        setState(() => _isUpdating = true);

                                        await _playback.load(_tracks!,
                                            autoPlay: true);
                                        _playback.addCollection(_album!.id!);
                                        Get.find<PlaybackHistoryProvider>()
                                            .addAlbums([_album!]);

                                        setState(() => _isUpdating = false);
                                      },
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.shuffle),
                              label: const Text('Shuffle'),
                              onPressed: _isUpdating
                                  ? null
                                  : () async {
                                      setState(() => _isUpdating = true);

                                      audioPlayer.setShuffle(true);

                                      await _playback.load(
                                        _tracks!,
                                        autoPlay: true,
                                        initialIndex:
                                            Random().nextInt(_tracks!.length),
                                      );
                                      _playback.addCollection(_album!.id!);
                                      Get.find<PlaybackHistoryProvider>()
                                          .addAlbums([_album!]);

                                      setState(() => _isUpdating = false);
                                    },
                            ),
                          ],
                        ).paddingSymmetric(horizontal: 24),
                        const Gap(24),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Text(
                      'Songs (${_tracks?.length ?? 0})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ).paddingOnly(left: 28, right: 28, bottom: 4),
                  ),
                  PlaylistTrackList(
                    isLoading: _isLoadingTracks,
                    playlistId: widget.albumId,
                    tracks: _tracks,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
