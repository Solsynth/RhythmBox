library song_link;

import 'dart:convert';
import 'dart:developer';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart';

part 'model.dart';

part 'song_link.freezed.dart';
part 'song_link.g.dart';

abstract class SongLinkService {
  static Future<List<SongLink>> links(String spotifyId) async {
    try {
      final client = GetConnect();
      final res = await client.get(
        "https://song.link/s/$spotifyId",
        headers: {
          "Accept":
              "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
          "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
        },
      );

      final document = parse(res.body);

      final script = document.getElementById("__NEXT_DATA__")?.text;

      if (script == null) {
        return <SongLink>[];
      }

      final pageProps = jsonDecode(script) as Map<String, dynamic>;
      final songLinks = pageProps["props"]?["pageProps"]?["pageData"]
              ?["sections"]
          ?.firstWhere(
        (section) => section?["sectionId"] == "section|auto|links|listen",
      )?["links"] as List?;

      return songLinks?.map((link) => SongLink.fromJson(link)).toList() ??
          <SongLink>[];
    } catch (e) {
      log('[SongLink] Unable get song link: $e');
      return <SongLink>[];
    }
  }
}
