part of '../database.dart';

class AuthenticationTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get spotifyCookie => text().map(EncryptedTextConverter())();
  TextColumn get spotifyAccessToken => text().map(EncryptedTextConverter())();
  DateTimeColumn get spotifyExpiration => dateTime()();
  TextColumn get neteaseCookie =>
      text().map(EncryptedTextConverter()).nullable()();
  DateTimeColumn get neteaseExpiration => dateTime().nullable()();
}
