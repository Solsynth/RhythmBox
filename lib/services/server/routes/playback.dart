import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' hide Response;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/providers/error_notifier.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';
import 'package:rhythm_box/services/server/active_sourced_track.dart';
import 'package:rhythm_box/services/server/sourced_track.dart';
import 'package:rhythm_box/services/sourced_track/sources/kugou.dart';
import 'package:rhythm_box/services/sourced_track/sources/netease.dart';
import 'package:shelf/shelf.dart';

class ServerPlaybackRoutesProvider {
  /// @get('/stream/<trackId>')
  Future<Response> getStreamTrackId(Request request, String trackId) async {
    final AudioPlayerProvider playback = Get.find();

    try {
      final track = playback.state.value.tracks
          .firstWhere((element) => element.id == trackId);

      final ActiveSourcedTrackProvider activeSourcedTrack = Get.find();
      final sourcedTrack = activeSourcedTrack.state.value?.id == track.id
          ? activeSourcedTrack.state.value
          : await Get.find<SourcedTrackProvider>().fetch(RhythmMedia(track));

      activeSourcedTrack.updateTrack(sourcedTrack);

      var url = sourcedTrack!.url;

      if (sourcedTrack is NeteaseSourcedTrack) {
        // Special processing for netease to get real assets url
        final resp = await GetConnect(timeout: const Duration(seconds: 30)).get(
          '${sourcedTrack.url}&realIP=${await NeteaseSourcedTrack.lookupRealIp()}',
        );
        final realUrl = resp.body['data'][0]['url'];
        url = realUrl;
      } else if (sourcedTrack is KugouSourcedTrack) {
        // Special processing for kugou to get real assets url
        final resp = await GetConnect(timeout: const Duration(seconds: 30))
            .get(sourcedTrack.url);
        final urls = jsonDecode(resp.body)['url'];
        if (urls?.isEmpty ?? true) {
          Get.find<ErrorNotifier>().showError(
            '[PlaybackServer] Unable get audio source via Kugou, probably cause by paid needed resources.',
          );
          return Response(
            HttpStatus.notFound,
            body: 'Unable get audio source via Kugou',
          );
        }
        final realUrl = KugouSourcedTrack.unescapeUrl(urls.first);
        url = realUrl;
      }

      final res = await Dio().get(
        url,
        options: Options(
          headers: {
            ...request.headers,
            'User-Agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
            'host': Uri.parse(url).host,
            'Cache-Control': 'max-age=0',
            'Connection': 'keep-alive',
          },
          responseType: ResponseType.stream,
          validateStatus: (status) => status! < 500,
        ),
      );

      final audioStream =
          (res.data?.stream as Stream<Uint8List>?)?.asBroadcastStream();

      audioStream!.listen(
        (event) {},
        cancelOnError: true,
      );

      return Response(
        res.statusCode!,
        body: audioStream,
        context: {
          'shelf.io.buffer_output': false,
        },
        headers: res.headers.map,
      );
    } catch (e, stack) {
      Get.find<ErrorNotifier>()
          .logError('[PlaybackSever] Error: $e', trace: stack);
      return Response.internalServerError();
    }
  }
}
