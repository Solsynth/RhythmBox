import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/services/duration.dart';
import 'package:rhythm_box/services/server/active_sourced_track.dart';
import 'package:rhythm_box/services/sourced_track/models/source_info.dart';
import 'package:rhythm_box/services/sourced_track/sourced_track.dart';
import 'package:rhythm_box/services/sourced_track/sources/piped.dart';
import 'package:rhythm_box/services/sourced_track/sources/youtube.dart';
import 'package:rhythm_box/widgets/auto_cache_image.dart';
import 'package:rhythm_box/widgets/tracks/querying_track_info.dart';

class SiblingTracks extends StatefulWidget {
  const SiblingTracks({super.key});

  @override
  State<SiblingTracks> createState() => _SiblingTracksState();
}

class _SiblingTracksState extends State<SiblingTracks> {
  late final QueryingTrackInfoProvider _query = Get.find();
  late final ActiveSourcedTrackProvider _activeSource = Get.find();
  late final AudioPlayerProvider _playback = Get.find();

  get _activeTrack =>
      _activeSource.state.value ?? _playback.state.value.activeTrack;

  List<SourceInfo> get _siblings => !_query.isQueryingTrackInfo.value
      ? [
          (_activeTrack as SourcedTrack).sourceInfo,
          ..._activeSource.state.value!.siblings,
        ]
      : [];

  final sourceInfoToLabelMap = {
    YoutubeSourceInfo: 'YouTube',
    PipedSourceInfo: 'Piped',
  };

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListView.builder(
        itemCount: _siblings.length,
        itemBuilder: (context, idx) {
          final item = _siblings[idx];
          final src = sourceInfoToLabelMap[item.runtimeType];
          return ListTile(
            title: Text(
              item.title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: AutoCacheImage(
                item.thumbnail,
                height: 64,
                width: 64,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            trailing: Text(
              item.duration.toHumanReadableString(),
              style: GoogleFonts.robotoMono(),
            ),
            subtitle: Row(
              children: [
                if (src != null) Text(src),
                Expanded(
                  child: Text(
                    ' · ${item.artist}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            enabled: !_query.isQueryingTrackInfo.value,
            tileColor: !_query.isQueryingTrackInfo.value &&
                    item.id == (_activeTrack as SourcedTrack).sourceInfo.id
                ? Theme.of(context).colorScheme.secondaryContainer
                : null,
            onTap: () {
              if (!_query.isQueryingTrackInfo.value &&
                  item.id != (_activeTrack as SourcedTrack).sourceInfo.id) {
                _activeSource.swapSibling(item);
                Navigator.of(context).pop();
              }
            },
          );
        },
      ),
    );
  }
}
