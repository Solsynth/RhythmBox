import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_box/providers/auth.dart';
import 'package:rhythm_box/providers/error_notifier.dart';
import 'package:rhythm_box/services/sourced_track/sources/netease.dart';
import 'package:rhythm_box/widgets/sized_container.dart';

class LoginNeteaseScreen extends StatefulWidget {
  const LoginNeteaseScreen({super.key});

  @override
  State<LoginNeteaseScreen> createState() => _LoginNeteaseScreenState();
}

class _LoginNeteaseScreenState extends State<LoginNeteaseScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _phoneRegionController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final AuthenticationProvider _auth = Get.find();

  bool _isLogging = false;

  Future<void> _sentCaptcha() async {
    setState(() => _isLogging = true);

    final phone = _phoneController.text;
    var region = _phoneRegionController.text;
    if (region.isEmpty) region = '86';
    final client = NeteaseSourcedTrack.getClient();
    final resp = await client.get(
      '/captcha/sent?phone=$phone&ctcode=$region&timestamp=${DateTime.now().millisecondsSinceEpoch}',
    );

    if (resp.statusCode != 200 || resp.body?['code'] != 200) {
      Get.find<ErrorNotifier>().showError(
        resp.bodyString ?? resp.status.toString(),
      );
    }

    setState(() => _isLogging = false);
  }

  Future<void> _performLogin() async {
    setState(() => _isLogging = true);

    final phone = _phoneController.text;
    final password = _passwordController.text;
    var region = _phoneRegionController.text;
    if (region.isEmpty) region = '86';
    final client = NeteaseSourcedTrack.getClient();
    final resp = await client.get(
      '/login/cellphone?phone=$phone&captcha=$password&countrycode=$region&timestamp=${DateTime.now().millisecondsSinceEpoch}',
    );

    if (resp.statusCode != 200 || resp.body?['code'] != 200) {
      Get.find<ErrorNotifier>().showError(
        resp.bodyString ?? resp.status.toString(),
      );
      setState(() => _isLogging = false);
      return;
    }

    await _auth.setNeteaseCredentials(resp.body['cookie']);

    setState(() => _isLogging = false);

    GoRouter.of(context).goNamed('settings');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneRegionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect with Netease Cloud Music'),
      ),
      body: CenteredContainer(
        maxWidth: 320,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 64,
                  child: TextField(
                    controller: _phoneRegionController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '86',
                      isDense: true,
                    ),
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      label: Text('Phone Number'),
                      isDense: true,
                    ),
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                ),
              ],
            ),
            const Gap(8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      label: Text('Captcha Code'),
                      isDense: true,
                    ),
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                ),
                const Gap(8),
                IconButton(
                  onPressed: _isLogging ? null : () => _sentCaptcha(),
                  icon: const Icon(Icons.sms),
                  tooltip: 'Get Captcha',
                ),
              ],
            ),
            const Gap(8),
            TextButton(
              onPressed: _isLogging ? null : () => _performLogin(),
              child: const Text('Login'),
            )
          ],
        ),
      ),
    );
  }
}
