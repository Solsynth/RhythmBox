import 'package:flutter/material.dart';
import 'package:rhythm_box/widgets/auto_cache_image.dart';
import 'package:spotify/spotify.dart';
import 'package:rhythm_box/services/artist.dart';

class TrackTile extends StatelessWidget {
  final Track? item;

  final Function? onTap;

  const TrackTile({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: (item?.album?.images?.isNotEmpty ?? false)
            ? AutoCacheImage(
                item!.album!.images!.first.url!,
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
        item?.artists?.asString() ?? 'Please stand by...',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        if (onTap == null) return;
        onTap!();
      },
    );
  }
}
