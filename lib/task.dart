import 'dart:developer';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:memo_book/sql_helper.dart';
import 'package:sqflite/sqflite.dart';

const String tableWtcTask = 'wtc_task';
const String columnId = '_id';
const String columnContent = 'content';
const String columnCreatedTime = 'createdTime';
const String columnStatus = 'status';
const String columnSeq = 'seq';
const String columnGroupId = 'groupId';
const String createTableTaskSql = '''
          create table $tableWtcTask ( 
            $columnId integer primary key autoincrement, 
            $columnContent text not null,
            $columnCreatedTime integer not null,
            $columnStatus integer not null,
            $columnSeq integer not null,
            $columnGroupId integer)
          ''';

class WtcTask {
  WtcTask(
      {required this.id,
      required this.content,
      required this.createdTime,
      required this.status,
      required this.seq,
      this.groupId});

  int? id;
  String? content;
  DateTime? createdTime;
  TaskStatus? status;
  int? seq;
  int? groupId;

  Map<String, Object?> toMap() {
    var map = <String, Object?>{
      columnContent: content,
      columnCreatedTime: createdTime!.millisecondsSinceEpoch,
      columnStatus: status!.index,
      columnSeq: seq,
    };
    if (groupId != null) {
      map[columnGroupId] = groupId;
    }
    if (id != null) {
      map[columnId] = id;
    }
    log("$map");
    return map;
  }

  WtcTask.fromMap(Map<String, Object?> map) {
    id = map[columnId] as int?;
    content = map[columnContent] as String?;
    createdTime = DateTime.fromMillisecondsSinceEpoch(map[columnCreatedTime] as int);
    status = TaskStatus.values[map[columnStatus] as int];
    seq = map[columnSeq] as int?;
    groupId = map[columnGroupId] as int?;
  }
}

enum TaskStatus {
  wait,
  finish;
}

class WtcTaskService {
  WtcTaskProvider wtcTaskProvider = WtcTaskProvider();

  Future open() async {
    await wtcTaskProvider.open().onError((error, stackTrace) {
      SmartDialog.showToast("open table error", displayTime: const Duration(seconds: 3));
    });
  }

  Future close() async {
    await wtcTaskProvider.close();
  }

  Future<WtcTask> insert(WtcTask task) async {
    task = await wtcTaskProvider.insert(task);
    return task;
  }

  Future<int> delete(int id) async {
    int result = await wtcTaskProvider.delete(id);
    return result;
  }

  Future<WtcTask> update(WtcTask task) async {
    await wtcTaskProvider.update(task);
    return task;
  }

  Future<List<WtcTask>?> listWtcTask(int pageNum, int pageSize, int? status, int? groupId) async {
    List<WtcTask>? list = await wtcTaskProvider.listWtcTask(pageNum, pageSize, status, groupId);
    return list;
  }

  Future<int> queryMaxId() async {
    return await wtcTaskProvider.maxId();
  }
}

class WtcTaskProvider {
  late Database db;

  Future open() async {
    db = await DBHelper().database;
  }

  Future<WtcTask> insert(WtcTask task) async {
    task.id = await db.insert(tableWtcTask, task.toMap());
    return task;
  }

  Future<WtcTask?> getWtcTask(int id) async {
    List<Map<String, Object?>> maps = await db.query(tableWtcTask,
        columns: [columnId, columnContent, columnCreatedTime, columnStatus, columnSeq],
        where: '$columnId = ?',
        whereArgs: [id]);
    if (maps.isNotEmpty) {
      return WtcTask.fromMap(maps.first);
    }
    return null;
  }

  Future<List<WtcTask>?> listWtcTask(int pageNum, int pageSize, int? status, int? groupId) async {
    List<Map<String, Object?>> maps;
    if (status == null && groupId == null) {
      maps = await db.query(tableWtcTask,
          columns: [columnId, columnContent, columnCreatedTime, columnStatus, columnSeq],
          orderBy: "$columnId desc",
          limit: pageSize,
          offset: (pageNum - 1) * pageSize);
    } else if (status != null && groupId == null) {
      maps = await db.query(tableWtcTask,
          columns: [columnId, columnContent, columnCreatedTime, columnStatus, columnSeq],
          where: "$columnStatus = ?",
          whereArgs: [status],
          orderBy: "$columnId desc",
          limit: pageSize,
          offset: (pageNum - 1) * pageSize);
    } else if (status == null && groupId != null) {
      maps = await db.query(tableWtcTask,
          columns: [columnId, columnContent, columnCreatedTime, columnStatus, columnSeq],
          where: "$columnGroupId = ?",
          whereArgs: [groupId],
          orderBy: "$columnId desc",
          limit: pageSize,
          offset: (pageNum - 1) * pageSize);
    } else {
      maps = await db.query(tableWtcTask,
          columns: [columnId, columnContent, columnCreatedTime, columnStatus, columnSeq],
          where: "$columnGroupId = ? and $columnStatus = ?",
          whereArgs: [groupId, status],
          orderBy: "$columnId desc",
          limit: pageSize,
          offset: (pageNum - 1) * pageSize);
    }

    log("list num:${maps.length}");
    List<WtcTask>? result = maps.map((e) => WtcTask.fromMap(e)).toList();
    return result;
  }

  Future<int> delete(int id) async {
    return await db.delete(tableWtcTask, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> update(WtcTask task) async {
    return await db.update(tableWtcTask, task.toMap(), where: '$columnId = ?', whereArgs: [task.id]);
  }

  Future<int> maxId() async {
    List<Map<String, dynamic>> result = await db.rawQuery('SELECT MAX($columnId) as maxId FROM $tableWtcTask');
    int maxId = result.isNotEmpty ? (result.first['maxId'] ?? 0) as int : 0;
    return maxId;
  }

  Future close() async => db.close();
}
