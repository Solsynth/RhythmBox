import 'package:spotify/spotify.dart';
import 'package:collection/collection.dart';

enum ImagePlaceholder {
  albumArt,
  artist,
  collection,
  online,
}

extension SpotifyImageExtensions on List<Image>? {
  String? asUrlString({
    int index = 1,
  }) {
    final sortedImage = this?.sorted((a, b) => a.width!.compareTo(b.width!));

    return sortedImage?[
            index > sortedImage.length - 1 ? sortedImage.length - 1 : index]
        .url;
  }
}
