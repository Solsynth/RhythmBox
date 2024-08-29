import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_box/platform.dart';
import 'package:rhythm_box/providers/auth.dart';

class MobileLogin extends StatelessWidget {
  const MobileLogin({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthenticationProvider authenticate = Get.find();

    if (PlatformInfo.isDesktop) {
      const Scaffold(
        body: Center(
          child: Text('This feature is not available on desktop'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect with Spotify'),
      ),
      body: SafeArea(
        child: InAppWebView(
          initialSettings: InAppWebViewSettings(
            userAgent:
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36',
          ),
          initialUrlRequest: URLRequest(
            url: WebUri('https://accounts.spotify.com/'),
          ),
          onPermissionRequest: (controller, permissionRequest) async {
            return PermissionResponse(
              resources: permissionRequest.resources,
              action: PermissionResponseAction.GRANT,
            );
          },
          onLoadStop: (controller, action) async {
            if (action == null) return;
            String url = action.toString();
            if (url.endsWith('/')) {
              url = url.substring(0, url.length - 1);
            }

            final exp = RegExp(r'https:\/\/accounts.spotify.com\/.+\/status');

            if (exp.hasMatch(url)) {
              final cookies =
                  await CookieManager.instance().getCookies(url: action);
              final cookieHeader =
                  "sp_dc=${cookies.firstWhere((element) => element.name == "sp_dc").value}";

              await authenticate.login(cookieHeader);
              if (context.mounted) {
                GoRouter.of(context).pop();
              }
            }
          },
        ),
      ),
    );
  }
}
