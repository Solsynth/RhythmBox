import 'dart:async';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/database.dart';
import 'package:rhythm_box/services/database/database.dart';

class RecentlyPlayedProvider extends GetxController {
  Future<List<HistoryTableData>> fetch() async {
    final database = Get.find<DatabaseProvider>().database;

    final uniqueItemIds = await (database.selectOnly(
      database.historyTable,
      distinct: true,
    )
          ..addColumns([database.historyTable.itemId, database.historyTable.id])
          ..where(
            database.historyTable.type.isInValues([
              HistoryEntryType.playlist,
              HistoryEntryType.album,
            ]),
          )
          ..limit(10)
          ..orderBy([
            OrderingTerm(
              expression: database.historyTable.createdAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .map(
          (row) => row.read(database.historyTable.id),
        )
        .get()
        .then((value) => value.whereNotNull().toList());

    final query = database.select(database.historyTable)
      ..where(
        (tbl) => tbl.id.isIn(uniqueItemIds),
      )
      ..orderBy([
        (tbl) => OrderingTerm(
              expression: tbl.createdAt,
              mode: OrderingMode.desc,
            ),
      ]);

    final fetchedItems = await query.get();
    return fetchedItems;
  }
}
