import 'dart:async';
import 'dart:math';

import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/providers/auth.dart';
import 'package:rhythm_box/screens/player/queue.dart';
import 'package:rhythm_box/screens/player/siblings.dart';
import 'package:rhythm_box/screens/player/source_details.dart';
import 'package:rhythm_box/services/artist.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';
import 'package:rhythm_box/services/duration.dart';
import 'package:rhythm_box/widgets/auto_cache_image.dart';
import 'package:rhythm_box/services/audio_services/image.dart';
import 'package:rhythm_box/widgets/lyrics/synced_lyrics.dart';
import 'package:rhythm_box/widgets/tracks/heart_button.dart';
import 'package:rhythm_box/widgets/tracks/querying_track_info.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final AudioPlayerProvider _playback = Get.find();
  late final QueryingTrackInfoProvider _query = Get.find();
  late final AuthenticationProvider _auth = Get.find();

  String? get _albumArt =>
      (_playback.state.value.activeTrack?.album?.images).asUrlString(
        index:
            (_playback.state.value.activeTrack?.album?.images?.length ?? 1) - 1,
      );

  bool get _isPlaying => _playback.isPlaying.value;
  bool get _isFetchingActiveTrack => _query.isQueryingTrackInfo.value;
  PlaylistMode get _loopMode => _playback.state.value.loopMode;

  Future<void> _togglePlayState() async {
    if (!audioPlayer.isPlaying) {
      await audioPlayer.resume();
    } else {
      await audioPlayer.pause();
    }
    setState(() {});
  }

  double? _draggingValue;

  static const double maxAlbumSize = 360;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final albumSize = max(size.shortestSide, maxAlbumSize).toDouble();

    final isLargeScreen = size.width >= 720;

    return DismissiblePage(
      backgroundColor: Theme.of(context).colorScheme.surface,
      onDismissed: () {
        Navigator.of(context).pop();
      },
      direction: DismissiblePageDismissDirection.down,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Row(
              children: [
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    children: [
                      Obx(
                        () => Center(
                          child: LimitedBox(
                            maxHeight: maxAlbumSize,
                            maxWidth: maxAlbumSize,
                            child: Hero(
                              tag: const Key('current-active-track-album-art'),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                  child: _albumArt != null
                                      ? AutoCacheImage(
                                          _albumArt!,
                                          width: albumSize,
                                          height: albumSize,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHigh,
                                          width: 64,
                                          height: 64,
                                          child: const Center(
                                            child: Icon(Icons.image),
                                          ),
                                        ),
                                ),
                              ).marginSymmetric(horizontal: 24),
                            ),
                          ),
                        ),
                      ),
                      const Gap(24),
                      Obx(
                        () => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _playback.state.value.activeTrack?.name ??
                                        'Not playing',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                    textAlign: TextAlign.left,
                                  ),
                                  Text(
                                    _playback.state.value.activeTrack?.artists
                                            ?.asString() ??
                                        'No author',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              ),
                            ),
                            if (_playback.state.value.activeTrack != null &&
                                _auth.auth.value != null)
                              TrackHeartButton(
                                key: ValueKey(
                                  _playback.state.value.activeTrack!.id!,
                                ),
                                trackId: _playback.state.value.activeTrack!.id!,
                              ),
                          ],
                        ).paddingSymmetric(horizontal: 32),
                      ),
                      const Gap(24),
                      Obx(
                        () => Column(
                          children: [
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 2,
                                trackShape: _PlayerProgressTrackShape(),
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                ),
                                overlayShape: SliderComponentShape.noOverlay,
                              ),
                              child: Slider(
                                secondaryTrackValue: _playback
                                    .durationBuffered.value.inMilliseconds
                                    .abs()
                                    .toDouble(),
                                value: _draggingValue?.abs() ??
                                    _playback
                                        .durationCurrent.value.inMilliseconds
                                        .toDouble()
                                        .abs(),
                                min: 0,
                                max: max(
                                  _playback.durationCurrent.value.inMilliseconds
                                      .abs(),
                                  _playback.durationTotal.value.inMilliseconds
                                      .abs(),
                                ).toDouble(),
                                onChanged: (value) {
                                  setState(() => _draggingValue = value);
                                },
                                onChangeEnd: (value) {
                                  audioPlayer.seek(
                                    Duration(milliseconds: value.toInt()),
                                  );
                                  setState(() => _draggingValue = null);
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _playback.durationCurrent.value
                                      .toHumanReadableString(),
                                  style: GoogleFonts.robotoMono(fontSize: 12),
                                ),
                                Text(
                                  _playback.durationTotal.value
                                      .toHumanReadableString(),
                                  style: GoogleFonts.robotoMono(fontSize: 12),
                                ),
                              ],
                            ).paddingSymmetric(horizontal: 8, vertical: 4),
                          ],
                        ).paddingSymmetric(horizontal: 24),
                      ),
                      const Gap(24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StreamBuilder<bool>(
                            stream: audioPlayer.shuffledStream,
                            builder: (context, snapshot) {
                              final shuffled = snapshot.data ?? false;
                              return Obx(
                                () => IconButton(
                                  icon: Icon(
                                    shuffled
                                        ? Icons.shuffle_on_outlined
                                        : Icons.shuffle,
                                  ),
                                  onPressed: _isFetchingActiveTrack
                                      ? null
                                      : () {
                                          if (shuffled) {
                                            audioPlayer.setShuffle(false);
                                          } else {
                                            audioPlayer.setShuffle(true);
                                          }
                                        },
                                ),
                              );
                            },
                          ),
                          Obx(
                            () => IconButton(
                              icon: const Icon(Icons.skip_previous),
                              onPressed: _isFetchingActiveTrack
                                  ? null
                                  : audioPlayer.skipToPrevious,
                            ),
                          ),
                          const Gap(8),
                          Obx(
                            () => SizedBox(
                              width: 56,
                              height: 56,
                              child: IconButton.filled(
                                icon: _isFetchingActiveTrack
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Icon(
                                        !_isPlaying
                                            ? Icons.play_arrow
                                            : Icons.pause,
                                        size: 28,
                                      ),
                                onPressed: _togglePlayState,
                              ),
                            ),
                          ),
                          const Gap(8),
                          Obx(
                            () => IconButton(
                              icon: const Icon(Icons.skip_next),
                              onPressed: _isFetchingActiveTrack
                                  ? null
                                  : audioPlayer.skipToNext,
                            ),
                          ),
                          Obx(
                            () => IconButton(
                              icon: Icon(
                                _loopMode == PlaylistMode.none
                                    ? Icons.repeat
                                    : _loopMode == PlaylistMode.loop
                                        ? Icons.repeat_on_outlined
                                        : Icons.repeat_one_on_outlined,
                              ),
                              onPressed: _isFetchingActiveTrack
                                  ? null
                                  : () async {
                                      await audioPlayer.setLoopMode(
                                        switch (_loopMode) {
                                          PlaylistMode.loop =>
                                            PlaylistMode.single,
                                          PlaylistMode.single =>
                                            PlaylistMode.none,
                                          PlaylistMode.none =>
                                            PlaylistMode.loop,
                                        },
                                      );
                                    },
                            ),
                          ),
                        ],
                      ),
                      const Gap(20),
                      Center(
                        child: SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.queue_music),
                                label: const Text(
                                  'Queue',
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    useRootNavigator: true,
                                    isScrollControlled: true,
                                    context: context,
                                    builder: (context) =>
                                        const PlayerQueuePopup(),
                                  ).then((_) {
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  });
                                },
                              ),
                              if (!isLargeScreen) const Gap(4),
                              if (!isLargeScreen)
                                TextButton.icon(
                                  icon: const Icon(Icons.lyrics),
                                  label: const Text(
                                    'Lyrics',
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                  ),
                                  onPressed: () {
                                    GoRouter.of(context)
                                        .pushNamed('playerLyrics');
                                  },
                                ),
                              const Gap(4),
                              TextButton.icon(
                                icon: const Icon(Icons.merge),
                                label: const Text(
                                  'Sources',
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    useRootNavigator: true,
                                    isScrollControlled: true,
                                    context: context,
                                    builder: (context) =>
                                        const SiblingTracksPopup(),
                                  ).then((_) {
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  });
                                },
                              ),
                              const Gap(4),
                              TextButton.icon(
                                label: const Text('Info'),
                                icon: const Icon(Icons.info),
                                onPressed: () {
                                  showModalBottomSheet(
                                    useRootNavigator: true,
                                    context: context,
                                    builder: (context) =>
                                        const SourceDetailsPopup(),
                                  ).then((_) {
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLargeScreen) const Gap(24),
                if (isLargeScreen)
                  const Expanded(
                    child: SyncedLyrics(defaultTextZoom: 67),
                  )
              ],
            ),
          ),
        ).marginSymmetric(horizontal: 24),
      ),
    );
  }
}

class _PlayerProgressTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight!) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
