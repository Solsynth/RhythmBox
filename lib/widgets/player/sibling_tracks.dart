import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/providers/error_notifier.dart';
import 'package:rhythm_box/providers/user_preferences.dart';
import 'package:rhythm_box/services/database/database.dart';
import 'package:rhythm_box/services/duration.dart';
import 'package:rhythm_box/services/server/active_sourced_track.dart';
import 'package:rhythm_box/services/sourced_track/models/source_info.dart';
import 'package:rhythm_box/services/sourced_track/models/video_info.dart';
import 'package:rhythm_box/services/sourced_track/sourced_track.dart';
import 'package:rhythm_box/services/sourced_track/sources/kugou.dart';
import 'package:rhythm_box/services/sourced_track/sources/netease.dart';
import 'package:rhythm_box/services/sourced_track/sources/piped.dart';
import 'package:rhythm_box/services/sourced_track/sources/youtube.dart';
import 'package:rhythm_box/services/artist.dart';
import 'package:rhythm_box/services/utils.dart';
import 'package:rhythm_box/widgets/auto_cache_image.dart';
import 'package:rhythm_box/widgets/tracks/querying_track_info.dart';
import 'package:spotify/spotify.dart';

class SiblingTracks extends StatefulWidget {
  const SiblingTracks({super.key});

  @override
  State<SiblingTracks> createState() => _SiblingTracksState();
}

class _SiblingTracksState extends State<SiblingTracks> {
  late final QueryingTrackInfoProvider _query = Get.find();
  late final ActiveSourcedTrackProvider _activeSource = Get.find();
  late final AudioPlayerProvider _playback = Get.find();

  final TextEditingController _searchTermController = TextEditingController();

  Track? get _activeTrack =>
      _activeSource.state.value ?? _playback.state.value.activeTrack;

  List<SourceInfo> _siblings = List.empty(growable: true);

  final sourceInfoToLabelMap = {
    YoutubeSourceInfo: 'YouTube',
    PipedSourceInfo: 'Piped',
    NeteaseSourceInfo: 'Netease',
    KugouSourceInfo: 'Kugou',
  };

  List<StreamSubscription>? _subscriptions;

  String? _lastActiveTrackId;

  void _updateSiblings() {
    _siblings = List.from(
      !_query.isQueryingTrackInfo.value
          ? [
              (_activeTrack as SourcedTrack).sourceInfo,
              ..._activeSource.state.value!.siblings,
            ]
          : [],
      growable: true,
    );
  }

  void _updateSearchTerm() {
    if (_lastActiveTrackId == _activeTrack?.id) return;

    final title = ServiceUtils.getTitle(
      _activeTrack?.name ?? '',
      artists: _activeTrack?.artists?.map((e) => e.name!).toList() ?? [],
      onlyCleanArtist: true,
    ).trim();

    final defaultSearchTerm =
        '$title - ${_activeTrack?.artists?.asString() ?? ''}';

    _searchTermController.text = defaultSearchTerm;
  }

  bool _isSearching = false;

  Future<void> _searchSiblings() async {
    if (_isSearching) return;
    if (_searchTermController.text.trim().isEmpty) return;

    _siblings.clear();
    setState(() => _isSearching = true);

    final preferences = Get.find<UserPreferencesProvider>().state.value;
    final searchTerm = _searchTermController.text.trim();

    try {
      if (preferences.audioSource == AudioSource.youtube ||
          preferences.audioSource == AudioSource.piped) {
        final resultsYt = await youtubeClient.search.search(searchTerm.trim());

        final searchResults = await Future.wait(
          resultsYt
              .map(YoutubeVideoInfo.fromVideo)
              .mapIndexed((i, video) async {
            final siblingType =
                await YoutubeSourcedTrack.toSiblingType(i, video);
            return siblingType.info;
          }),
        );
        final activeSourceInfo = (_activeTrack! as SourcedTrack).sourceInfo;
        _siblings = List.from(
          searchResults
            ..removeWhere((element) => element.id == activeSourceInfo.id)
            ..insert(
              0,
              activeSourceInfo,
            ),
          growable: true,
        );
      } else if (preferences.audioSource == AudioSource.netease) {
        final client = NeteaseSourcedTrack.getClient();
        final resp = await client.get(
            '/search?keywords=${Uri.encodeComponent(searchTerm)}&realIP=${NeteaseSourcedTrack.lookupRealIp()}');
        final searchResults = resp.body['result']['songs']
            .map(NeteaseSourcedTrack.toSourceInfo)
            .toList();

        final activeSourceInfo = (_activeTrack! as SourcedTrack).sourceInfo;
        _siblings = List.from(
          searchResults
            ..removeWhere((element) => element.id == activeSourceInfo.id)
            ..insert(
              0,
              activeSourceInfo,
            ),
          growable: true,
        );
      }
    } catch (err) {
      Get.find<ErrorNotifier>().showError(err.toString());
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _updateSearchTerm();
    _updateSiblings();
    _subscriptions = [
      _playback.state.listen((value) async {
        if (value.activeTrack != null) {
          _updateSearchTerm();
          _updateSiblings();
          setState(() {});
        }
      }),
    ];
  }

  @override
  void dispose() {
    _searchTermController.dispose();
    if (_subscriptions != null) {
      for (final subscription in _subscriptions!) {
        subscription.cancel();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surfaceContainer,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: TextField(
            controller: _searchTermController,
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: 'search'.tr,
            ),
            onSubmitted: (_) {
              _searchSiblings();
            },
          ),
        ),
        if (_isSearching) const LinearProgressIndicator(minHeight: 3),
        Expanded(
          child: ListView.builder(
            itemCount: _siblings.length,
            itemBuilder: (context, idx) {
              final item = _siblings[idx];
              final src = sourceInfoToLabelMap[item.runtimeType];
              return ListTile(
                title: Text(
                  item.title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AutoCacheImage(
                    item.thumbnail,
                    height: 64,
                    width: 64,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                trailing: Text(
                  item.duration.toHumanReadableString(),
                  style: GoogleFonts.robotoMono(),
                ),
                subtitle: Row(
                  children: [
                    if (src != null) Text(src),
                    Expanded(
                      child: Text(
                        ' · ${item.artist}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                enabled: !_query.isQueryingTrackInfo.value,
                tileColor: !_query.isQueryingTrackInfo.value &&
                        item.id == (_activeTrack as SourcedTrack).sourceInfo.id
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : null,
                onTap: () {
                  if (!_query.isQueryingTrackInfo.value &&
                      item.id != (_activeTrack as SourcedTrack).sourceInfo.id) {
                    _activeSource.swapSibling(item);
                    Navigator.of(context).pop();
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
