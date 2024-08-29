import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_box/providers/spotify.dart';
import 'package:rhythm_box/widgets/playlist/playlist_tile.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:spotify/spotify.dart';

class UserPlaylistList extends StatefulWidget {
  const UserPlaylistList({super.key});

  @override
  State<UserPlaylistList> createState() => _UserPlaylistListState();
}

class _UserPlaylistListState extends State<UserPlaylistList> {
  late final SpotifyProvider _spotify = Get.find();

  PlaylistSimple get _userLikedPlaylist => PlaylistSimple()
    ..name = 'Liked Music'
    ..description = 'Your favorite music'
    ..type = 'playlist'
    ..collaborative = false
    ..public = false
    ..id = 'user-liked-tracks';

  bool _isLoading = true;

  List<PlaylistSimple>? _playlist;

  Future<void> _pullPlaylist() async {
    _playlist = [_userLikedPlaylist, ...await _spotify.api.playlists.me.all()];
    setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    _pullPlaylist();
  }

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: _isLoading,
      child: ListView.builder(
        itemCount: _playlist?.length ?? 3,
        itemBuilder: (context, idx) {
          final item = _playlist?[idx];
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
    );
  }
}
