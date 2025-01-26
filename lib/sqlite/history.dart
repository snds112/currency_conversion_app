import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


class History {
  final String from_curr;
  final String to_curr;
  final int vat;
  final String conversion_date;
  final String rate_date;
  final double input;
  final double result;

  const History({
    required this.from_curr,
    required this.to_curr,
    required this.vat,
    required this.conversion_date,
    required this.rate_date,
    required this.input,
    required this.result
  });
  @override
  String toString() {
    return '''
      From Currency: $from_curr
      To Currency: $to_curr
      VAT: ${vat.toString()}%
      Conversion Date: $conversion_date
      Rate Date: $rate_date
      Input Amount: ${input.toString()}
      Converted Amount: ${result.toString()}
    ''';
  }

  Map<String, Object?> toMap() {
    return {
      'from_curr': from_curr,
      'to_curr': to_curr,
      'vat': vat,
      'conversion_date': conversion_date,
      'rate_date': rate_date,
      'input': input,
      'result': result,
    };
  }

}
class HistorySqlite{

  static Database? _db;
  static final HistorySqlite instance = HistorySqlite._constructor();
  final String _tableName = "history";
  final String _tableFromCurrColumnName = "from_curr";
  final String _tableToCurrColumnName = "to_curr";
  final String _tableVatColumnName = "vat";
  final String _tableConversionDateColumnName = "conversion_date";
  final String _tableRateDateColumnName = "rate_date";
  final String _tableInputColumnName = "input";
  final String _tableResultColumnName = "result";


  HistorySqlite._constructor();

  Future<Database?> get database async {
    if (_db != null) {
      return _db;
    }
    _db = await getDatabase();
    return _db;
  }
  Future<Database> getDatabase() async {
    final dbDirPath = await getDatabasesPath();
    final dbPath = join(dbDirPath, "history_db.db");
    final database =
    await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE  $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        $_tableFromCurrColumnName TEXT NOT NULL,
        $_tableToCurrColumnName TEXT NOT NULL,
        $_tableVatColumnName INTEGER NOT NULL,
        $_tableConversionDateColumnName TEXT NOT NULL,
        $_tableRateDateColumnName TEXT NOT NULL,
        $_tableInputColumnName REAL NOT NULL,
        $_tableResultColumnName REAL NOT NULL
             
        );
        ''');
    });
    return database;
  }

  Future<bool> addHistory(History history) async {
    final db = await database;
    try {
      // Convert history object to a map
      Map<String, Object?> historyMap = history.toMap();

      // Insert the history data into the database
      await db?.insert(_tableName, historyMap);
      return true;
    } on DatabaseException catch (_) {
      return false;
    }
  }
  Future<List<History>> getHistory() async {
    final db = await database;
    final data = await db!.query(_tableName);

    // Check if any data is returned
    if (data.isEmpty) {
      return []; // Return empty list if no data found
    }

    // Convert each map entry to a History object
    List<History> historyList = data.map((e) => History(
      from_curr: e["from_curr"] as String,
      to_curr: e["to_curr"] as String,
      vat: e["vat"] as int,
      conversion_date: e["conversion_date"] as String,
      rate_date: e["rate_date"] as String,
      input: e["input"] as double,
      result: e["result"] as double,
    )).toList();

    return historyList;
  }
  Future<bool> deleteHistory(int id) async {
    final db = await database;
    try {
      await db!.delete(_tableName, where: 'id = ?', whereArgs: [id]);
      return true;
    } on DatabaseException catch (_) {
      return false;
    }
  }
  Future<bool> deleteAllHistory() async {
    final db = await database;
    try {
      await db!.delete(_tableName);
      return true;
    } on DatabaseException catch (_) {
      return false;
    }
  }
  Future<bool> deleteHistoryBatch(List<int> ids) async {
    final db = await database;
    try {
      // Create a list of placeholders for the WHERE IN clause
      List<String> placeholders = List.filled(ids.length, '?');
      String whereClause = 'id IN (${placeholders.join(',')})';

      // Execute the batch delete
      await db!.delete(_tableName, where: whereClause, whereArgs: ids);
      return true;
    } on DatabaseException catch (_) {
      return false;
    }
  }


}