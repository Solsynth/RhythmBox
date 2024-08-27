import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/widgets/player/music_queue.dart';

class PlayerQueuePopup extends StatelessWidget {
  const PlayerQueuePopup({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Queue',
            style: Theme.of(context).textTheme.headlineSmall,
          ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
          const Expanded(
            child: PlayerQueue(),
          )
        ],
      ),
    );
  }
}
