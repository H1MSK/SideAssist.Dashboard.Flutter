import 'package:flutter/foundation.dart';

class ManualValueNotifier<T> extends ChangeNotifier
    implements ValueNotifier<T> {
  ManualValueNotifier(this._value);

  @override
  T get value => _value;
  T _value;

  @override
  set value(T newValue) {
    if (_value == newValue) {
      return;
    }
    _value = newValue;
  }

  @override
  // To disable @visibleForTesting
  // ignore: unnecessary_overrides
  void notifyListeners() {
    super.notifyListeners();
  }
}
