import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:dashboard/side_assist/side_assist.dart';
import 'package:dashboard/manual_value_notifer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

class EditWidgetMixin {
  Widget buildEditWidget(ValueType type, ValueMetaType? meta,
      dynamic initialValue, void Function(dynamic value) onChanged) {
    if (type.isList) {
      var itemType = type.itemType;
      var notifier =
          ManualValueNotifier(initialValue is List ? initialValue : []);
      dynamic newlyAddedValue;
      notifier.addListener(() => onChanged(notifier.value));
      return ValueListenableBuilder(
          valueListenable: notifier,
          builder: (context, List value, child) => ListView.builder(
              shrinkWrap: true,
              itemCount: value.length + 1,
              itemBuilder: (context, index) => index == value.length
                  ? Row(children: [
                      Expanded(
                        child: buildEditWidget(itemType, meta, null,
                            (value) => newlyAddedValue = value),
                      ),
                      IconButton(
                        icon: const Icon(FluentIcons.add),
                        onPressed: () {
                          if (newlyAddedValue != null) {
                            notifier.value.add(newlyAddedValue);
                            newlyAddedValue = null;
                            notifier.notifyListeners();
                          }
                        },
                      )
                    ])
                  : Row(
                      children: [
                        Expanded(
                          child: buildEditWidget(itemType, meta, value[index],
                              (value) {
                            notifier.value[index] = value;
                            notifier.notifyListeners();
                          }),
                        ),
                        IconButton(
                            icon: const Icon(FluentIcons.delete),
                            onPressed: () {
                              notifier.value.removeAt(index);
                              notifier.notifyListeners();
                            })
                      ],
                    )));
    }
    if (type.isStringMap) {
      var itemType = type.itemType;
      var notifier = ManualValueNotifier(initialValue is Map<String, dynamic>
          ? initialValue
          : <String, dynamic>{});
      dynamic newlyAddedName, newlyAddedValue;
      notifier.addListener(() => onChanged(notifier.value));
      return ValueListenableBuilder(
          valueListenable: notifier,
          builder: (context, Map<String, dynamic> theMap, child) {
            var entryList = theMap.entries.toList(growable: false);
            return ListView.builder(
                shrinkWrap: true,
                itemCount: theMap.length + 1,
                itemBuilder: (context, index) => index == theMap.length
                    ? Row(children: [
                        Expanded(
                          child: buildEditWidget(ValueType.stringType, null,
                              null, (value) => newlyAddedName = value),
                        ),
                        Expanded(
                          child: buildEditWidget(itemType, meta, null,
                              (value) => newlyAddedValue = value),
                        ),
                        IconButton(
                          icon: const Icon(FluentIcons.add),
                          onPressed: () {
                            if (newlyAddedValue != null) {
                              if (theMap.containsKey(newlyAddedName)) {
                                // TODO: log
                                return;
                              }
                              notifier.value[newlyAddedName] = newlyAddedValue;
                              newlyAddedName = null;
                              newlyAddedValue = null;
                              notifier.notifyListeners();
                            }
                          },
                        )
                      ])
                    : Row(
                        children: [
                          buildEditWidget(ValueType.stringType, null, null,
                              (value) {
                            if (theMap.containsKey(value)) {
                              // TODO: log
                              return;
                            }
                            var val = theMap.remove(value);
                            theMap[value] = val;
                            notifier.notifyListeners();
                          }),
                          buildEditWidget(
                              itemType, meta, entryList[index].value, (value) {
                            notifier.value[entryList[index].key] = value;
                            notifier.notifyListeners();
                          }),
                          IconButton(
                              icon: const Icon(FluentIcons.delete),
                              onPressed: () {
                                notifier.value.remove(entryList[index].key);
                                notifier.notifyListeners();
                              })
                        ],
                      ));
          });
    }
    if (type == ValueType.boolType) {
      bool checked = initialValue == true;
      return ToggleSwitch(
        checked: checked,
        onChanged: onChanged,
        content: checked ? const Text("true") : const Text("false"),
      );
    } else if (type == ValueType.integerType) {
      return NumberBox(
        value: initialValue is int ? initialValue : 0,
        onChanged: onChanged,
        mode: SpinButtonPlacementMode.inline,
      );
    } else if (type == ValueType.doubleType) {
      var textEditController =
          TextEditingController(text: initialValue.toString());
      String savedValue = initialValue;
      textEditController.addListener(() {
        if (textEditController.text.contains(RegExp(r'[^\d.]')) ||
            textEditController.text.allMatches('.').length > 1) {
          textEditController.text = savedValue;
        } else {
          savedValue = textEditController.text;
          onChanged(savedValue);
        }
      });
      return TextBox(controller: textEditController);
    } else if (type == ValueType.stringType) {
      var textEditController =
          TextEditingController(text: initialValue.toString());
      textEditController.addListener(() => onChanged(textEditController.text));
      return TextBox(controller: textEditController);
    } else if (type == ValueType.optionType) {
      var notifier = ManualValueNotifier(initialValue);
      notifier.addListener(() => onChanged(notifier.value));
      return ValueListenableBuilder(
        valueListenable: notifier,
        builder: (context, savedValue, child) => ComboBox(
            value: savedValue,
            items: (meta as OptionMetaType)
                .options
                .map((e) => ComboBoxItem(child: Text(e), value: e))
                .toList(growable: false),
            onChanged: (value) {
              if (value is String) {
                notifier.value = value;
                notifier.notifyListeners();
              }
            }),
      );
    } else if (type == ValueType.pathType) {
      var textEditController =
          TextEditingController(text: initialValue.toString());
      textEditController.addListener(() => onChanged(textEditController.text));
      var widgets = <Widget>[
        Expanded(child: TextBox(controller: textEditController))
      ];
      meta = meta as PathMetaType;
      if (meta.isOpenFile) {
        widgets.add(IconButton(
            icon: const Icon(FluentIcons.open_file),
            onPressed: () => FilePicker.platform.pickFiles().then((value) {
                  if (value == null) return;
                  var path = value.files.single.path;
                  if (path != null) textEditController.text = path;
                })));
      } else if (meta.isSaveFile &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        widgets.add(IconButton(
            icon: const Icon(FluentIcons.open_folder_horizontal),
            onPressed: () => FilePicker.platform.saveFile().then((value) {
                  if (value != null) textEditController.text = value;
                })));
      } else if (meta.isDir && !kIsWeb) {
        widgets.add(IconButton(
            icon: const Icon(FluentIcons.folder_open),
            onPressed: () =>
                FilePicker.platform.getDirectoryPath().then((value) {
                  if (value != null) textEditController.text = value;
                })));
      }
      return Row(children: widgets);
    } else {
      var textEditController =
          TextEditingController(text: initialValue.toString());
      textEditController.addListener(() => onChanged(textEditController.text));
      return TextBox(controller: textEditController);
    }
  }

  List<CommandBarButton> buildViewControls(
      ValueType type, ValueMetaType? meta, dynamic value) {
    var list = <CommandBarButton>[];
    if (type.value == ValueType.pathType.value) {
      meta = meta as PathMetaType;
      if (meta.isOpenFile || meta.isExistedDir) {
        list.add(CommandBarButton(
          icon: const Icon(FluentIcons.open_file),
          label: const Text("open"),
          onPressed: () => OpenFilex.open(value as String),
        ));
      }
    }
    list.add(
      CommandBarButton(
          icon: const Icon(FluentIcons.copy),
          label: const Text("copy"),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value.toString()));
          }),
    );
    return list;
  }
}
