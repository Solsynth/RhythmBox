import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/user_preferences.dart';
import 'package:rhythm_box/widgets/lyrics/synced_lyrics.dart';
import 'package:rhythm_box/widgets/player/bottom_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  late final UserPreferencesProvider _preferences = Get.find();

  @override
  void activate() {
    super.activate();
    if (_preferences.state.value.playerWakelock) {
      WakelockPlus.enable();
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    WakelockPlus.disable();
  }

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
