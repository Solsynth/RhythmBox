import 'dart:async';
import 'dart:math';

import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/screens/player/view.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';
import 'package:rhythm_box/services/audio_services/image.dart';
import 'package:rhythm_box/widgets/auto_cache_image.dart';
import 'package:rhythm_box/widgets/player/track_details.dart';
import 'package:rhythm_box/widgets/tracks/querying_track_info.dart';

class BottomPlayer extends StatefulWidget {
  const BottomPlayer({super.key});

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

  Duration _durationCurrent = Duration.zero;
  Duration _durationTotal = Duration.zero;
  Duration _durationBuffered = Duration.zero;

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
  }

  bool _isLifted = false;

  @override
  void initState() {
    super.initState();
    _subscriptions = [
      audioPlayer.durationStream
          .listen((dur) => setState(() => _durationTotal = dur)),
      audioPlayer.positionStream
          .listen((dur) => setState(() => _durationCurrent = dur)),
      audioPlayer.bufferedPositionStream
          .listen((dur) => setState(() => _durationBuffered = dur)),
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
    return SizeTransition(
      sizeFactor: _animation,
      axis: Axis.vertical,
      axisAlignment: -1,
      child: Obx(
        () => GestureDetector(
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              if (_durationCurrent != Duration.zero)
                TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: _durationCurrent.inMilliseconds /
                        max(_durationTotal.inMilliseconds, 1),
                  ),
                  duration: const Duration(milliseconds: 100),
                  builder: (context, value, _) => LinearProgressIndicator(
                    minHeight: 3,
                    value: value,
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Hero(
                    tag: const Key('current-active-track-album-art'),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      child: _albumArt != null
                          ? AutoCacheImage(_albumArt!, width: 64, height: 64)
                          : Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHigh,
                              width: 64,
                              height: 64,
                              child: const Center(child: Icon(Icons.image)),
                            ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: PlayerTrackDetails(
                      track: _playback.state.value.activeTrack,
                    ),
                  ),
                  const Gap(12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
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
                        onPressed:
                            _isFetchingActiveTrack ? null : _togglePlayState,
                      ),
                    ],
                  ),
                  const Gap(12),
                ],
              ).paddingSymmetric(horizontal: 12, vertical: 8),
            ],
          ),
          onTap: () {
            context.pushTransparentRoute(PlayerScreen(
              durationCurrent: _durationCurrent,
              durationTotal: _durationTotal,
              durationBuffered: _durationBuffered,
            ));
          },
        ),
      ),
    );
  }
}
