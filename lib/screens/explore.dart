import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rhythm_box/providers/auth.dart';
import 'package:rhythm_box/providers/recent_played.dart';
import 'package:rhythm_box/providers/spotify.dart';
import 'package:rhythm_box/providers/user_preferences.dart';
import 'package:rhythm_box/services/album.dart';
import 'package:rhythm_box/services/database/database.dart';
import 'package:rhythm_box/services/spotify/spotify_endpoints.dart';
import 'package:rhythm_box/widgets/playlist/playlist_section.dart';
import 'package:spotify/spotify.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final SpotifyProvider _spotify = Get.find();
  late final RecentlyPlayedProvider _history = Get.find();
  late final AuthenticationProvider _auth = Get.find();

  final Map<String, bool> _isLoading = {
    'featured': true,
    'recently': true,
    'newReleases': true,
    'forYou': true,
  };

  List<Object>? _featuredPlaylist;
  List<Object>? _recentlyPlaylist;
  List<Object>? _newReleasesPlaylist;
  List<dynamic>? _forYouView;

  Future<void> _pullPlaylist() async {
    final market = Get.find<UserPreferencesProvider>().state.value.market;
    final locale = Get.find<UserPreferencesProvider>().state.value.locale;

    _featuredPlaylist =
        (await _spotify.api.playlists.featured.getPage(20)).items!.toList();
    if (mounted) {
      setState(() => _isLoading['featured'] = false);
    } else {
      return;
    }

    final idxList = Set();
    _recentlyPlaylist = (await _history.fetch())
        .where((x) => x.playlist != null)
        .map((x) => x.playlist!)
        .toList()
      ..retainWhere((x) => idxList.add(x.id!));
    if (mounted) {
      setState(() => _isLoading['recently'] = false);
    } else {
      return;
    }

    _newReleasesPlaylist =
        (await _spotify.api.browse.newReleases(country: market).getPage(20))
            .items
            ?.map((album) => album.toAlbum())
            .toList();
    if (mounted) {
      setState(() => _isLoading['newReleases'] = false);
    } else {
      return;
    }

    final customEndpoint =
        CustomSpotifyEndpoints(_auth.auth.value?.accessToken.value ?? '');
    final forYouView = await customEndpoint.getView(
      'made-for-x-hub',
      market: market,
      locale: Intl.canonicalizedLocale(locale.toString()),
    );
    _forYouView = forYouView['content']?['items'];
    if (mounted) {
      setState(() => _isLoading['forYou'] = false);
    } else {
      return;
    }
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
        body: CustomScrollView(
          slivers: [
            if (_recentlyPlaylist?.isNotEmpty ?? false)
              SliverToBoxAdapter(
                child: PlaylistSection(
                  isLoading: _isLoading['recently']!,
                  title: 'Recent Played',
                  list: _recentlyPlaylist,
                ),
              ),
            if (_recentlyPlaylist?.isNotEmpty ?? false) const SliverGap(16),
            if (_newReleasesPlaylist?.isNotEmpty ?? false)
              SliverToBoxAdapter(
                child: PlaylistSection(
                  isLoading: _isLoading['newReleases']!,
                  title: 'New Releases',
                  list: _newReleasesPlaylist,
                ),
              ),
            if (_newReleasesPlaylist?.isNotEmpty ?? false) const SliverGap(16),
            SliverList.builder(
              itemCount: _forYouView?.length ?? 0,
              itemBuilder: (context, idx) {
                final item = _forYouView![idx];
                final playlists = item['content']?['items']
                        ?.where((itemL2) => itemL2['type'] == 'playlist')
                        .map((itemL2) => PlaylistSimple.fromJson(itemL2))
                        .toList()
                        .cast<PlaylistSimple>() ??
                    <PlaylistSimple>[];
                if (playlists.isEmpty) return const SizedBox.shrink();
                return PlaylistSection(
                  isLoading: false,
                  title: item['name'] ?? '',
                  list: playlists,
                ).paddingOnly(bottom: 16);
              },
            ),
            SliverToBoxAdapter(
              child: PlaylistSection(
                isLoading: _isLoading['featured']!,
                title: 'Featured',
                list: _featuredPlaylist,
              ),
            ),
            const SliverGap(16),
          ],
        ),
      ),
    );
  }
}
