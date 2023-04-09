import 'package:shared_preferences/shared_preferences.dart';

late final SharedPreferences prefs;

void initDefault(Map<String, dynamic> initial) {
  var existedKeys = prefs.getKeys();
  for (var entry in initial.entries) {
    if (!existedKeys.contains(entry.key)) {
      if (entry.value is bool) {
        prefs.setBool(entry.key, entry.value);
      } else if (entry.value is int) {
        prefs.setInt(entry.key, entry.value);
      } else if (entry.value is double) {
        prefs.setDouble(entry.key, entry.value);
      } else if (entry.value is String) {
        prefs.setString(entry.key, entry.value);
      } else if (entry.value is List &&
          (entry.value as List)
              .where((element) => element is! String)
              .isEmpty) {
        prefs.setStringList(entry.key, entry.value);
      } else {
        assert(false);
      }
    }
  }
}

Future<void> initConfig() async {
  prefs = await SharedPreferences.getInstance();
  initDefault({"server.host": "localhost", "server.port": 1883});
}
