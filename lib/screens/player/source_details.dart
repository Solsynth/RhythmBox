import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/services/server/active_sourced_track.dart';
import 'package:rhythm_box/widgets/player/track_source_details.dart';

class SourceDetailsPopup extends StatelessWidget {
  const SourceDetailsPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final ActiveSourcedTrackProvider activeTrack = Get.find();

    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Source Details',
            style: Theme.of(context).textTheme.headlineSmall,
          ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
          Expanded(
            child: Obx(
              () => TrackSourceDetails(
                track: activeTrack.state.value!,
              ).paddingSymmetric(horizontal: 24),
            ),
          )
        ],
      ),
    );
  }
}
