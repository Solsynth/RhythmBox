import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/services/artist.dart';
import 'package:spotify/spotify.dart';

class PlayerTrackDetails extends StatelessWidget {
  final Color? color;
  final Track? track;
  const PlayerTrackDetails({super.key, this.color, this.track});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AudioPlayerProvider playback = Get.find();

    return Row(
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              InkWell(
                child: Text(
                  playback.state.value.activeTrack?.name ?? 'Not playing',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: color,
                  ),
                ),
                onTap: () {
                  // TODO Push to track page
                },
              ),
              Text(
                playback.state.value.activeTrack?.artists?.asString() ??
                    'No author',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall!.copyWith(color: color),
              )
            ],
          ),
        ),
      ],
    );
  }
}
