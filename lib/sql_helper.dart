import 'package:memo_book/group.dart';
import 'package:memo_book/task.dart';
import 'package:sqflite/sqflite.dart';

const int versionWtcDB = 3;

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();

  factory DBHelper() {
    return _instance;
  }

  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDB();
    return _database!;
  }

  final String dbpath = "wtc.db";

  Future<Database> initDB() async {
    String path = "${await getDatabasesPath()}/$dbpath";
    return await openDatabase(path, version: versionWtcDB, onCreate: (Database db, int version) async {
      await db.execute(createTableGroupSql);
      await db.execute(createTableTaskSql);
    });
  }
}
