import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:rhythm_box/services/rhythm_media.dart';
import 'package:rhythm_box/services/server/routes/playback.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

class PlaybackServerProvider extends GetxController {
  final int port = Random().nextInt(17500) + 5000;

  HttpServer? _server;
  Router? _router;

  @override
  void onInit() {
    _initServer();
    super.onInit();
  }

  Future<void> _initServer() async {
    const pipeline = Pipeline();
    if (kDebugMode) {
      pipeline.addMiddleware(logRequests());
    }

    RhythmMedia.serverPort = port;

    _router = Router();
    _router!.get("/ping", (Request request) => Response.ok("pong"));
    _router!.get(
      "/stream/<trackId>",
      Get.find<ServerPlaybackRoutesProvider>().getStreamTrackId,
    );

    _server = await serve(
      pipeline.addHandler(_router!.call),
      InternetAddress.anyIPv4,
      port,
    );

    log('[Playback] Playback server at http://${_server!.address.host}:${_server!.port}');
  }
}
