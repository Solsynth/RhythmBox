import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_box/providers/spotify.dart';
import 'package:rhythm_box/widgets/playlist/playlist_tile.dart';
import 'package:rhythm_box/widgets/sized_container.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:spotify/spotify.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final SpotifyProvider _spotify = Get.find();

  bool _isLoading = true;

  List<PlaylistSimple>? _featuredPlaylist;

  Future<void> _pullPlaylist() async {
    _featuredPlaylist =
        (await _spotify.api.playlists.featured.getPage(20)).items!.toList();
    setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    _pullPlaylist();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Scaffold(
        appBar: AppBar(
          title: Text('explore'.tr),
          centerTitle: MediaQuery.of(context).size.width >= 720,
        ),
        body: CenteredContainer(
          child: Skeletonizer(
            enabled: _isLoading,
            child: ListView.builder(
              itemCount: _featuredPlaylist?.length ?? 20,
              itemBuilder: (context, idx) {
                final item = _featuredPlaylist?[idx];
                return PlaylistTile(
                  item: item,
                  onTap: () {
                    if (item == null) return;
                    GoRouter.of(context).pushNamed(
                      'playlistView',
                      pathParameters: {'id': item.id!},
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
