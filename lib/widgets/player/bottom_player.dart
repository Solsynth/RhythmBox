import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';
import 'package:rhythm_box/services/audio_services/image.dart';
import 'package:rhythm_box/widgets/auto_cache_image.dart';
import 'package:rhythm_box/widgets/player/track_details.dart';
import 'package:rhythm_box/widgets/tracks/querying_track_info.dart';
import 'package:rhythm_box/widgets/volume_slider.dart';

class BottomPlayer extends StatefulWidget {
  final bool usePop;

  const BottomPlayer({super.key, this.usePop = false});

  @override
  State<BottomPlayer> createState() => _BottomPlayerState();
}

class _BottomPlayerState extends State<BottomPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeInOut,
  );

  late final AudioPlayerProvider _playback = Get.find();
  late final QueryingTrackInfoProvider _query = Get.find();

  String? get _albumArt =>
      (_playback.state.value.activeTrack?.album?.images).asUrlString(
        index:
            (_playback.state.value.activeTrack?.album?.images?.length ?? 1) - 1,
      );

  bool get _isPlaying => _playback.isPlaying.value;
  bool get _isFetchingActiveTrack => _query.isQueryingTrackInfo.value;

  List<StreamSubscription>? _subscriptions;

  Future<void> _togglePlayState() async {
    if (!audioPlayer.isPlaying) {
      await audioPlayer.resume();
    } else {
      await audioPlayer.pause();
    }
  }

  bool _isLifted = false;

  @override
  void initState() {
    super.initState();
    _subscriptions = [
      _playback.state.listen((state) {
        if (state.playlist.medias.isNotEmpty && !_isLifted) {
          _animationController.animateTo(1);
          _isLifted = true;
        }
      }),
      _playback.isPlaying.listen((value) {
        if (value && !_isLifted) {
          _animationController.animateTo(1);
          _isLifted = true;
        }
      }),
      _query.isQueryingTrackInfo.listen((value) {
        if (value && !_isLifted) {
          _animationController.animateTo(1);
          _isLifted = true;
        }
      }),
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
    final controls = Obx(
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
            icon: _isFetchingActiveTrack
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                    ),
                  )
                : Icon(
                    !_isPlaying ? Icons.play_arrow : Icons.pause,
                  ),
            onPressed: _isFetchingActiveTrack ? null : _togglePlayState,
          ),
          if (MediaQuery.of(context).size.width >= 720)
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: _isFetchingActiveTrack ? null : audioPlayer.skipToNext,
            )
        ],
      ),
    );

    return SizeTransition(
      sizeFactor: _animation,
      axis: Axis.vertical,
      axisAlignment: -1,
      child: Obx(
        () => GestureDetector(
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              if (_playback.durationCurrent.value != Duration.zero)
                TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: _playback.durationCurrent.value.inMilliseconds /
                        max(_playback.durationTotal.value.inMilliseconds, 1),
                  ),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, value, _) => LinearProgressIndicator(
                    minHeight: 3,
                    value: value,
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Hero(
                          tag: const Key('current-active-track-album-art'),
                          child: ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8)),
                            child: _albumArt != null
                                ? AutoCacheImage(
                                    _albumArt!,
                                    width: 64,
                                    height: 64,
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
                        ),
                        const Gap(12),
                        Expanded(
                          child: PlayerTrackDetails(
                            track: _playback.state.value.activeTrack,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(12),
                  if (MediaQuery.of(context).size.width >= 720)
                    Expanded(child: controls)
                  else
                    controls,
                  if (MediaQuery.of(context).size.width >= 720) const Gap(12),
                  if (MediaQuery.of(context).size.width >= 720)
                    const Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: VolumeSlider(
                              mainAxisAlignment: MainAxisAlignment.end,
                            ),
                          )
                        ],
                      ),
                    ),
                  const Gap(12),
                ],
              ).paddingSymmetric(horizontal: 12, vertical: 8),
            ],
          ),
          onTap: () {
            if (widget.usePop) {
              GoRouter.of(context).pop();
            } else {
              GoRouter.of(context).pushNamed('player');
            }
          },
        ),
      ),
    );
  }
}
