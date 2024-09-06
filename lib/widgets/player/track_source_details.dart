import 'package:flutter/material.dart';
import 'package:rhythm_box/services/duration.dart';
import 'package:rhythm_box/services/sourced_track/sourced_track.dart';
import 'package:rhythm_box/services/sourced_track/sources/netease.dart';
import 'package:rhythm_box/services/sourced_track/sources/piped.dart';
import 'package:rhythm_box/services/sourced_track/sources/youtube.dart';

class TrackSourceDetails extends StatelessWidget {
  final SourcedTrack track;

  const TrackSourceDetails({super.key, required this.track});

  static final sourceInfoToLabelMap = {
    YoutubeSourceInfo: 'YouTube',
    PipedSourceInfo: 'Piped',
    NeteaseSourceInfo: 'Netease',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final detailsMap = {
      'Title': track.name!,
      'Artist': track.artists?.map((x) => x.name).join(', '),
      'Album': track.album!.name!,
      'Duration': track.sourceInfo.duration.toHumanReadableString(),
      if (track.album!.releaseDate != null)
        'Released': track.album!.releaseDate,
      'Popularity': track.popularity?.toString() ?? '0',
      'Provider': sourceInfoToLabelMap[track.sourceInfo.runtimeType],
    };

    return Table(
      columnWidths: const {
        0: FixedColumnWidth(95),
        1: FixedColumnWidth(10),
        2: FlexColumnWidth(1),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (final entry in detailsMap.entries)
          TableRow(
            children: [
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.top,
                child: Text(
                  entry.key,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const TableCell(
                verticalAlignment: TableCellVerticalAlignment.top,
                child: Text(':'),
              ),
              if (entry.value is Widget)
                entry.value as Widget
              else if (entry.value is String)
                Text(
                  entry.value as String,
                  style: theme.textTheme.bodyMedium,
                )
              else
                const Text('Unknown'),
            ],
          ),
      ],
    );
  }
}
