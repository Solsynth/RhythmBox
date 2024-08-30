import 'dart:developer';

import 'package:dio/dio.dart' hide Response;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:rhythm_box/providers/audio_player.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';
import 'package:rhythm_box/services/server/active_sourced_track.dart';
import 'package:rhythm_box/services/server/sourced_track.dart';
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

      final res = await Dio().get(
        sourcedTrack!.url,
        options: Options(
          headers: {
            ...request.headers,
            'User-Agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
            'host': Uri.parse(sourcedTrack.url).host,
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
    } catch (e, stackTrace) {
      log('[PlaybackSever] Error: $e; Trace:\n $stackTrace');
      return Response.internalServerError();
    }
  }
}
