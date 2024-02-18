import 'dart:developer';

import 'package:sqflite/sqflite.dart';

const String tableWtcTask = 'wtc_task';
const String columnId = '_id';
const String columnContent = 'content';
const String columnCreatedTime = 'createdTime';
const String columnStatus = 'status';
const String columnSeq = 'seq';

class WtcTask {
  WtcTask(
      {required this.id, required this.content, required this.createdTime, required this.status, required this.seq});

  int? id;
  String? content;
  DateTime? createdTime;
  TaskStatus? status;
  int? seq;

  Map<String, Object?> toMap() {
    var map = <String, Object?>{
      columnContent: content,
      columnCreatedTime: createdTime!.millisecondsSinceEpoch,
      columnStatus: status!.index,
      columnSeq: seq
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  WtcTask.fromMap(Map<String, Object?> map) {
    id = map[columnId] as int?;
    content = map[columnContent] as String?;
    createdTime = DateTime.fromMillisecondsSinceEpoch(map[columnCreatedTime] as int);
    status = TaskStatus.values[map[columnStatus] as int];
    seq = map[columnSeq] as int?;
  }
}

enum TaskStatus {
  wait,
  finish;
}

class WtcTaskService {
  final String path = "wtc";
  WtcTaskProvider wtcTaskProvider = WtcTaskProvider();

  Future open() async {}

  Future close() async {}

  Future<WtcTask> insert(WtcTask task) async {
    await wtcTaskProvider.open(path);
    task = await wtcTaskProvider.insert(task);
    await wtcTaskProvider.close();
    return task;
  }

  Future<int> delete(int id) async {
    await wtcTaskProvider.open(path);
    int result = await wtcTaskProvider.delete(id);
    await wtcTaskProvider.close();
    return result;
  }

  Future<WtcTask> update(WtcTask task) async {
    await wtcTaskProvider.open(path);
    await wtcTaskProvider.update(task);
    await wtcTaskProvider.close();
    return task;
  }

  Future<List<WtcTask>?> listWtcTask(int pageNum, int pageSize, int? status) async {
    await wtcTaskProvider.open(path);
    List<WtcTask>? list = await wtcTaskProvider.listWtcTask(pageNum, pageSize, status);
    await wtcTaskProvider.close();
    return list;
  }
}

class WtcTaskProvider {
  late Database db;

  Future open(String path) async {
    db = await openDatabase(path, version: 1, onCreate: (Database db, int version) async {
      await db.execute('''
create table $tableWtcTask ( 
  $columnId integer primary key autoincrement, 
  $columnContent text not null,
  $columnCreatedTime integer not null,
  $columnStatus integer not null,
  $columnSeq integer not null)
''');
    });
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

  Future<List<WtcTask>?> listWtcTask(int pageNum, int pageSize, int? status) async {
    List<Map<String, Object?>> maps;
    if (status == null) {
      maps = await db.query(tableWtcTask,
          columns: [columnId, columnContent, columnCreatedTime, columnStatus, columnSeq],
          orderBy: "$columnId desc",
          limit: pageSize,
          offset: (pageNum - 1) * pageSize);
    } else {
      maps = await db.query(tableWtcTask,
          columns: [columnId, columnContent, columnCreatedTime, columnStatus, columnSeq],
          where: "$columnStatus = ?",
          whereArgs: [status!],
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

  Future close() async => db.close();
}
