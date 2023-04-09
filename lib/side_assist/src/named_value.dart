import 'package:dashboard/manual_value_notifer.dart';

import 'value_meta_type/value_validator.dart';

class ValueType {
  // Treated as json value
  static const unknownType = ValueType(0x00);

  //
  static const nullType = ValueType(0x01);
  static const boolType = ValueType(0x02);
  static const integerType = ValueType(0x03);
  static const doubleType = ValueType(0x04);
  static const stringType = ValueType(0x05);

  static const optionType = ValueType(0x11);
  static const constraintedIntegerType = ValueType(0x12);
  static const constraintedDoubleType = ValueType(0x13);
  static const urlType = ValueType(0x14);
  static const pathType = ValueType(0x15);
  static const blobType = ValueType(0x16);

  static const listType = ValueType(0x1000);
  static const stringMapType = ValueType(0x2000);

  static const int plainTypeField = 0x000F;
  static const int typeField = 0x00FF;
  static const int attributeBitField = 0xFF00;

  final int value;

  const ValueType(this.value);

  factory ValueType.findDefault(int v) {
    if (v == unknownType.value) return unknownType;
    if (v == nullType.value) return nullType;
    if (v == boolType.value) return boolType;
    if (v == integerType.value) return integerType;
    if (v == doubleType.value) return doubleType;
    if (v == stringType.value) return stringType;
    if (v == optionType.value) return optionType;
    if (v == constraintedIntegerType.value) return constraintedIntegerType;
    if (v == constraintedDoubleType.value) return constraintedDoubleType;
    if (v == urlType.value) return urlType;
    if (v == pathType.value) return pathType;
    if (v == blobType.value) return blobType;
    throw ArgumentError.value(v);
  }

  ValueType get itemType => (value & ~typeField) == 0
      ? this
      : ValueType.findDefault(value & typeField);

  bool get itemIsPlainType =>
      (itemType.value | plainTypeField) == plainTypeField;

  bool get isPlainType => (value | plainTypeField) == plainTypeField;

  bool get isList => (value & listType.value) == listType.value;
  bool get isStringMap => (value & listType.value) == listType.value;

  bool isListOf(ValueType v) => isList && itemType == v;
  bool isStringMapOf(ValueType v) => isStringMap && itemType == v;

  String? plainTypeToString() {
    if (value == nullType.value) return "Null";
    if (value == boolType.value) return "Bool";
    if (value == integerType.value) return "Integer";
    if (value == doubleType.value) return "Double";
    if (value == stringType.value) return "String";
    if (value == listType.value) return "Array";
    if (value == stringMapType.value) return "Object";
    return null;
  }

  factory ValueType.fromString(String str) {
    if (str == "Null") return nullType;
    if (str == "Bool") return boolType;
    if (str == "Integer") return integerType;
    if (str == "Double") return doubleType;
    if (str == "String") return stringType;
    if (str == "Array") return listType;
    if (str == "Object") return stringMapType;
    return unknownType;
  }

  factory ValueType.fromType(Type type) {
    if (type == Null) return nullType;
    if (type == bool) return boolType;
    if (type == int) return integerType;
    if (type == double) return doubleType;
    if (type == String) return stringType;
    if (type == List) return listType;
    if (type == Object) return stringMapType;
    return unknownType;
  }

  static ValueType listTypeOf(ValueType type) {
    assert((type.value & listType.value) == 0);
    return ValueType(type.value | listType.value);
  }
}

class NamedValue {
  static int nameComparator(NamedValue a, NamedValue b) {
    return a.name.compareTo(b.name);
  }

  final String name;
  ValueType _type;
  ValueMetaType? _meta;
  final ManualValueNotifier<dynamic> _value;
  final void Function(dynamic value)? tryChangeValue;

  NamedValue(this.name,
      {ValueType type = ValueType.unknownType,
      dynamic value,
      this.tryChangeValue,
      ValueMetaType? meta})
      : _type = type,
        _value = ManualValueNotifier(value),
        _meta = meta;

  NamedValue.fromLocalValue(this.name, dynamic value, {this.tryChangeValue})
      : _value = ManualValueNotifier(value),
        _type = ValueType.fromType(value.runtimeType);

  ValueType get type => _type;
  ValueMetaType? get meta => _meta;

  dynamic get value => _value.value;
  ManualValueNotifier<dynamic> get valueNotifer => _value;

  bool get isValueChangable => tryChangeValue != null;
  bool get isValueChangeEnabled => _type != ValueType.nullType;

  void originSetValue(dynamic v) {
    if (_value.value == v) return;
    _value.value = v;
    _value.notifyListeners();
  }

  void setTypeAndMeta(ValueType type, [ValueMetaType? meta]) {
    _type = type;
    _meta = meta;
  }
}
