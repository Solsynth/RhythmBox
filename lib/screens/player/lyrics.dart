import 'package:flutter/material.dart';
import 'package:rhythm_box/widgets/lyrics/synced.dart';
import 'package:rhythm_box/widgets/player/bottom_player.dart';

class LyricsScreen extends StatelessWidget {
  const LyricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lyrics'),
        ),
        body: const Column(
          children: [
            Expanded(
              child: SyncedLyrics(
                defaultTextZoom: 67,
              ),
            ),
          ],
        ),
        bottomNavigationBar: const SizedBox(
          height: 83,
          child: Material(
            elevation: 2,
            child: BottomPlayer(usePop: true),
          ),
        ),
      ),
    );
  }
}
