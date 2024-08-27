part of '../database.dart';

class ColorConverter extends TypeConverter<Color, int> {
  const ColorConverter();

  @override
  Color fromSql(int fromDb) {
    return Color(fromDb);
  }

  @override
  int toSql(Color value) {
    return value.value;
  }
}

class RhythmColorConverter extends TypeConverter<RhythmColor, String> {
  const RhythmColorConverter();

  @override
  RhythmColor fromSql(String fromDb) {
    return RhythmColor.fromString(fromDb);
  }

  @override
  String toSql(RhythmColor value) {
    return value.toString();
  }
}
