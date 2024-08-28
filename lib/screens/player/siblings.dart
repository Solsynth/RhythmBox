import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/widgets/player/sibling_tracks.dart';

class SiblingTracksPopup extends StatelessWidget {
  const SiblingTracksPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alternative Sources',
            style: Theme.of(context).textTheme.headlineSmall,
          ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
          const Expanded(
            child: SiblingTracks(),
          )
        ],
      ),
    );
  }
}
