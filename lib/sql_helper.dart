import 'package:sqflite/sqflite.dart' as sql;

class SQLHelper {
  //Future enables you to run tasks asynchronously in order to free up any other threads that shouldn't be blocked.
  static Future<void> createTables(sql.Database database) async {
    
    await database.execute("""CREATE TABLE diary(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        feeling TEXT,
        description TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      """);
  }
// id: the id of a diary
// feeling, description: emotion and description of your feeling
// created_at: the time that the diary was created. It will be automatically handled by SQLite

  static Future<sql.Database> db() async {
    return sql.openDatabase(
      'diary_siti_maisarah.db',
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      },
    );
  }

  // Create new diary (diaries)
  static Future<int> createDiary(String feeling, String? description) async {
    final db = await SQLHelper.db();

    final data = {'feeling': feeling, 'description': description};
    final id = await db.insert('diary', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  // Read all diaries
  static Future<List<Map<String, dynamic>>> getDiaries() async {
    final db = await SQLHelper.db();
    // Return newest entries first to match UI expectation.
    return db.query('diary', orderBy: "id DESC");
  }

  // Read a single diary by id
  // The app doesn't use this method but I put here in case you want to see it
  static Future<List<Map<String, dynamic>>> getDiary(int id) async {
    final db = await SQLHelper.db();
    return db.query('diary', where: "id = ?", whereArgs: [id], limit: 1);
  }

  // Update an diary by id
  static Future<int> updateDiary(
      int id, String feeling, String? description) async {
    final db = await SQLHelper.db();

    final data = {
      'feeling': feeling,
      'description': description,
      'createdAt': DateTime.now().toString()
    };

    final result =
        await db.update('diary', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  // Delete a  diary by id
  static Future<void> deleteDiary(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("diary", where: "id = ?", whereArgs: [id]);
    } catch (err) {
      // ignore: avoid_print
      print("Something went wrong when deleting a diary: $err");
    }
  }
}