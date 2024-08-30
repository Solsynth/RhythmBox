import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_box/platform.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/services/audio_services/image.dart';
import 'package:rhythm_box/widgets/auto_cache_image.dart';
import 'package:rhythm_box/widgets/player/controls.dart';
import 'package:rhythm_box/widgets/player/devices.dart';
import 'package:rhythm_box/widgets/player/track_details.dart';
import 'package:rhythm_box/widgets/tracks/querying_track_info.dart';
import 'package:rhythm_box/widgets/volume_slider.dart';
import 'package:window_manager/window_manager.dart';

class BottomPlayer extends StatefulWidget {
  final bool usePop;
  final bool isMiniPlayer;
  final Function? onTap;

  const BottomPlayer({
    super.key,
    this.usePop = false,
    this.isMiniPlayer = false,
    this.onTap,
  });

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

  bool get _isFetchingActiveTrack => _query.isQueryingTrackInfo.value;

  String? get _albumArt =>
      (_playback.state.value.activeTrack?.album?.images).asUrlString(
        index:
            (_playback.state.value.activeTrack?.album?.images?.length ?? 1) - 1,
      );

  List<StreamSubscription>? _subscriptions;

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
    return SizeTransition(
      sizeFactor: _animation,
      axis: Axis.vertical,
      axisAlignment: -1,
      child: Obx(
        () => GestureDetector(
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0,
                  end: _playback.durationCurrent.value.inMilliseconds /
                      max(_playback.durationTotal.value.inMilliseconds, 1),
                ),
                duration: const Duration(milliseconds: 1000),
                builder: (context, value, _) => LinearProgressIndicator(
                  minHeight: 3,
                  value: _isFetchingActiveTrack ? null : null,
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
                    const Expanded(child: PlayerControls())
                  else
                    const PlayerControls(),
                  if (MediaQuery.of(context).size.width >= 720) const Gap(12),
                  if (MediaQuery.of(context).size.width >= 720)
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.speaker, size: 18),
                            onPressed: () {
                              showModalBottomSheet(
                                useRootNavigator: true,
                                context: context,
                                builder: (context) => const PlayerDevicePopup(),
                              );
                            },
                          ),
                          if (!widget.isMiniPlayer && PlatformInfo.isDesktop)
                            IconButton(
                              icon: const Icon(
                                Icons.picture_in_picture,
                                size: 18,
                              ),
                              onPressed: () async {
                                if (!PlatformInfo.isDesktop) return;

                                final prevSize = await windowManager.getSize();
                                await windowManager.setMinimumSize(
                                  const Size(300, 300),
                                );
                                await windowManager.setAlwaysOnTop(true);
                                if (!PlatformInfo.isLinux) {
                                  await windowManager.setHasShadow(false);
                                }
                                await windowManager
                                    .setAlignment(Alignment.topRight);
                                await windowManager
                                    .setSize(const Size(400, 500));
                                await Future.delayed(
                                  const Duration(milliseconds: 100),
                                  () async {
                                    GoRouter.of(context).pushNamed(
                                      'playerMini',
                                      extra: prevSize,
                                    );
                                  },
                                );
                              },
                            ),
                          const VolumeSlider(
                            mainAxisAlignment: MainAxisAlignment.end,
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
            if (widget.onTap != null) {
              widget.onTap!();
              return;
            }
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
