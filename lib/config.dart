import 'package:dashboard/manual_value_notifer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalConfig {
  static late final ManualValueNotifier<SharedPreferences> _prefs;

  static dynamic get(String name) {
    return _prefs.value.get(name);
  }

  static Set<String> get keys => _prefs.value.getKeys();

  static void set(String name, dynamic value) {
    if (value is bool) {
      _prefs.value.setBool(name, value);
    } else if (value is int) {
      _prefs.value.setInt(name, value);
    } else if (value is double) {
      _prefs.value.setDouble(name, value);
    } else if (value is String) {
      _prefs.value.setString(name, value);
    } else if (value is List &&
        value.where((element) => element is! String).isEmpty) {
      _prefs.value.setStringList(name, value.cast());
    } else {
      assert(false);
    }
    _prefs.notifyListeners();
  }

  static Future<void> init(Map<String, dynamic> initial) async {
    _prefs = ManualValueNotifier(await SharedPreferences.getInstance());
    var existedKeys = _prefs.value.getKeys();
    for (var entry in initial.entries) {
      if (!existedKeys.contains(entry.key)) {
        if (entry.value is bool) {
          _prefs.value.setBool(entry.key, entry.value);
        } else if (entry.value is int) {
          _prefs.value.setInt(entry.key, entry.value);
        } else if (entry.value is double) {
          _prefs.value.setDouble(entry.key, entry.value);
        } else if (entry.value is String) {
          _prefs.value.setString(entry.key, entry.value);
        } else if (entry.value is List &&
            (entry.value as List)
                .where((element) => element is! String)
                .isEmpty) {
          _prefs.value.setStringList(entry.key, entry.value);
        } else {
          assert(false);
        }
      }
    }
  }
}
