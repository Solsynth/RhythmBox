import 'package:flutter/material.dart';
import 'package:rhythm_box/platform.dart';
import 'package:rhythm_box/services/kv_store/kv_store.dart';
import 'package:window_manager/window_manager.dart';

class WindowSize {
  final double height;
  final double width;
  final bool maximized;

  WindowSize({
    required this.height,
    required this.width,
    required this.maximized,
  });

  factory WindowSize.fromJson(Map<String, dynamic> json) => WindowSize(
        height: json['height'],
        width: json['width'],
        maximized: json['maximized'],
      );

  Map<String, dynamic> toJson() => {
        'height': height,
        'width': width,
        'maximized': maximized,
      };
}

class WindowManagerTools with WidgetsBindingObserver {
  static WindowManagerTools? _instance;
  static WindowManagerTools get instance => _instance!;

  WindowManagerTools._();

  static Future<void> initialize() async {
    await windowManager.ensureInitialized();
    _instance = WindowManagerTools._();
    WidgetsBinding.instance.addObserver(instance);

    await windowManager.waitUntilReadyToShow(
      WindowOptions(
        title: 'RhythmBox',
        backgroundColor: Colors.transparent,
        minimumSize: const Size(300, 700),
        titleBarStyle:
            PlatformInfo.isMacOS ? TitleBarStyle.hidden : TitleBarStyle.normal,
        center: true,
      ),
      () async {
        final savedSize = KVStoreService.windowSize;
        await windowManager.setResizable(true);
        if (savedSize?.maximized == true &&
            !(await windowManager.isMaximized())) {
          await windowManager.maximize();
        } else if (savedSize != null) {
          await windowManager.setSize(Size(savedSize.width, savedSize.height));
        }

        await windowManager.focus();
        await windowManager.show();
      },
    );
  }

  Size? _prevSize;

  @override
  void didChangeMetrics() async {
    super.didChangeMetrics();
    if (PlatformInfo.isMobile) return;
    final size = await windowManager.getSize();
    final windowSameDimension =
        _prevSize?.width == size.width && _prevSize?.height == size.height;

    if (windowSameDimension || _prevSize == null) {
      _prevSize = size;
      return;
    }
    final isMaximized = await windowManager.isMaximized();
    await KVStoreService.setWindowSize(
      WindowSize(
        height: size.height,
        width: size.width,
        maximized: isMaximized,
      ),
    );
    _prevSize = size;
  }
}
