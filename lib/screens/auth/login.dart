import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_box/platform.dart';
import 'package:rhythm_box/screens/auth/desktop_login.dart';

Future<void> universalLogin(BuildContext context) async {
  if (PlatformInfo.isMobile) {
    GoRouter.of(context).pushNamed('authMobileLogin');
    return;
  }

  return await desktopLogin(context);
}
