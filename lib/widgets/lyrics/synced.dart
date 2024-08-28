import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';
import 'package:rhythm_box/services/lyrics/model.dart';
import 'package:rhythm_box/services/lyrics/provider.dart';
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
  late Duration _durationCurrent = audioPlayer.position;

  SubtitleSimple? _lyric;

  bool get _isLyricSynced =>
      _lyric == null ? false : _lyric!.lyrics.any((x) => x.time.inSeconds > 0);

  Future<void> _pullLyrics() async {
    if (_playback.state.value.activeTrack == null) return;
    final out = await _syncedLyrics.fetch(_playback.state.value.activeTrack!);
    setState(() => _lyric = out);
  }

  List<StreamSubscription>? _subscriptions;

  Color get _unFocusColor =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.75);

  @override
  void initState() {
    super.initState();
    _subscriptions = [
      audioPlayer.positionStream
          .listen((dur) => setState(() => _durationCurrent = dur)),
    ];
    _pullLyrics();
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
        if (_lyric != null && _lyric!.lyrics.isNotEmpty)
          SliverList.builder(
            itemCount: _lyric!.lyrics.length,
            itemBuilder: (context, idx) {
              final lyricSlice = _lyric!.lyrics[idx];
              final lyricNextSlice = idx + 1 < _lyric!.lyrics.length
                  ? _lyric!.lyrics[idx + 1]
                  : null;
              final isActive =
                  _durationCurrent.inSeconds >= lyricSlice.time.inSeconds &&
                      (lyricNextSlice == null ||
                          lyricNextSlice.time.inSeconds >
                              _durationCurrent.inSeconds);

              if (_durationCurrent.inSeconds == lyricSlice.time.inSeconds &&
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
                            ? const EdgeInsets.all(8.0).copyWith(bottom: 100)
                            : const EdgeInsets.all(8.0),
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
                              return Text(
                                lyricSlice.text,
                                style: TextStyle(
                                  color: isActive
                                      ? Theme.of(context).colorScheme.onSurface
                                      : _unFocusColor,
                                  fontSize: 16,
                                ),
                              ).animate(target: isActive ? 1 : 0).scale(
                                    duration: 300.ms,
                                    begin: const Offset(0.9, 0.9),
                                    end: const Offset(1.3, 1.3),
                                  );
                            }).paddingSymmetric(horizontal: 12),
                          ),
                        ),
                      ),
              );
            },
          ),
      ],
    );
  }
}
