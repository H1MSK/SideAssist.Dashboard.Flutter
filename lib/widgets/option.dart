import 'dart:io';
import 'dart:math';

import 'package:dashboard/side_assist/side_assist.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

import '../manual_value_notifer.dart';

class ClientOptionWidget extends StatefulWidget {
  final NamedValue option;
  final bool expanded;
  final void Function(bool expanded)? onStateChange;
  const ClientOptionWidget(this.option,
      {this.expanded = false, this.onStateChange, super.key});

  @override
  State<ClientOptionWidget> createState() => _ClientOptionWidgetState();
}

// ignore: unused_element
class _LastHalfLinear extends Curve {
  @override
  double transform(double t) => max(0, t * 2 - 1);
}

class _FirstHalfLinear extends Curve {
  @override
  double transform(double t) => min(1, t * 2);
}

class _ClientOptionWidgetState extends State<ClientOptionWidget> {
  bool expanded = false;
  late final bool valueChangable;
  late final bool valueChangeEnabled;
  bool editing = false;
  late final List<CommandBarButton> viewCommands;
  late final List<CommandBarButton> editCommands;
  dynamic newValue;

  Widget buildEditWidget(ValueType type, ValueMetaType? meta,
      dynamic initialValue, void Function(dynamic value) onChanged) {
    if (type.isList) {
      var itemType = type.itemType;
      var notifier =
          ManualValueNotifier(initialValue is List ? initialValue : []);
      dynamic newlyAddedValue;
      if (initialValue != notifier.value) onChanged(notifier.value);
      notifier.addListener(() => onChanged(notifier.value));
      return ValueListenableBuilder(
          valueListenable: notifier,
          builder: (context, List value, child) => ListView.builder(
              shrinkWrap: true,
              itemCount: value.length + 1,
              itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.all(4),
                    child: index == value.length
                        ? Row(children: [
                            Expanded(
                              child: buildEditWidget(itemType, meta, null,
                                  (value) => newlyAddedValue = value),
                            ),
                            Tooltip(
                              message: "Add new item",
                              useMousePosition: false,
                              child: IconButton(
                                icon: const Icon(FluentIcons.add),
                                onPressed: () {
                                  if (newlyAddedValue != null) {
                                    notifier.value.add(newlyAddedValue);
                                    newlyAddedValue = null;
                                    notifier.notifyListeners();
                                  }
                                },
                              ),
                            )
                          ])
                        : Row(
                            children: [
                              Expanded(
                                child: buildEditWidget(
                                    itemType, meta, value[index], (value) {
                                  notifier.value[index] = value;
                                  notifier.notifyListeners();
                                }),
                              ),
                              Tooltip(
                                message: "Delete this",
                                useMousePosition: false,
                                child: IconButton(
                                    icon: const Icon(FluentIcons.delete),
                                    onPressed: () {
                                      notifier.value.removeAt(index);
                                      notifier.notifyListeners();
                                    }),
                              )
                            ],
                          ),
                  )));
    }
    if (type.isStringMap) {
      var itemType = type.itemType;
      var notifier = ManualValueNotifier(initialValue is Map<String, dynamic>
          ? initialValue
          : <String, dynamic>{});
      dynamic newlyAddedName, newlyAddedValue;
      if (initialValue != notifier.value) onChanged(notifier.value);
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
      if (initialValue != checked) onChanged(checked);
      return ToggleSwitch(
        checked: checked,
        onChanged: onChanged,
        content: checked ? const Text("true") : const Text("false"),
      );
    } else if (type == ValueType.integerType) {
      if (initialValue is! int) {
        initialValue = 0;
        onChanged(initialValue);
      }
      return NumberBox(
        value: initialValue,
        onChanged: onChanged,
        mode: SpinButtonPlacementMode.inline,
      );
    } else if (type == ValueType.doubleType) {
      if (initialValue is! double) {
        initialValue = 0.0;
        onChanged(initialValue);
      }
      return NumberBox(
        value: initialValue,
        onChanged: (value) => onChanged(value),
        smallChange: 0.1,
        largeChange: 1,
      );
    } else if (type == ValueType.stringType) {
      if (initialValue is! String) {
        initialValue = "";
        onChanged(initialValue);
      }
      var textEditController = TextEditingController(text: initialValue);
      textEditController.addListener(() => onChanged(textEditController.text));
      return TextBox(controller: textEditController);
    } else if (type == ValueType.optionType) {
      meta = meta as OptionMetaType;
      if (!meta.options.contains(initialValue)) {
        initialValue = meta.options[0];
        onChanged(initialValue);
      }
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
      if (initialValue is! String) {
        initialValue = "";
        onChanged(initialValue);
      }
      var textEditController = TextEditingController(text: initialValue);
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
        widgets.add(Tooltip(
          message: "Pick a folder...",
          useMousePosition: false,
          child: IconButton(
              icon: const Icon(FluentIcons.folder_open),
              onPressed: () =>
                  FilePicker.platform.getDirectoryPath().then((value) {
                    if (value != null) textEditController.text = value;
                  })),
        ));
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

  void flushState() => setState(() {
        newValue = widget.option.value;
      });

  @override
  void dispose() {
    super.dispose();
    widget.option.valueNotifer.removeListener(flushState);
  }

  @override
  void initState() {
    super.initState();
    expanded = widget.expanded;
    newValue = widget.option.value;
    widget.option.valueNotifer.addListener(flushState);

    valueChangable = widget.option.isValueChangable;
    valueChangeEnabled = widget.option.isValueChangeEnabled;

    viewCommands = [
      if (widget.option.isValueChangable)
        CommandBarButton(
          icon: valueChangeEnabled
              ? const Icon(FluentIcons.edit)
              : const Icon(FluentIcons.blocked),
          label: Text(valueChangeEnabled ? "edit" : "uneditable"),
          onPressed: () => setState(() {
            editing = true;
          }),
        )
    ];
    editCommands = [
      CommandBarButton(
        icon: const Icon(FluentIcons.accept),
        label: const Text("accept"),
        onPressed: () => setState(() {
          widget.option.tryChangeValue!(newValue);
          editing = false;
        }),
      ),
      CommandBarButton(
        icon: const Icon(FluentIcons.cancel),
        label: const Text("cancel"),
        onPressed: () => setState(() {
          editing = false;
        }),
      )
    ];
  }

  Widget buildControls(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: expanded ? 300 : 0),
        child: CommandBar(
            mainAxisAlignment: MainAxisAlignment.end,
            primaryItems: editing
                ? editCommands
                : buildViewControls(widget.option.type, widget.option.meta,
                        widget.option.value) +
                    viewCommands),
      );

  @override
  Widget build(BuildContext context) {
    final appTheme = FluentTheme.of(context);
    return Expander(
      header: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.option.name,
                  style: appTheme.typography.bodyStrong,
                ),
                AnimatedSize(
                  duration: appTheme.mediumAnimationDuration,
                  curve: _FirstHalfLinear(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: !expanded ? double.infinity : 0),
                    child: Text(widget.option.value.toString(),
                        maxLines: 1,
                        style: appTheme.typography.body,
                        overflow: TextOverflow.ellipsis),
                  ),
                )
              ],
            ),
          )
        ],
      ),
      trailing: buildControls(context),
      content: AnimatedSize(
        duration: FluentTheme.of(context).mediumAnimationDuration,
        curve: Curves.easeOut,
        child: editing
            ? Card(
                padding: const EdgeInsets.all(0),
                child: IntrinsicWidth(
                  child: buildEditWidget(widget.option.type, widget.option.meta,
                      widget.option.value, (value) => newValue = value),
                ))
            : Text(widget.option.value.toString()),
      ),
      initiallyExpanded: widget.expanded,
      onStateChanged: (value) {
        setState(() {
          expanded = value;
          if (!expanded) editing = false;
          widget.onStateChange?.call(value);
        });
      },
    );
  }
}
