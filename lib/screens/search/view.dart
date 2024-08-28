import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/spotify.dart';
import 'package:rhythm_box/providers/user_preferences.dart';
import 'package:rhythm_box/widgets/tracks/track_list.dart';
import 'package:spotify/spotify.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final SpotifyProvider _spotify = Get.find();

  bool _isLoading = false;

  String? _searchTerm;
  List<dynamic>? _searchResult;

  Future<void> _search(String? term) async {
    if (term != null) {
      _searchTerm = term.trim();
    }
    if (_searchTerm == null) {
      return;
    }

    setState(() => _isLoading = true);

    final prefs = Get.find<UserPreferencesProvider>().state.value;

    _searchResult = (await _spotify.api.search
            .get(_searchTerm!, types: [SearchType.track], market: prefs.market)
            .getPage(20))
        .mapMany((x) => x.items)
        .toList();

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            SearchBar(
              padding: const WidgetStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(horizontal: 16.0),
              ),
              onSubmitted: (value) {
                if (_isLoading) return;
                _search(value);
              },
              leading: const Icon(Icons.search),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ).paddingSymmetric(horizontal: 24, vertical: 8),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  if (_searchResult != null)
                    TrackSliverList(tracks: List<Track>.from(_searchResult!)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
