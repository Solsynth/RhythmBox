import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';
import 'package:rhythm_box/services/lyrics/model.dart';
import 'package:rhythm_box/services/lyrics/provider.dart';
import 'package:rhythm_box/widgets/sized_container.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class SyncedLyrics extends StatefulWidget {
  final int defaultTextZoom;

  const SyncedLyrics({
    super.key,
    required this.defaultTextZoom,
  });

  @override
  State<SyncedLyrics> createState() => _SyncedLyricsState();
}

class _SyncedLyricsState extends State<SyncedLyrics> {
  late final AudioPlayerProvider _playback = Get.find();
  late final SyncedLyricsProvider _syncedLyrics = Get.find();

  final AutoScrollController _autoScrollController = AutoScrollController();

  late final int _textZoomLevel = widget.defaultTextZoom;

  SubtitleSimple? _lyric;
  String? _activeTrackId;

  bool get _isLyricSynced =>
      _lyric == null ? false : _lyric!.lyrics.any((x) => x.time.inSeconds > 0);

  Future<void> _pullLyrics() async {
    if (_playback.state.value.activeTrack == null) return;
    _activeTrackId = _playback.state.value.activeTrack!.id;
    final out = await _syncedLyrics.fetch(_playback.state.value.activeTrack!);
    setState(() => _lyric = out);
  }

  List<StreamSubscription>? _subscriptions;

  Color get _unFocusColor =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.5);

  void _syncLyricsProgress() {
    for (var idx = 0; idx < _lyric!.lyrics.length; idx++) {
      final lyricSlice = _lyric!.lyrics[idx];
      final lyricNextSlice =
          idx + 1 < _lyric!.lyrics.length ? _lyric!.lyrics[idx + 1] : null;
      final isActive = _playback.durationCurrent.value.inSeconds >=
              lyricSlice.time.inSeconds &&
          (lyricNextSlice == null ||
              lyricNextSlice.time.inSeconds >
                  _playback.durationCurrent.value.inSeconds);
      if (isActive) {
        _autoScrollController.scrollToIndex(
          idx,
          preferPosition: AutoScrollPosition.middle,
        );
        return;
      }
    }

    if (_lyric!.lyrics.isNotEmpty) {
      _autoScrollController.scrollToIndex(
        0,
        preferPosition: AutoScrollPosition.begin,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _pullLyrics().then((_) {
      _syncLyricsProgress();
    });
    _subscriptions = [
      _playback.state.listen((value) {
        if (value.activeTrack == null) return;
        if (value.activeTrack!.id != _activeTrackId) {
          _pullLyrics().then((_) {
            _syncLyricsProgress();
          });
        }
      }),
    ];
  }

  @override
  void dispose() {
    _autoScrollController.dispose();
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

    return CustomScrollView(
      controller: _autoScrollController,
      slivers: [
        if (_lyric == null)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        if (_lyric != null && _lyric!.lyrics.isNotEmpty)
          SliverList.builder(
            itemCount: _lyric!.lyrics.length,
            itemBuilder: (context, idx) => Obx(() {
              final lyricSlice = _lyric!.lyrics[idx];
              final lyricNextSlice = idx + 1 < _lyric!.lyrics.length
                  ? _lyric!.lyrics[idx + 1]
                  : null;
              final isActive = _playback.durationCurrent.value.inSeconds >=
                      lyricSlice.time.inSeconds &&
                  (lyricNextSlice == null ||
                      lyricNextSlice.time.inSeconds >
                          _playback.durationCurrent.value.inSeconds);

              if (_playback.durationCurrent.value.inSeconds ==
                      lyricSlice.time.inSeconds &&
                  _isLyricSynced) {
                _autoScrollController.scrollToIndex(
                  idx,
                  preferPosition: AutoScrollPosition.middle,
                );
              }
              return AutoScrollTag(
                key: ValueKey(idx),
                index: idx,
                controller: _autoScrollController,
                child: lyricSlice.text.isEmpty
                    ? Container(
                        padding: idx == _lyric!.lyrics.length - 1
                            ? EdgeInsets.only(bottom: size.height / 2)
                            : null,
                      )
                    : Padding(
                        padding: idx == _lyric!.lyrics.length - 1
                            ? const EdgeInsets.symmetric(vertical: 8)
                                .copyWith(bottom: 80)
                            : const EdgeInsets.symmetric(vertical: 8),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                            fontWeight:
                                isActive ? FontWeight.w500 : FontWeight.normal,
                            fontSize:
                                (isActive ? 28 : 26) * (_textZoomLevel / 100),
                          ),
                          textAlign: TextAlign.center,
                          child: InkWell(
                            onTap: () async {
                              final time = Duration(
                                seconds: lyricSlice.time.inSeconds -
                                    _syncedLyrics.delay.value,
                              );
                              if (time > audioPlayer.duration ||
                                  time.isNegative) {
                                return;
                              }
                              audioPlayer.seek(time);
                            },
                            child: Builder(builder: (context) {
                              return AnimatedDefaultTextStyle(
                                style: TextStyle(
                                  fontSize: isActive ? 20 : 16,
                                  color: isActive
                                      ? Theme.of(context).colorScheme.onSurface
                                      : _unFocusColor,
                                ),
                                duration: 500.ms,
                                curve: Curves.easeInOut,
                                child: Text(
                                  lyricSlice.text,
                                  textAlign:
                                      MediaQuery.of(context).size.width >= 720
                                          ? TextAlign.center
                                          : TextAlign.left,
                                ),
                              );
                            }).paddingSymmetric(horizontal: 24),
                          ),
                        ),
                      ),
              );
            }),
          )
        else if (_lyric != null && _lyric!.lyrics.isEmpty)
          SliverFillRemaining(
            child: CenteredContainer(
              maxWidth: 280,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lyrics Not Found',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const Text(
                    "This song haven't lyrics that recorded in our database.",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
