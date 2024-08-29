import 'package:flutter/material.dart';
import 'package:rhythm_box/widgets/auto_cache_image.dart';
import 'package:spotify/spotify.dart';

class PlaylistTile extends StatelessWidget {
  final PlaylistSimple? item;

  final Function? onTap;

  const PlaylistTile({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: (item?.images?.isNotEmpty ?? false)
            ? AutoCacheImage(
                item!.images!.first.url!,
                width: 64.0,
                height: 64.0,
              )
            : const SizedBox(
                width: 64,
                height: 64,
                child: Center(
                  child: Icon(Icons.image),
                ),
              ),
      ),
      title: Text(item?.name ?? 'Loading...'),
      subtitle: Text(
        item?.description ?? 'Please stand by...',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        if (onTap == null) return;
        onTap!();
      },
    );
  }
}
