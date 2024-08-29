import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:rhythm_box/widgets/album/album_card.dart';
import 'package:rhythm_box/widgets/playlist/playlist_card.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:spotify/spotify.dart';

class PlaylistSection extends StatelessWidget {
  final bool isLoading;
  final String title;
  final List<Object>? list;

  const PlaylistSection({
    super.key,
    required this.isLoading,
    required this.title,
    required this.list,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ).paddingOnly(left: 32, right: 32, bottom: 4),
        SizedBox(
          height: 280,
          width: double.infinity,
          child: Skeletonizer(
            enabled: isLoading,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: list?.length ?? 20,
              itemBuilder: (context, idx) {
                final item = list?[idx];
                return SizedBox(
                  width: 180,
                  height: 180,
                  child: switch (item.runtimeType) {
                    const (AlbumSimple) || const (Album) => AlbumCard(
                        item: item as AlbumSimple?,
                        onTap: () {
                          if (item == null) return;
                          GoRouter.of(context).pushNamed(
                            'playlistView',
                            pathParameters: {'id': item.id!},
                          );
                        },
                      ),
                    _ => PlaylistCard(
                        item: item as PlaylistSimple?,
                        onTap: () {
                          if (item == null) return;
                          GoRouter.of(context).pushNamed(
                            'playlistView',
                            pathParameters: {'id': item.id!},
                          );
                        },
                      ),
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
