import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_box/platform.dart';
import 'package:rhythm_box/providers/user_preferences.dart';
import 'package:rhythm_box/screens/player/queue.dart';
import 'package:rhythm_box/screens/player/siblings.dart';
import 'package:rhythm_box/widgets/lyrics/synced_lyrics.dart';
import 'package:rhythm_box/widgets/player/bottom_player.dart';
import 'package:rhythm_box/widgets/player/devices.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

class MiniPlayerScreen extends StatefulWidget {
  final Size prevSize;

  const MiniPlayerScreen({super.key, required this.prevSize});

  @override
  State<MiniPlayerScreen> createState() => _MiniPlayerScreenState();
}

class _MiniPlayerScreenState extends State<MiniPlayerScreen> {
  late final UserPreferencesProvider _preferences = Get.find();

  bool _wasMaximized = false;

  bool _areaActive = false;
  bool _isHoverMode = true;

  void _exitMiniPlayer() async {
    if (!PlatformInfo.isDesktop) return;

    try {
      await windowManager.setMinimumSize(const Size(300, 700));
      await windowManager.setAlwaysOnTop(false);
      if (_wasMaximized) {
        await windowManager.maximize();
      } else {
        await windowManager.setSize(widget.prevSize);
      }
      await windowManager.setAlignment(Alignment.center);
      if (!PlatformInfo.isLinux) {
        await windowManager.setHasShadow(true);
      }
      await Future.delayed(const Duration(milliseconds: 200));
    } finally {
      if (context.mounted) {
        if (GoRouter.of(context).canPop()) {
          GoRouter.of(context).pop();
        } else {
          GoRouter.of(context).replaceNamed('player');
        }
      }
    }
  }

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
  void initState() {
    super.initState();
    if (PlatformInfo.isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _wasMaximized = await windowManager.isMaximized();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: !_isHoverMode
          ? null
          : (event) {
              setState(() => _areaActive = true);
            },
      onExit: !_isHoverMode
          ? null
          : (event) {
              setState(() => _areaActive = false);
            },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _areaActive
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              secondChild: const SizedBox(),
              firstChild: Material(
                color: theme.colorScheme.surfaceContainer,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.fullscreen_exit),
                      onPressed: () => _exitMiniPlayer(),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.speaker, size: 18),
                      onPressed: () {
                        showModalBottomSheet(
                          useRootNavigator: true,
                          context: context,
                          builder: (context) => const PlayerDevicePopup(),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.merge),
                      onPressed: () {
                        showModalBottomSheet(
                          useRootNavigator: true,
                          isScrollControlled: true,
                          context: context,
                          builder: (context) => const SiblingTracksPopup(),
                        ).then((_) {
                          if (mounted) {
                            setState(() {});
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.queue_music),
                      onPressed: () {
                        showModalBottomSheet(
                          useRootNavigator: true,
                          isScrollControlled: true,
                          context: context,
                          builder: (context) => const PlayerQueuePopup(),
                        ).then((_) {
                          if (mounted) {
                            setState(() {});
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: _isHoverMode
                          ? const Icon(Icons.touch_app)
                          : const Icon(Icons.touch_app_outlined),
                      style: ButtonStyle(
                        foregroundColor: _isHoverMode
                            ? WidgetStateProperty.all(theme.colorScheme.primary)
                            : null,
                      ),
                      onPressed: () async {
                        setState(() {
                          _areaActive = true;
                          _isHoverMode = !_isHoverMode;
                        });
                      },
                    ),
                    if (PlatformInfo.isDesktop)
                      FutureBuilder(
                        future: windowManager.isAlwaysOnTop(),
                        builder: (context, snapshot) {
                          return IconButton(
                            icon: Icon(
                              snapshot.data == true
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                            ),
                            style: ButtonStyle(
                              foregroundColor: snapshot.data == true
                                  ? WidgetStateProperty.all(
                                      theme.colorScheme.primary)
                                  : null,
                            ),
                            onPressed: snapshot.data == null
                                ? null
                                : () async {
                                    await windowManager.setAlwaysOnTop(
                                      snapshot.data == true ? false : true,
                                    );
                                    setState(() {});
                                  },
                          );
                        },
                      ),
                  ],
                ).paddingSymmetric(horizontal: 14),
              ),
            ),
          ),
          body: Column(
            children: [
              const Expanded(child: SyncedLyrics(defaultTextZoom: 67)),
              SizedBox(
                height: 85,
                child: BottomPlayer(
                  isMiniPlayer: true,
                  usePop: true,
                  onTap: () => _exitMiniPlayer(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
