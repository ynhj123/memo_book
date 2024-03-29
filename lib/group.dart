import 'dart:developer';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:memo_book/sql_helper.dart';
import 'package:sqflite/sqflite.dart';

const String tableWtcGroup = 'wtc_group';
const String columnId = '_id';
const String columnName = 'name';
const String columnSeq = 'seq';

const String createTableGroupSql = '''
          create table $tableWtcGroup ( 
            $columnId integer primary key autoincrement, 
            $columnName text not null,
            $columnSeq integer not null)
          ''';

class WtcGroup {
  WtcGroup({required this.id, required this.name, required this.seq});

  int? id;
  String? name;

  int? seq;

  Map<String, Object?> toMap() {
    var map = <String, Object?>{columnName: name, columnSeq: seq};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  WtcGroup.fromMap(Map<String, Object?> map) {
    id = map[columnId] as int?;
    name = map[columnName] as String?;
    seq = map[columnSeq] as int?;
  }
}

class WtcGroupService {
  WtcGroupProvider wtcGroupProvider = WtcGroupProvider();

  Future open() async {
    await wtcGroupProvider.open().onError((error, stackTrace) {
      SmartDialog.showToast("open table error", displayTime: const Duration(seconds: 3));
    });
  }

  Future close() async {
    await wtcGroupProvider.close();
  }

  Future<WtcGroup> insert(WtcGroup group) async {
    group = await wtcGroupProvider.insert(group);
    return group;
  }

  Future<int> delete(int id) async {
    int result = await wtcGroupProvider.delete(id);
    return result;
  }

  Future<WtcGroup> update(WtcGroup task) async {
    await wtcGroupProvider.update(task);
    return task;
  }

  Future<List<WtcGroup>?> listWtcGroup() async {
    List<WtcGroup>? list = await wtcGroupProvider.listWtcGroup();
    return list;
  }

  Future<int> queryMaxId() async {
    return await wtcGroupProvider.maxId();
  }
}

class WtcGroupProvider {
  late Database db;

  Future open() async {
    db = await DBHelper().database;
  }

  Future<WtcGroup> insert(WtcGroup group) async {
    group.id = await db.insert(tableWtcGroup, group.toMap());
    return group;
  }

  Future<WtcGroup?> getWtcGroup(int id) async {
    List<Map<String, Object?>> maps = await db.query(tableWtcGroup,
        columns: [columnId, columnName, columnSeq], where: '$columnId = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return WtcGroup.fromMap(maps.first);
    }
    return null;
  }

  Future<List<WtcGroup>?> listWtcGroup() async {
    List<Map<String, Object?>> maps;
    maps = await db.query(
      tableWtcGroup,
      columns: [columnId, columnName, columnSeq],
      orderBy: "$columnId asc",
    );

    log("list num:${maps.length}");
    List<WtcGroup>? result = maps.map((e) => WtcGroup.fromMap(e)).toList();
    return result;
  }

  Future<int> delete(int id) async {
    return await db.delete(tableWtcGroup, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> update(WtcGroup group) async {
    return await db.update(tableWtcGroup, group.toMap(), where: '$columnId = ?', whereArgs: [group.id]);
  }

  Future<int> maxId() async {
    List<Map<String, Object?>> result = await db.rawQuery('SELECT MAX($columnId) as maxId FROM $tableWtcGroup');
    for (var element in result) {
      log("$element");
    }
    int maxId = result.isNotEmpty ? (result.first['maxId'] ?? 0) as int : 0;
    return maxId;
  }

  Future close() async => db.close();
}
