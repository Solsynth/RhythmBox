import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/services/server/active_sourced_track.dart';
import 'package:rhythm_box/services/sourced_track/sourced_track.dart';
import 'package:rhythm_box/widgets/player/track_source_details.dart';

class SourceDetailsPopup extends StatelessWidget {
  const SourceDetailsPopup({super.key});

  Future<SourcedTrack?> _pullActiveTrack() async {
    final ActiveSourcedTrackProvider activeSourcedTrack = Get.find();
    return activeSourcedTrack.state.value;
  }

  @override
  Widget build(BuildContext context) {
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
              () => FutureBuilder(
                future: _pullActiveTrack(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return TrackSourceDetails(
                      track: snapshot.data!,
                    );
                  }

                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ).paddingSymmetric(horizontal: 24),
            ),
          )
        ],
      ),
    );
  }
}
