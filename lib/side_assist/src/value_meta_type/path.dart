// ignore_for_file: constant_identifier_names

import 'value_validator.dart';

enum PathTypeEnum {
  Undefined(0),
  File(1),
  Dir(2),
  All(3);

  final int value;
  const PathTypeEnum(this.value);

  factory PathTypeEnum.fromInt(int v) {
    for (var supported in values) {
      if (supported.value == v) return supported;
    }
    throw ArgumentError.value(v);
  }

  bool get isFile => value == File.value;
  bool get isDir => value == Dir.value;
}

class PathMetaType extends ValueMetaType {
  static const int sReadable = 4;
  static const int sWritable = 2;
  static const int sExecutable = 1;
  static const int sAllPerm = 7;
  final bool? exist;
  final int minPerm, maxPerm;
  final PathTypeEnum minType, maxType;

  PathMetaType(
      {this.exist,
      this.minPerm = 0,
      this.maxPerm = sAllPerm,
      this.minType = PathTypeEnum.Undefined,
      this.maxType = PathTypeEnum.All}) {
    if (minPerm < 0 || maxPerm > sAllPerm || minPerm > maxPerm) {
      throw ArgumentError.value(
          [minPerm, maxPerm], "permission", "invalid range");
    }
    if (minType.value < 0 ||
        maxType.value > PathTypeEnum.All.value ||
        minType.value > maxType.value) {
      throw ArgumentError.value([minType, maxType], "type", "invalid range");
    }
  }

  bool get isFile =>
      minType == PathTypeEnum.File && maxType == PathTypeEnum.File;

  bool get isDir => minType == PathTypeEnum.Dir && maxType == PathTypeEnum.Dir;

  bool get isOpenFile =>
      exist == true && sReadable == (minPerm & sReadable) && isFile;

  bool get isSaveFile =>
      exist == null && sWritable == (minPerm & sWritable) && isFile;

  bool get isExistedDir => exist == true && isDir;
}
