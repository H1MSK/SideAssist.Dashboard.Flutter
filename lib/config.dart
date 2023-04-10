import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:dashboard/manual_value_notifer.dart';
import 'package:dashboard/side_assist/side_assist.dart';
import 'package:path_provider/path_provider.dart';

class GlobalConfig {
  static final indexedConfig = <String, NamedValue>{};
  static final sortedConfigNotifier =
      ManualValueNotifier(SplayTreeSet<NamedValue>(NamedValue.nameComparator));

  static SplayTreeSet<NamedValue> get sortedConfig =>
      sortedConfigNotifier.value;

  static dynamic get(String name) {
    return indexedConfig[name]?.value;
  }

  static bool savingInProcess = false;

  static Future<void> _saveToFile() async {
    if (savingInProcess) return;
    savingInProcess = true;
    var data = jsonEncode(
        indexedConfig.map((key, value) => MapEntry(key, value.value)));
    var dir = await getApplicationDocumentsDirectory();
    File(dir.path + '/config.json').writeAsStringSync(data);
    savingInProcess = false;
  }

  static Future<void> _loadFromFile() async {
    late Directory dir;
    if (Platform.isAndroid || Platform.isIOS) {
      dir = await getApplicationDocumentsDirectory();
    } else {
      dir = Directory.current;
    }
    try {
      var data = File(dir.path + '/config.json').readAsStringSync();
      var map = jsonDecode(data);
      if (map is! Map) return;
      for (var entry in map.entries) {
        if (indexedConfig.containsKey(entry.key)) {
          indexedConfig[entry.key]!.tryChangeValue!(entry.value);
          continue;
        }
        print("Loaded an unfamiliar entry: ${entry.key}: ${entry.value}");
      }
      // ignore: empty_catches
    } on PathNotFoundException {}
  }

  static void set(String name, dynamic value) {
    if (indexedConfig.containsKey(name)) {
      indexedConfig[name]!.tryChangeValue!(value);
    } else {
      // Do not allow new entry creation
      assert(false);
      // var namedValue = NamedValue(name);
      // namedValue.originSetValue(value);
      // indexedConfig[name] = namedValue;
      // bool ret = sortedConfig.add(namedValue);
      // assert(ret);
    }
    sortedConfigNotifier.notifyListeners();
    _saveToFile();
  }

  static Future<void> init(Iterable<NamedValue> initial) async {
    initial = _preprocessInitialValue(initial);
    indexedConfig.addEntries(initial.map((e) => MapEntry(e.name, e)));
    sortedConfig.addAll(initial);
    await _loadFromFile();
    sortedConfigNotifier.notifyListeners();
  }

  static List<NamedValue> _preprocessInitialValue(
      Iterable<NamedValue> initial) {
    var list = <NamedValue>[];
    for (var item in initial) {
      var name = item.name;
      var fun = item.tryChangeValue;
      list.add(NamedValue(name, type: item.type, meta: item.meta,
          tryChangeValue: (value) {
        fun?.call(value);
        indexedConfig[name]!.originSetValue(value);
        _saveToFile();
      }, value: item.value));
    }
    return list;
  }
}
