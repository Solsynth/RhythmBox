import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_box/providers/auth.dart';
import 'package:rhythm_box/providers/spotify.dart';
import 'package:rhythm_box/providers/user_preferences.dart';
import 'package:rhythm_box/screens/auth/login.dart';
import 'package:rhythm_box/services/database/database.dart';
import 'package:rhythm_box/widgets/auto_cache_image.dart';
import 'package:rhythm_box/widgets/sized_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SpotifyProvider _spotify = Get.find();
  late final AuthenticationProvider _authenticate = Get.find();
  late final UserPreferencesProvider _preferences = Get.find();

  bool _isLoggingIn = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          centerTitle: MediaQuery.of(context).size.width >= 720,
        ),
        body: CenteredContainer(
          child: ListView(
            children: [
              Obx(() {
                if (_authenticate.auth.value == null) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: const Icon(Icons.login),
                    title: const Text('Connect with Spotify'),
                    subtitle:
                        const Text('To explore your own library and more'),
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
              const Divider(thickness: 0.3, height: 1),
              Obx(
                () => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: const Icon(Icons.audio_file),
                  title: const Text('Audio Source'),
                  subtitle:
                      const Text('Choose who to provide the songs you played.'),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton2<AudioSource>(
                      isExpanded: true,
                      hint: Text(
                        'Select Item',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      items: AudioSource.values
                          .map((AudioSource item) =>
                              DropdownMenuItem<AudioSource>(
                                value: item,
                                child: Text(
                                  item.label,
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ))
                          .toList(),
                      value: _preferences.state.value.audioSource,
                      onChanged: (AudioSource? value) {
                        _preferences
                            .setAudioSource(value ?? AudioSource.youtube);
                      },
                      buttonStyleData: const ButtonStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        height: 40,
                        width: 140,
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 40,
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(thickness: 0.3, height: 1),
              Obx(
                () => SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  secondary: const Icon(Icons.all_inclusive),
                  title: const Text('Endless Playback'),
                  subtitle: const Text(
                      'Automatically get more recommendation for you after your queue finish playing'),
                  value: _preferences.state.value.endlessPlayback,
                  onChanged: _preferences.setEndlessPlayback,
                ),
              ),
              Obx(
                () => SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  secondary: const Icon(Icons.graphic_eq),
                  title: const Text('Normalize Audio'),
                  subtitle:
                      const Text('Make audio not too loud either too quiet'),
                  value: _preferences.state.value.normalizeAudio,
                  onChanged: _preferences.setNormalizeAudio,
                ),
              ),
              Obx(
                () => SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  secondary: const Icon(Icons.screen_lock_portrait),
                  title: const Text('Player Wakelock'),
                  subtitle: const Text(
                      'Keep your screen doesn\'t lock in player screen'),
                  value: _preferences.state.value.playerWakelock,
                  onChanged: _preferences.setPlayerWakelock,
                ),
              ),
              const Divider(thickness: 0.3, height: 1),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: const Icon(Icons.info),
                title: const Text('About'),
                subtitle: const Text('More information about this app'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  GoRouter.of(context).pushNamed('about');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
