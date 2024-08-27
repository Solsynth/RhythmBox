import 'package:get/get.dart';
import 'package:palette_generator/palette_generator.dart';

class PaletteProvider extends GetxController {
  final Rx<PaletteGenerator?> palette = Rx<PaletteGenerator?>(null);

  void updatePalette(PaletteGenerator? newPalette) {
    palette.value = newPalette;
  }

  void clear() {
    palette.value = null;
  }
}
