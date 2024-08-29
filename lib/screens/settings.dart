import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/auth.dart';
import 'package:rhythm_box/providers/spotify.dart';
import 'package:rhythm_box/screens/auth/login.dart';
import 'package:rhythm_box/widgets/auto_cache_image.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SpotifyProvider _spotify = Get.find();
  late final AuthenticationProvider _authenticate = Get.find();

  bool _isLoggingIn = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Obx(() {
              if (_authenticate.auth.value == null) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: const Icon(Icons.login),
                  title: const Text('Connect with Spotify'),
                  subtitle: const Text('To explore your own library and more'),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !_isLoggingIn,
                  onTap: () async {
                    setState(() => _isLoggingIn = true);
                    await universalLogin(context);
                    setState(() => _isLoggingIn = false);
                  },
                );
              }

              return FutureBuilder(
                future: _spotify.api.me.get(),
                builder: (context, snapshot) {
                  print(snapshot.data);
                  print(snapshot.error);
                  if (!snapshot.hasData) {
                    return const ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      leading: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                        ),
                      ),
                      title: Text('Loading...'),
                    );
                  }

                  return ListTile(
                    leading: (snapshot.data!.images?.isNotEmpty ?? false)
                        ? CircleAvatar(
                            backgroundImage: AutoCacheImage.provider(
                              snapshot.data!.images!.firstOrNull!.url!,
                            ),
                          )
                        : const Icon(Icons.account_circle),
                    title: Text(snapshot.data!.displayName!),
                    subtitle: const Text('Connected with your Spotify'),
                  );
                },
              );
            }),
            Obx(() {
              if (_authenticate.auth.value == null) {
                return const SizedBox();
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: const Icon(Icons.logout),
                title: const Text('Log out'),
                subtitle: const Text('Disconnect with this Spotify account'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  _authenticate.logout();
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
