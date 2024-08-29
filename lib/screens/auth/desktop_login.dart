import 'dart:io';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rhythm_box/platform.dart';
import 'package:rhythm_box/providers/auth.dart';

Future<void> desktopLogin(BuildContext context) async {
  final exp = RegExp(r'https:\/\/accounts.spotify.com\/.+\/status');
  final applicationSupportDir = await getApplicationSupportDirectory();
  final userDataFolder =
      Directory(join(applicationSupportDir.path, 'webview_window_Webview2'));

  if (!await userDataFolder.exists()) {
    await userDataFolder.create();
  }

  final webview = await WebviewWindow.create(
    configuration: CreateConfiguration(
      title: 'Spotify Login',
      titleBarTopPadding: PlatformInfo.isMacOS ? 20 : 0,
      windowHeight: 720,
      windowWidth: 1280,
      userDataFolderWindows: userDataFolder.path,
    ),
  );
  webview
    ..setBrightness(Theme.of(context).colorScheme.brightness)
    ..launch('https://accounts.spotify.com/')
    ..setOnUrlRequestCallback((url) {
      if (exp.hasMatch(url)) {
        webview.getAllCookies().then((cookies) async {
          final cookieHeader =
              "sp_dc=${cookies.firstWhere((element) => element.name.contains("sp_dc")).value.replaceAll("\u0000", "")}";

          final AuthenticationProvider authenticate = Get.find();
          await authenticate.login(cookieHeader);

          webview.close();
          if (context.mounted) {
            GoRouter.of(context).go('/');
          }
        });
      }

      return true;
    });
}
