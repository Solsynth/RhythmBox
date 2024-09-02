import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/platform.dart';
import 'package:rhythm_box/providers/error_notifier.dart';
import 'package:window_manager/window_manager.dart';

class SystemShell extends StatefulWidget {
  final Widget child;

  const SystemShell({super.key, required this.child});

  @override
  State<SystemShell> createState() => _SystemShellState();
}

class _SystemShellState extends State<SystemShell> {
  late final ErrorNotifier _errorNotifier = Get.find();

  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = _errorNotifier.showing.listen((value) {
      if (value == null) {
        ScaffoldMessenger.of(context).clearMaterialBanners();
      } else {
        ScaffoldMessenger.of(context).showMaterialBanner(value);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.isMacOS) {
      return DragToMoveArea(
        child: Column(
          children: [
            Container(
              height: 28,
              color: Theme.of(context).colorScheme.surface,
            ),
            const Divider(
              thickness: 0.3,
              height: 0.3,
            ),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    return widget.child;
  }
}
