import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/widgets/auto_cache_image.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:spotify/spotify.dart';
import 'package:rhythm_box/services/artist.dart';

class PlayerQueue extends StatefulWidget {
  const PlayerQueue({super.key});

  @override
  State<PlayerQueue> createState() => _PlayerQueueState();
}

class _PlayerQueueState extends State<PlayerQueue> {
  final AutoScrollController _autoScrollController = AutoScrollController();

  final AudioPlayerProvider _playback = Get.find();

  List<Track> get _tracks => _playback.state.value.tracks;

  bool _getIsActiveTrack(Track track) {
    return track.id == _playback.state.value.activeTrack!.id;
  }

  @override
  void initState() {
    super.initState();
    if (_playback.state.value.activeTrack != null) {
      final idx = _tracks
          .indexWhere((x) => x.id == _playback.state.value.activeTrack!.id);
      if (idx != -1) {
        _autoScrollController.scrollToIndex(
          idx,
          preferPosition: AutoScrollPosition.middle,
        );
      }
    }
  }

  @override
  void dispose() {
    _autoScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Obx(
        () => CustomScrollView(
          controller: _autoScrollController,
          slivers: [
            SliverReorderableList(
              itemCount: _tracks.length,
              onReorder: (prev, now) async {
                _playback.moveTrack(prev, now);
              },
              itemBuilder: (context, idx) {
                final item = _tracks[idx];
                return AutoScrollTag(
                  key: ValueKey<int>(idx),
                  controller: _autoScrollController,
                  index: idx,
                  child: Material(
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: idx,
                          child: const Icon(Icons.drag_indicator).paddingOnly(
                            left: 8,
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            tileColor: _getIsActiveTrack(item)
                                ? Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer
                                : null,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                            ),
                            contentPadding: const EdgeInsets.only(
                              left: 8,
                              right: 24,
                            ),
                            leading: ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(8)),
                              child: AutoCacheImage(
                                item.album!.images!.first.url!,
                                width: 64.0,
                                height: 64.0,
                              ),
                            ),
                            title: Text(item.name ?? 'Loading...'),
                            subtitle: Text(
                              item.artists?.asString() ?? 'Please stand by...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              _playback.jumpToTrack(item);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
