import 'package:spotify/spotify.dart';

extension ArtistSimpleExtension on List<ArtistSimple> {
  String asString() {
    return map((e) => e.name?.replaceAll(',', ' ')).join(', ');
  }
}

extension ArtistExtension on List<Artist> {
  String asString() {
    return map((e) => e.name?.replaceAll(',', ' ')).join(', ');
  }
}
