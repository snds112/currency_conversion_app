// ignore_for_file: unused_local_variable

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

enum darkModeEnum {system, dark, light} //use .name for string
extension ParseToString on darkModeEnum {
  String toShortString() {
    return toString().split('.').last;
  }
}

extension ParseFromString on String {
  darkModeEnum toDarkModeEnum() {
    switch (this) {
      case 'system':
        return darkModeEnum.system;
      case 'light':
        return darkModeEnum.light;
      case 'dark':
        return darkModeEnum.dark;
      default:
        return darkModeEnum.system; // Default value
    }
  }

}



class Settings{
  final darkModeEnum dark_mode;

  final int history;
  final String base_currency;
  final int vat;

  const Settings({
    required this.dark_mode,

    required this.history,
    required this.base_currency,
    required this.vat,
  });
  @override
  String toString() {
  return
    '''     dark mode : ${dark_mode.name},
            history : ${history.toString()},
            base currency : $base_currency,
            vat : ${vat.toString()},
    ''';
  }
  Map<String, Object?> toMap() {
    return {
      'dark_mode': dark_mode,
      'history': history,
      'base currency': base_currency,
      'vat': vat,
    };
  }
}

class SettingsSqlite{
  static Database? _db;
  static final SettingsSqlite instance = SettingsSqlite._constructor();
  final String _tableName = "settings";
  final String _tableDarkModeColumnName = "dark_mode";
  final String _tableHistoryColumnName = "history";
  final String _tableBaseCurrencyColumnName = "base_currency";
  final String _tableVatColumnName = "vat";
  Settings default_settings = const Settings(dark_mode: darkModeEnum.system, history: 0, base_currency: 'eur', vat: 20);

  SettingsSqlite._constructor();

  Future<Database?> get database async {
    if (_db != null) {
      return _db;
    }
    _db = await getDatabase();
    return _db;
  }
  Future<Database> getDatabase() async {
    final dbDirPath = await getDatabasesPath();
    final dbPath = join(dbDirPath, "settings_db.db");
    final database =
    await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE  $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        $_tableDarkModeColumnName TEXT NOT NULL,
        $_tableHistoryColumnName TEXT NOT NULL,
        $_tableBaseCurrencyColumnName TEXT NOT NULL,
        $_tableVatColumnName TEXT NOT NULL        
        );
        ''');
    });
    return database;
  }
  Future<void> initializeDefaultSettings() async {
    final db = await database;

    try {
      // Check if the settings table exists
      await db?.rawQuery('SELECT * FROM $_tableName LIMIT 1');
    } catch (e) {
      // If the table doesn't exist, insert default settings
      await insertDefaultSettings();
    }
  }
  Future<bool> addSettings(Settings s) async {
    final db = await database;
    try{var data = await db?.insert(_tableName, {
      _tableDarkModeColumnName: s.dark_mode.name,
      _tableHistoryColumnName: s.history.toString(),
      _tableBaseCurrencyColumnName: s.base_currency,
      _tableVatColumnName:s.vat.toString(),
    });}
    on DatabaseException catch (_)
    {return true;}
    return false;
  }

  Future<Settings> getSettings() async {
    final db = await database;
    final data = await db!.query(_tableName);

    if (data.isEmpty) {
      // Handle empty list (e.g., return default settings)
      addSettings(default_settings);
      return default_settings;
    }

    List<Settings> settings = data.map((e) => Settings(
      dark_mode:  (e["dark_mode"] as String).toDarkModeEnum(),
      history: int.tryParse(e["history"].toString()) ?? 0,
      base_currency: e["base_currency"] as String,
      vat: int.tryParse(e["vat"].toString()) ?? 0,
    )).toList();
    return settings.first;


  }
  Future<void> updateSettings(Settings settings) async{
    final db = await database;
    db?.update(_tableName,settings.toMap(),where: 'id = 1');
  }

  Future<void> insertDefaultSettings() async{
    final db = await database;

    addSettings(default_settings);

  }

}