import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/widgets/auto_cache_image.dart';
import 'package:spotify/spotify.dart';

class PlaylistCard extends StatelessWidget {
  final PlaylistSimple? item;

  final Function? onTap;

  const PlaylistCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: AspectRatio(
                aspectRatio: 1,
                child: (item?.images?.isNotEmpty ?? false)
                    ? AutoCacheImage(item!.images!.first.url!)
                    : const Center(child: Icon(Icons.image)),
              ),
            ).paddingSymmetric(vertical: 8),
            Text(
              item?.name ?? 'Loading...',
              style: Theme.of(context).textTheme.bodyLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Expanded(
              child: Text(
                item?.description ?? 'Please stand by...',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ).paddingSymmetric(horizontal: 8),
        onTap: () {
          if (onTap != null) return;
          onTap!();
        },
      ),
    );
  }
}
