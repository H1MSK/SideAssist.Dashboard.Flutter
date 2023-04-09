import 'dart:collection';

import 'package:dashboard/manual_value_notifer.dart';
import 'package:dashboard/side_assist/side_assist.dart';
import 'package:dashboard/side_assist/src/value_meta_type/path.dart';

class Client {
  final List<String> category;
  final String name;

  final indexedOptions = <String, NamedValue>{};
  final _options =
      ManualValueNotifier(SplayTreeSet<NamedValue>(NamedValue.nameComparator));
  final indexedParameters = <String, NamedValue>{};
  final _parameters =
      ManualValueNotifier(SplayTreeSet<NamedValue>(NamedValue.nameComparator));

  SplayTreeSet<NamedValue> get sortedOptions => _options.value;
  SplayTreeSet<NamedValue> get sortedParameters => _parameters.value;

  ManualValueNotifier<SplayTreeSet<NamedValue>> get optionsValueNotifier =>
      _options;
  ManualValueNotifier<SplayTreeSet<NamedValue>> get parametersValueNotifier =>
      _parameters;

  Client({required this.category, required this.name});

  NamedValue _createValue(String name,
          {void Function(dynamic)? tryChangeValue}) =>
      NamedValue(name, tryChangeValue: tryChangeValue);

  NamedValue _findOrCreateOption(String name) {
    if (indexedOptions.containsKey(name)) return indexedOptions[name]!;
    var theValue = _createValue(
      name,
      tryChangeValue: (value) {
        dashboard.changeOption(this, name, value);
      },
    );
    indexedOptions[name] = theValue;
    bool ret = sortedOptions.add(theValue);
    assert(ret);
    optionsValueNotifier.notifyListeners();
    return theValue;
  }

  NamedValue _findOrCreateParam(String name) {
    if (indexedParameters.containsKey(name)) return indexedParameters[name]!;
    var theValue = _createValue(name);
    indexedParameters[name] = theValue;
    bool ret = sortedParameters.add(theValue);
    assert(ret);
    parametersValueNotifier.notifyListeners();
    return theValue;
  }

  void _originUpdateValue(NamedValue value, dynamic obj) {
    value.originSetValue(obj);
  }

  void _originUpdateValueValidator(NamedValue value, dynamic validator) {
    if (validator is! Map<String, dynamic>) {
      value.setTypeAndMeta(ValueType.unknownType, null);
      return;
    }
    Map<String, dynamic> map = validator;
    try {
      if (map.containsKey("type")) {
        var item = map["type"];
        if (item is! String) throw ArgumentError;
        value.setTypeAndMeta(ValueType.fromString(item));
      } else if (map.containsKey("types")) {
        value.setTypeAndMeta(ValueType.unknownType);
        if (map["types"] is! List ||
            (map["types"] as List)
                .where((e) =>
                    e is! String ||
                    ValueType.fromString(e) == ValueType.unknownType)
                .isNotEmpty) throw ArgumentError;
      } else if (map.containsKey("path")) {
        var item = map["path"];
        if (item is! Map<String, dynamic>) throw ArgumentError;
        bool? existance;
        if (item.containsKey("existance")) {
          if (item["existance"] is! bool) throw ArgumentError;
          existance = (item["existance"] == true);
        }
        late final int minPerm, maxPerm;
        if (item.containsKey("perm")) {
          var perm = item["perm"];
          if (perm is! List ||
              perm.length != 2 ||
              perm[0] is! int ||
              perm[1] is! int ||
              perm[0] < 0 ||
              perm[1] > PathMetaType.sAllPerm ||
              perm[0] > perm[1]) {
            throw ArgumentError;
          }
          minPerm = perm[0];
          maxPerm = perm[1];
        } else {
          minPerm = 0;
          maxPerm = PathMetaType.sAllPerm;
        }
        late final int minType, maxType;
        if (item.containsKey("type")) {
          var type = item["type"];
          if (type is! List ||
              type.length != 2 ||
              type[0] is! int ||
              type[1] is! int ||
              type[0] < PathTypeEnum.Undefined.value ||
              type[0] > type[1] ||
              type[1] > PathTypeEnum.All.value) {
            throw ArgumentError;
          }
          minType = type[0];
          maxType = type[1];
        } else {
          minType = PathTypeEnum.Undefined.value;
          maxType = PathTypeEnum.All.value;
        }
        value.setTypeAndMeta(
            ValueType.pathType,
            PathMetaType(
                exist: existance,
                minPerm: minPerm,
                maxPerm: maxPerm,
                minType: PathTypeEnum.fromInt(minType),
                maxType: PathTypeEnum.fromInt(maxType)));
      } else if (map.containsKey("options")) {
        var item = map["options"];
        if (item is! List || !item.every((element) => element is String)) {
          throw ArgumentError;
        }
        value.setTypeAndMeta(
            ValueType.optionType, OptionMetaType(item.cast<String>()));
      } else if (map.containsKey("list")) {
        _originUpdateValueValidator(value, map["list"]);
        if (value.type.isList) {
          value.setTypeAndMeta(ValueType.unknownType);
        } else {
          value.setTypeAndMeta(ValueType.listTypeOf(value.type), value.meta);
        }
      } else {
        throw ArgumentError;
      }
    } on ArgumentError {
      value.setTypeAndMeta(ValueType.unknownType);
      rethrow;
    }
  }

  void originUpdateParam(String name, dynamic obj) {
    var param = _findOrCreateParam(name);
    _originUpdateValue(param, obj);
  }

  void originUpdateParamValidator(String name, dynamic validator) {
    var param = _findOrCreateParam(name);
    try {
      _originUpdateValueValidator(param, validator);
    } catch (e) {
      print(e);
    }
  }

  void originUpdateOption(String name, dynamic obj) {
    var option = _findOrCreateOption(name);
    _originUpdateValue(option, obj);
  }

  void originUpdateOptionValidator(String name, dynamic validator) {
    var option = _findOrCreateOption(name);
    try {
      _originUpdateValueValidator(option, validator);
    } catch (e) {
      print(e);
    }
  }
}
