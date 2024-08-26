import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_box/platform.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';

class PlayPauseIntent extends Intent {
  const PlayPauseIntent();
}

class PlayPauseAction extends Action<PlayPauseIntent> {
  @override
  invoke(intent) async {
    if (!audioPlayer.isPlaying) {
      await audioPlayer.resume();
    } else {
      await audioPlayer.pause();
    }
    return null;
  }
}

class NavigationIntent extends Intent {
  final GoRouter router;
  final String path;
  const NavigationIntent(this.router, this.path);
}

class NavigationAction extends Action<NavigationIntent> {
  @override
  invoke(intent) {
    intent.router.go(intent.path);
    return null;
  }
}

enum HomeTabs {
  browse,
  search,
  library,
  lyrics,
}

class HomeTabIntent extends Intent {
  final HomeTabs tab;
  const HomeTabIntent({required this.tab});
}

class HomeTabAction extends Action<HomeTabIntent> {
  @override
  invoke(intent) {
    return null;
  }
}

class SeekIntent extends Intent {
  final bool forward;
  const SeekIntent(this.forward);
}

class SeekAction extends Action<SeekIntent> {
  @override
  invoke(intent) async {
    final position = audioPlayer.position.inSeconds;
    await audioPlayer.seek(
      Duration(
        seconds: intent.forward ? position + 5 : position - 5,
      ),
    );
    return null;
  }
}

class CloseAppIntent extends Intent {}

class CloseAppAction extends Action<CloseAppIntent> {
  @override
  invoke(intent) {
    if (PlatformInfo.isDesktop) {
      exit(0);
    } else {
      SystemNavigator.pop();
    }
    return null;
  }
}
