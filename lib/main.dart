// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

//sqlite
import 'package:currency_conversion/sqlite/currency.dart';
import 'package:currency_conversion/sqlite/settings.dart';
import 'package:currency_conversion/sqlite/history.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database and populate it with API data

  await SettingsSqlite.instance.initializeDefaultSettings();
  Settings settings = await SettingsSqlite.instance.getSettings();

  await CurrencySqlite.instance.importAllCurrenciesToDb(settings.base_currency);

  runApp(MaterialApp(
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: CurrencyConversion(settings: settings)));
}

class HistoryCard extends StatelessWidget {
  final History history;

  const HistoryCard({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.rate_date == '') {
      return const Card(
        elevation: 2,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '',
                        ),
                        Text(
                          "",
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '',
                        ),
                        Text(
                          '',
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '',
                        ),
                        Text(
                          '',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${history.from_curr} to ${history.to_curr}',
                      ),
                      Text(
                        "On: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(history.conversion_date))}",
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'VAT: ${history.vat}%',
                      ),
                      Text(
                        'Rate date: ${history.rate_date}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Input: ${history.input.toStringAsFixed(2)}',
                      ),
                      Text(
                        'Result: ${history.result.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurrencyConversion extends StatefulWidget {
  final Settings settings;

  const CurrencyConversion({super.key, required this.settings});

  @override
  State<CurrencyConversion> createState() => _CurrencyConversionState();
}

class _CurrencyConversionState extends State<CurrencyConversion> {
  late Settings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  DateTime? _selectedDate;

  Currency _from_conversion =
      const Currency(short_name: 'n/a', long_name: '', rate: 0, favorited: 0);
  Currency _to_conversion =
      const Currency(short_name: 'n/a', long_name: '', rate: 0, favorited: 0);
  final String _from_select = "n/a";
  final String _to_select = "n/a";

  bool _conversion_search_option = false; //false means from and true means to

  int _stack_index = 0;
  int _index = 0;
  final _input_controller = TextEditingController();
  final _currency_search_controller = TextEditingController();
  final _explore_currency_search_controller = TextEditingController();
  final _custom_vat_controller = TextEditingController();
  bool _custom_vat = false;
  bool _custom_date = true;
  bool _show_result = false;
  String _currency_conversion_search_term = "";
  String _explore_currency_conversion_search_term = "";
  final CurrencySqlite _currencysqlite = CurrencySqlite.instance;
  final HistorySqlite _historysqlite = HistorySqlite.instance;
  final int _input_vat = 0;
  String _conversion_result = '';

  @override
  Widget build(BuildContext context) {
    //homepage
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Conversion'),
        backgroundColor: Colors.deepPurple.shade200,
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _stack_index,
        children: [
          _convertPage(),
          _explorePage(),
          _settingsPage(),
          _historyPage(),
          _currencyConversionSearchPage()
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _showFloatingActionButtons(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: "convert",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "explore"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "settings"),
        ],
        currentIndex: _index,
        onTap: (int index) {
          setState(() {
            debugPrint(_settings.toString());
            _stack_index = index;
            _index = index;
          });
        },
      ),
    );
  }

  List<FloatingActionButton> _showFloatingActionButtons() {
    if (_stack_index == 0) {
      List<FloatingActionButton> list = [];
      list.add(FloatingActionButton(
        onPressed: _clearAllConvertPage,
        child: const Icon(Icons.clear),
      ));
      if (_settings.history == 1) {
        list.add(FloatingActionButton(
          onPressed: () {
            _switchToPage(3);
          },
          child: const Icon(Icons.history),
        ));
      }

      return list;
    }else if (_stack_index == 1) {
      return [
        FloatingActionButton(
          onPressed: (){setState(() {
            _explore_currency_search_controller.clear();
          });},
          child: const Icon(Icons.keyboard_return_rounded),
        ),

      ];
    }
    else if (_stack_index == 3) {
      return [
        FloatingActionButton(
          onPressed: _clearHistory,
          child: const Icon(Icons.clear),
        ),
        FloatingActionButton(
          onPressed: () {
            _switchToPage(0);
          },
          child: const Icon(Icons.home_filled),
        ),
      ];
    }
    return [];
  }

  Widget _convertPage() {
    return Container(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.deepPurple.shade100),
              child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(
                              signed: false, decimal: true),
                          decoration: const InputDecoration(
                            label: Text("input:"),
                          ),
                          controller: _input_controller,
                        ),
                      ),
                    ),
                    FloatingActionButton(
                        onPressed: () => setState(() {
                              _input_controller.clear();
                            }),
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.clear))
                  ]),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.deepPurple.shade100),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _conversion_search_option = false;
                        _stack_index = 4;
                      });
                    },
                    backgroundColor: Colors.white,
                    child: Text(_from_conversion.short_name),
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        Currency temp = Currency(
                            short_name: _from_conversion.short_name,
                            long_name: _from_conversion.long_name,
                            rate: _from_conversion.rate,
                            favorited: 0);

                        _from_conversion = Currency(
                            short_name: _to_conversion.short_name,
                            long_name: _to_conversion.long_name,
                            rate: _to_conversion.rate,
                            favorited: 0);
                        _to_conversion = Currency(
                            short_name: temp.short_name,
                            long_name: temp.long_name,
                            rate: temp.rate,
                            favorited: 0);
                      });
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.swap_horiz),
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _conversion_search_option = true;
                        _stack_index = 4;
                      });
                    },
                    backgroundColor: Colors.white,
                    child: Text(_to_conversion.short_name),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 24),
                    child: FloatingActionButton(
                      onPressed: () {
                        _clearCurrencySelection();
                      },
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.clear),
                    ),
                  ),
                ],
              ),
            ),
            _showOptions(),
            _showConvertResult(),
            Container(
              margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.deepPurple.shade100),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextButton(
                        onPressed: () {
                          _convert();
                          setState(() {
                            _show_result = true;
                          });
                        },
                        child: const Text('Convert',
                            style: TextStyle(fontSize: 20))),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _historyPage() {
    return FutureBuilder<List<History>>(
      future: HistorySqlite.instance.getHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
              child: Text('Error loading history: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          List<History> historyList = snapshot.data!;
          historyList.add(const History(
              from_curr: '',
              to_curr: '',
              vat: 0,
              conversion_date: '',
              rate_date: '',
              input: 0,
              result: 0));
          return ListView.builder(
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              return HistoryCard(history: historyList[index]);
            },
          );
        } else {
          return const Center(child: Text('No history found.'));
        }
      },
    );
  }

  Widget _explorePage() {
    return Container(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.deepPurple.shade100),
              child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                        child: TextField(
                          decoration: const InputDecoration(
                            label: Text("search:"),
                          ),
                          controller: _explore_currency_search_controller,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                      child: FloatingActionButton(
                          onPressed: () => setState(() {
                                _explore_currency_conversion_search_term =
                                    _explore_currency_search_controller.text;
                              }),
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.search)),
                    )
                  ]),
            ),
            _showCurrencySearchResultsTable(),
          ],
        ),
      ),
    );
  }

  Widget _settingsPage() {
    return const Placeholder();
  }

  Widget _showVatInputField() {
    _custom_vat_controller.text = _settings.vat.toString();
    if (_custom_vat) {
      return SizedBox(
        width: 50,
        child: TextField(
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(
              signed: false, decimal: true),
          controller: _custom_vat_controller,
        ),
      );
    } else {
      return Container();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      debugPrint(_from_conversion.toString());
      debugPrint(_to_conversion.toString());
      Currency c1, c2;

      setState(() {
        _selectedDate = picked;
      });
      [c1, c2] = await CurrencySqlite.instance.importConversionCurrenciesByDate(
          _settings.base_currency,
          selectedDateFormatted!,
          _from_conversion,
          _to_conversion);
      setState(() {
        _from_conversion = c1;
        _to_conversion = c2;
        debugPrint(_from_conversion.toString());
        debugPrint(_to_conversion.toString());
      });
    }
  }

  String? get selectedDateFormatted {
    if (_selectedDate == null) return null;
    return DateFormat('yyyy-MM-dd').format(_selectedDate!);
  }

  Widget _showDateInputField() {
    if (!_custom_date) {
      return GestureDetector(
        onTap: () => _selectDate(context),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Text(
            _selectedDate != null
                ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                : 'Select Date',
            style: const TextStyle(fontSize: 16.0),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Container _showConvertResult() {
    if (_show_result) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.deepPurple.shade100),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _conversion_result,
              style: const TextStyle(fontSize: 20),
            )
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  _convert() async {
    double rate = _to_conversion.rate / _from_conversion.rate;
    double input = (double.tryParse(_input_controller.text) ?? 0);
    double result = (double.tryParse(_input_controller.text) ?? 0) * rate;
    double vat = 0;
    if (_custom_vat) {
      vat = (int.tryParse(_custom_vat_controller.text) ?? 0) * result / 100.0;
    }
    debugPrint(result.toString());
    debugPrint(vat.toString());
    result = result + vat;
    setState(() {
      _conversion_result = result.toStringAsFixed(3);
    });
    History history = History(
        from_curr: _from_conversion.short_name,
        to_curr: _to_conversion.short_name,
        vat: (int.tryParse(_custom_vat_controller.text) ?? 0),
        conversion_date: DateFormat('yyyy-MM-dd')
            .format(DateTime.parse(DateTime.now().toString())),
        rate_date: DateFormat('yyyy-MM-dd')
            .format(DateTime.parse(_selectedDate.toString())),
        input: input,
        result: result);
    await _historysqlite.addHistory(history);
  }

  _clearCurrencySelection() {
    setState(() {
      _from_conversion = const Currency(
          short_name: 'n/a', long_name: '', rate: 0, favorited: 0);
      _to_conversion = const Currency(
          short_name: 'n/a', long_name: '', rate: 0, favorited: 0);
    });
  }

  _clearAllConvertPage() {
    setState(() {
      _selectedDate = DateTime.now();
      _show_result = false;
      _from_conversion = const Currency(
          short_name: 'n/a', long_name: '', rate: 0, favorited: 0);
      _to_conversion = const Currency(
          short_name: 'n/a', long_name: '', rate: 0, favorited: 0);
      _input_controller.clear();
      _custom_vat_controller.clear();
      _currency_search_controller.clear();
      _custom_vat = false;
      _custom_date = true;
    });
  }

  Widget _showCurrencyConversionSearchResultsTable() {
    return FutureBuilder(
        future:
            _currencysqlite.searchCurrency(_currency_conversion_search_term),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            List<Currency> currencies = snapshot.data!;

            return Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: currencies.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            leading: Text(currencies[index].short_name),
                            title: Text(currencies[index].long_name),
                            subtitle: Text('Rate: ${currencies[index].rate}'),
                            onTap: () {
                              setState(() {
                                _currency_search_controller.clear();
                                _stack_index = 0;
                                if (_conversion_search_option) {
                                  _to_conversion = currencies[index];
                                } else {
                                  _from_conversion = currencies[index];
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        });
  }

  Widget _currencyConversionSearchPage() {
    return Container(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.deepPurple.shade100),
              child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                        child: TextField(
                          decoration: const InputDecoration(
                            label: Text("input:"),
                          ),
                          controller: _currency_search_controller,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                      child: FloatingActionButton(
                          onPressed: () => setState(() {
                                _currency_conversion_search_term =
                                    _currency_search_controller.text;
                              }),
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.search)),
                    )
                  ]),
            ),
            _showCurrencyConversionSearchResultsTable(),
          ],
        ),
      ),
    );
  }

  Container _showOptions() {
    if (_from_conversion.short_name != 'n/a' &&
        _to_conversion.short_name != 'n/a') {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.deepPurple.shade100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                        value: _custom_vat,
                        onChanged: (bool? ispressed) {
                          setState(() {
                            _custom_vat = ispressed!;
                          });
                        }),
                    const Text(
                      'Add VAT?',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                _showVatInputField()
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                        value: _custom_date,
                        onChanged: (bool? ispressed) {
                          setState(() {
                            _custom_date = ispressed!;
                            if (!_custom_date) {
                              _selectedDate = DateTime.now();
                            }
                          });
                        }),
                    const Text(
                      'Latest?',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                _showDateInputField()
              ],
            ),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  void _switchToPage(int index) {
    setState(() {
      _stack_index = index;
    });
  }

  void _clearHistory() async {
    await _historysqlite.deleteAllHistory();
    _switchToPage(0);
  }

  Widget _showCurrencySearchResultsTable() {
    return FutureBuilder(
        future: (_explore_currency_search_controller.text.isNotEmpty)
            ? _currencysqlite
                .searchCurrency(_explore_currency_conversion_search_term)
            : _currencysqlite
                .getFavoriteCurrency(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            List<Currency> currencies = snapshot.data!;

            return Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: currencies.length,
                      itemBuilder: (context, index) {
                       bool isFavorited = currencies[index].favorited==1;
                      Currency c = currencies[index];
                        return Card(
                          child: ListTile(
                            leading: Text(currencies[index].short_name),
                            title: Text(currencies[index].long_name),
                            subtitle: Text('Rate: ${currencies[index].rate}'),
                            trailing: IconButton(
                              icon: Icon(
                                isFavorited ? Icons.star : Icons.star_border,
                                color: isFavorited ? Colors.yellow.shade700 : null
                              ),
                              onPressed: () async{
                                int newfav = isFavorited ? 0:1;
                                await _currencysqlite.updateCurrencyFavorited(c, newfav);
                                debugPrint(c.toString());
                                debugPrint((!isFavorited).toString());
                                setState(() {

                                });
                              },
                            ),
                            onTap: () {},
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        });
  }
}
