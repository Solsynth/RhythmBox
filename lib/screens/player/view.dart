import 'dart:async';

import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/services/artist.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';
import 'package:rhythm_box/widgets/auto_cache_image.dart';
import 'package:rhythm_box/services/audio_services/image.dart';
import 'package:rhythm_box/widgets/tracks/querying_track_info.dart';

class PlayerScreen extends StatefulWidget {
  final Duration durationCurrent, durationTotal, durationBuffered;

  const PlayerScreen({
    super.key,
    required this.durationCurrent,
    required this.durationTotal,
    required this.durationBuffered,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final AudioPlayerProvider _playback = Get.find();
  late final QueryingTrackInfoProvider _query = Get.find();

  String? get _albumArt =>
      (_playback.state.value.activeTrack?.album?.images).asUrlString(
        index:
            (_playback.state.value.activeTrack?.album?.images?.length ?? 1) - 1,
      );

  bool get _isPlaying => _playback.isPlaying.value;
  bool get _isFetchingActiveTrack => _query.isQueryingTrackInfo.value;

  double _bufferProgress = 0;

  Duration _durationCurrent = Duration.zero;
  Duration _durationTotal = Duration.zero;

  void _updateDurationCurrent(Duration dur) {
    setState(() => _durationCurrent = dur);
  }

  void _updateDurationTotal(Duration dur) {
    setState(() => _durationTotal = dur);
  }

  List<StreamSubscription>? _subscriptions;

  Future<void> _togglePlayState() async {
    if (!audioPlayer.isPlaying) {
      await audioPlayer.resume();
    } else {
      await audioPlayer.pause();
    }
    setState(() {});
  }

  String _formatDuration(Duration duration) {
    String negativeSign = duration.isNegative ? '-' : '';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.abs());
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return '$negativeSign$twoDigitMinutes:$twoDigitSeconds';
  }

  double? _draggingValue;

  @override
  void initState() {
    super.initState();
    _durationCurrent = widget.durationCurrent;
    _durationTotal = widget.durationTotal;
    _bufferProgress = widget.durationBuffered.inMilliseconds.toDouble();
    _subscriptions = [
      audioPlayer.durationStream
          .listen((dur) => setState(() => _durationTotal = dur)),
      audioPlayer.positionStream
          .listen((dur) => setState(() => _durationCurrent = dur)),
      audioPlayer.bufferedPositionStream.listen((dur) =>
          setState(() => _bufferProgress = dur.inMilliseconds.toDouble())),
    ];
  }

  @override
  void dispose() {
    if (_subscriptions != null) {
      for (final subscription in _subscriptions!) {
        subscription.cancel();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return DismissiblePage(
      backgroundColor: Theme.of(context).colorScheme.surface,
      onDismissed: () {
        Navigator.of(context).pop();
      },
      direction: DismissiblePageDismissDirection.down,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: const Key('current-active-track-album-art'),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _albumArt != null
                        ? AutoCacheImage(
                            _albumArt!,
                            width: size.width,
                            height: size.width,
                          )
                        : Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHigh,
                            width: 64,
                            height: 64,
                            child: const Center(child: Icon(Icons.image)),
                          ),
                  ),
                ).marginSymmetric(horizontal: 24),
              ),
              const Gap(24),
              Text(
                _playback.state.value.activeTrack?.name ?? 'Not playing',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                _playback.state.value.activeTrack?.artists?.asString() ??
                    'No author',
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
              const Gap(24),
              Column(
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
                      secondaryTrackValue: _bufferProgress.abs(),
                      value: _draggingValue?.abs() ??
                          (_durationCurrent.inMilliseconds <=
                                  _durationTotal.inMilliseconds
                              ? _durationCurrent.inMilliseconds.toDouble().abs()
                              : 0),
                      min: 0,
                      max: _durationTotal.inMilliseconds.abs().toDouble(),
                      onChanged: (value) {
                        setState(() => _draggingValue = value);
                      },
                      onChangeEnd: (value) {
                        print('Seek to $value ms');
                        audioPlayer.seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_durationCurrent),
                        style: GoogleFonts.robotoMono(fontSize: 12),
                      ),
                      Text(
                        _formatDuration(_durationTotal),
                        style: GoogleFonts.robotoMono(fontSize: 12),
                      ),
                    ],
                  ).paddingSymmetric(horizontal: 8, vertical: 4),
                ],
              ).paddingSymmetric(horizontal: 24),
              const Gap(24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
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
                              !_isPlaying ? Icons.play_arrow : Icons.pause,
                              size: 28,
                            ),
                      onPressed:
                          _isFetchingActiveTrack ? null : _togglePlayState,
                    ),
                  ),
                ],
              )
            ],
          ),
        ).marginAll(24),
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
