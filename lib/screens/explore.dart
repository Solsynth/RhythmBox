import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/recent_played.dart';
import 'package:rhythm_box/providers/spotify.dart';
import 'package:rhythm_box/providers/user_preferences.dart';
import 'package:rhythm_box/services/album.dart';
import 'package:rhythm_box/services/database/database.dart';
import 'package:rhythm_box/widgets/playlist/playlist_section.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final SpotifyProvider _spotify = Get.find();
  late final RecentlyPlayedProvider _history = Get.find();

  final Map<String, bool> _isLoading = {
    'featured': true,
    'recently': true,
    'newReleases': true,
  };

  List<Object>? _featuredPlaylist;
  List<Object>? _recentlyPlaylist;
  List<Object>? _newReleasesPlaylist;

  Future<void> _pullPlaylist() async {
    final market = Get.find<UserPreferencesProvider>().state.value.market;

    _featuredPlaylist =
        (await _spotify.api.playlists.featured.getPage(20)).items!.toList();
    setState(() => _isLoading['featured'] = false);

    _recentlyPlaylist = (await _history.fetch())
        .where((x) => x.playlist != null)
        .map((x) => x.playlist!)
        .toList();
    setState(() => _isLoading['recently'] = false);

    _newReleasesPlaylist =
        (await _spotify.api.browse.newReleases(country: market).getPage(20))
            .items
            ?.map((album) => album.toAlbum())
            .toList();
    setState(() => _isLoading['newReleases'] = false);
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
        body: ListView(
          children: [
            if (_newReleasesPlaylist?.isNotEmpty ?? false)
              PlaylistSection(
                isLoading: _isLoading['newReleases']!,
                title: 'New Releases',
                list: _newReleasesPlaylist,
              ),
            if (_recentlyPlaylist?.isNotEmpty ?? false)
              PlaylistSection(
                isLoading: _isLoading['recently']!,
                title: 'Recent Played',
                list: _recentlyPlaylist,
              ),
            PlaylistSection(
              isLoading: _isLoading['featured']!,
              title: 'Featured',
              list: _featuredPlaylist,
            ),
          ],
        ),
      ),
    );
  }
}
