import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/widgets/lyrics/synced_lyrics.dart';
import 'package:rhythm_box/widgets/player/bottom_player.dart';

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
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
        bottomNavigationBar: SizedBox(
          height: 85 + max(MediaQuery.of(context).padding.bottom, 16),
          child: Material(
            elevation: 2,
            child: const BottomPlayer(
              key: Key('lyrics-page-bottom-player'),
              usePop: true,
            ).paddingOnly(
              bottom: max(MediaQuery.of(context).padding.bottom, 16),
            ),
          ),
        ),
      ),
    );
  }
}
