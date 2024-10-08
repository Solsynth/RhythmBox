import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ErrorNotifier extends GetxController {
  Rx<MaterialBanner?> showing = Rx(null);

  Timer? _autoDismissTimer;

  void logError(String msg, {StackTrace? trace}) {
    log('$msg${trace != null ? '\nTrace:\n$trace' : ''}');
    showError(msg);
  }

  void showError(String msg) {
    _autoDismissTimer?.cancel();

    showing.value = MaterialBanner(
      dividerColor: Colors.transparent,
      leading: const Icon(Icons.error),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Something went wrong...',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(msg),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            showing.value = null;
          },
          child: const Text('Dismiss'),
        ),
      ],
    );

    _autoDismissTimer = Timer(const Duration(seconds: 3), () {
      showing.value = null;
    });
  }
}
