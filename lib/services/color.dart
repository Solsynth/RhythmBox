import 'dart:ui';

class RhythmColor extends Color {
  final String name;

  const RhythmColor(super.color, {required this.name});

  const RhythmColor.from(super.value, {required this.name});

  factory RhythmColor.fromString(String string) {
    final slices = string.split(':');
    return RhythmColor(int.parse(slices.last), name: slices.first);
  }

  @override
  String toString() {
    return '$name:$value';
  }
}
