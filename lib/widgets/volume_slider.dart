import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/volume.dart';

class VolumeSlider extends StatelessWidget {
  final MainAxisAlignment mainAxisAlignment;

  const VolumeSlider({
    super.key,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final VolumeProvider vol = Get.find();

      final slider = Listener(
        onPointerSignal: (event) async {
          if (event is PointerScrollEvent) {
            if (event.scrollDelta.dy > 0) {
              final newValue = vol.volume.value - .2;
              vol.setVolume(newValue < 0 ? 0 : newValue);
            } else {
              final newValue = vol.volume.value + .2;
              vol.setVolume(newValue > 1 ? 1 : newValue);
            }
          }
        },
        child: SliderTheme(
          data: SliderThemeData(
            showValueIndicator: ShowValueIndicator.always,
            trackShape: _VolumeSliderShape(),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 6,
            ),
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            min: 0,
            max: 1,
            label: (vol.volume.value * 100).toStringAsFixed(0),
            value: vol.volume.value,
            onChanged: vol.setVolume,
          ),
        ),
      ).paddingSymmetric(horizontal: 8);
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        children: [
          IconButton(
            icon: Icon(
              vol.volume.value == 0
                  ? Icons.volume_off
                  : vol.volume.value <= 0.5
                      ? Icons.volume_down
                      : Icons.volume_up,
              size: 18,
            ),
            onPressed: () {
              if (vol.volume.value == 0) {
                vol.setVolume(1);
              } else {
                vol.setVolume(0);
              }
            },
          ),
          slider,
        ],
      );
    });
  }
}

class _VolumeSliderShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight!) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
