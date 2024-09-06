import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rhythm_box/platform.dart';

class AutoCacheImage extends StatelessWidget {
  final String url;
  final double? width, height;
  final BoxFit? fit;

  const AutoCacheImage(this.url,
      {super.key, this.width, this.height, this.fit});

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.canCacheImage) {
      return CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
    );
  }

  static ImageProvider provider(String url) {
    if (PlatformInfo.canCacheImage) {
      return CachedNetworkImageProvider(url);
    }
    return NetworkImage(url);
  }
}
