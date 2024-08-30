import 'package:flutter/material.dart';
import 'package:rhythm_box/platform.dart';
import 'package:window_manager/window_manager.dart';

class SystemShell extends StatelessWidget {
  final Widget child;

  const SystemShell({super.key, required this.child});

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
            Expanded(child: child),
          ],
        ),
      );
    }

    return child;
  }
}
