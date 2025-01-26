// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

class Currency{
  final String short_name;
  final String long_name;
  final double rate;
  final int favorited;

  const Currency({
  required this.short_name,
  required this.long_name,
  required this.rate,
   required this.favorited


  });

  @override
  String toString() {

    return
      '''     
              short name : $short_name,
              long name : $long_name,
              rate : $rate,
              favorited = $favorited,
      ''';
  }
  Map<String, Object?> toMap() {
    return {
      'short name': short_name,
      'long name': long_name,
      'rate' : rate,
      'favorited': favorited
    };
  }
 /* factory Currency.fromJson(Map<String, dynamic> json) {
    // Extract code and name from the key-value pair
    String code = json.keys.first;
    String name = json[code] as String;
    return Currency(short_name: code, long_name: name, rate : 0.0);
  }
*/

  /*static List<Currency> buildCurrencyNamesList(String jsonString) {
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    return jsonData.entries.map((entry) {
      return Currency(short_name: entry.key, long_name: entry.value, rate : 0.0);
    }).toList();
  }*/
}


class CurrencySqlite{
  static Database? _db;
  static final CurrencySqlite instance = CurrencySqlite._constructor();
  final String _tableName = "currency";
  final String _tableShortNameColumnName = "short_name";
  final String _tableLongNameColumnName = "long_name";
  final String _tableRateColumnName = "rate";
  final String _tableFavoritedColumnName= "favorited";

  final String _CurrencyNamesListLink = 'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies.json';
  final String _CurrencyRatesListLink = 'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/';

  CurrencySqlite._constructor();

  Future<Database?> get database async {
    if (_db != null) {
      return _db;
    }
    _db = await getDatabase();
    return _db;
  }

  Future<Database> getDatabase() async {
    final dbDirPath = await getDatabasesPath();
    final dbPath = join(dbDirPath, "currency_db.db");
    final database =
    await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE  $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        $_tableShortNameColumnName TEXT UNIQUE NOT NULL,
        $_tableLongNameColumnName TEXT NOT NULL,
        $_tableRateColumnName REAL NOT NULL,
        $_tableFavoritedColumnName INTEGER DEFAULT 0   
        );
        
        CREATE INDEX idx_Currencies_Favorited ON Currencies ($_tableFavoritedColumnName);
        ''');
    });
    return database;
  }
  Future<bool> addCurrency(Currency c) async {
    final db = await database;
    try{var data = await db?.insert(_tableName, {
      _tableShortNameColumnName: c.short_name,
      _tableLongNameColumnName: c.long_name,
      _tableRateColumnName: c.rate.toString()
    });}
    on DatabaseException catch (_)
    {return true;}
    return false;
  }

  Future<List<Currency>> getCurrency() async {
    final db = await database;
    final data = await db!.query(_tableName);
    List<Currency> currency = data.map((e) => Currency(
      short_name:  e["short_name"] as String,
      long_name:  e["long_name"] as String,
      rate:  e["rate"] as double,
      favorited: e["favorited"] as int
    )).toList();
    return currency;
  }
  Future<List<Currency>> getFavoriteCurrency() async {
    final db = await database;
    final data = await db!.query(_tableName,where: "favorited = ?",whereArgs: ['1']);
    List<Currency> currency = data.map((e) => Currency(
        short_name:  e["short_name"] as String,
        long_name:  e["long_name"] as String,
        rate:  e["rate"] as double,
        favorited: e["favorited"] as int
    )).toList();
    return currency;
  }
  Future<List<Currency>> searchCurrency(String term) async {
    final db = await database;
    final data = await db!.query(_tableName,whereArgs:['%$term%','%$term%'],where:"short_name like ? or long_name like ?" );
    List<Currency> currency = data.map((e) => Currency(
        short_name:  e["short_name"] as String,
        long_name:  e["long_name"] as String,
        rate:  e["rate"] as double,
        favorited: e["favorited"] as int
    )).toList();

    return currency;

  }

  Future<void> updateCurrencyRate(Currency c) async{
    final db = await database;

    db?.update(_tableName,{'rate': c.rate.toString()},where: 'short_name = ?',whereArgs: [c.short_name]);
  }
  Future<void> updateCurrencyFavorited(Currency c,int favorited) async{
    final db = await database;

    db?.update(_tableName,{'favorited': favorited.toString()},where: 'short_name = ?',whereArgs: [c.short_name]);
  }
  Future<void> importAllCurrenciesToDb(String currencyShortName) async
  {
    final names = await http.get(Uri.parse(_CurrencyNamesListLink));
    final rates = await http.get(Uri.parse('$_CurrencyRatesListLink$currencyShortName.json'));
    final Map<String, dynamic> jsonDataNames = json.decode(names.body);
    final Map<String, dynamic> jsonDataRates = json.decode(rates.body)[currencyShortName];
    List<Currency> currencies = jsonDataNames.entries.map((entry) {
      return Currency(short_name: entry.key, long_name: entry.value, rate : jsonDataRates[entry.key].toDouble(), favorited: 0);
    }).toList();
    for (var currency in currencies){
      addCurrency(currency);
    }
  }

  Future<List<Currency>> importConversionCurrenciesByDate(String baseCurrencyShortName,String date,Currency c1, Currency c2) async
  {

    final rates = await http.get(Uri.parse('https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@$date/v1/currencies/$baseCurrencyShortName.json'));
    final Map<String, dynamic> jsonDataRates = json.decode(rates.body)[baseCurrencyShortName];

    Currency newc1 = Currency(short_name: c1.short_name, long_name: c1.long_name, rate:jsonDataRates[c1.short_name].toDouble() , favorited: c1.favorited);
    Currency newc2 = Currency(short_name: c2.short_name, long_name: c2.long_name, rate:jsonDataRates[c2.short_name].toDouble() , favorited: c2.favorited);
    return [newc1,newc2];

  }




  Future<void> updateAllCurrencyRatesInDb(String currencyShortName) async {
    final names = await http.get(Uri.parse(_CurrencyNamesListLink));
    final rates = await http.get(Uri.parse('$_CurrencyRatesListLink$currencyShortName.json'));
    final Map<String, dynamic> jsonDataNames = json.decode(names.body);
    final Map<String, dynamic> jsonDataRates = json.decode(rates.body)[currencyShortName];
    List<Currency> currencies = jsonDataNames.entries.map((entry) {
      return Currency(short_name: entry.key, long_name: entry.value, rate : jsonDataRates[entry.key].toDouble(), favorited: 0);
    }).toList();
    for (var currency in currencies){
      updateCurrencyRate(currency);
    }
  }
}


