import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/auth.dart';
import 'package:rhythm_box/widgets/no_login_fallback.dart';
import 'package:rhythm_box/widgets/playlist/user_playlist_list.dart';
import 'package:rhythm_box/widgets/sized_container.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final AuthenticationProvider _authenticate = Get.find();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Library'),
          centerTitle: MediaQuery.of(context).size.width >= 720,
        ),
        body: Obx(() {
          if (_authenticate.auth.value == null) {
            return const NoLoginFallback();
          }

          return const CenteredContainer(
            child: Column(
              children: [
                Expanded(child: UserPlaylistList()),
              ],
            ),
          );
        }),
      ),
    );
  }
}
