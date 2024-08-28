import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:palette_generator/palette_generator.dart';

class PaletteProvider extends GetxController {
  final Rx<PaletteGenerator?> palette = Rx<PaletteGenerator?>(null);

  void updatePalette(PaletteGenerator? newPalette) {
    palette.value = newPalette;
    print('call update!');
    print(newPalette);
    if (newPalette != null) {
      Get.changeTheme(
        ThemeData.from(
          colorScheme:
              ColorScheme.fromSeed(seedColor: newPalette.dominantColor!.color),
          useMaterial3: true,
        ),
      );
    }
  }

  void clear() {
    palette.value = null;
  }
}
