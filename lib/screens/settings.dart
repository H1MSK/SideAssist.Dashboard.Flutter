// ignore_for_file: constant_identifier_names

import 'package:dashboard/config.dart';
import 'package:dashboard/manual_value_notifer.dart';
import 'package:dashboard/side_assist/side_assist.dart';
import 'package:dashboard/widgets/option.dart';
import 'package:dashboard/widgets/option_list.dart';
import 'package:flutter/foundation.dart';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';

import '../widgets/page.dart';

const List<String> accentColorNames = [
  'System',
  'Yellow',
  'Orange',
  'Red',
  'Magenta',
  'Purple',
  'Blue',
  'Teal',
  'Green',
];

bool get kIsWindowEffectsSupported {
  return !kIsWeb &&
      [
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.macOS,
      ].contains(defaultTargetPlatform);
}

const _LinuxWindowEffects = [
  WindowEffect.disabled,
  WindowEffect.transparent,
];

const _WindowsWindowEffects = [
  WindowEffect.disabled,
  WindowEffect.solid,
  WindowEffect.transparent,
  WindowEffect.aero,
  WindowEffect.acrylic,
  WindowEffect.mica,
  WindowEffect.tabbed,
];

const _MacosWindowEffects = [
  WindowEffect.disabled,
  WindowEffect.titlebar,
  WindowEffect.selection,
  WindowEffect.menu,
  WindowEffect.popover,
  WindowEffect.sidebar,
  WindowEffect.headerView,
  WindowEffect.sheet,
  WindowEffect.windowBackground,
  WindowEffect.hudWindow,
  WindowEffect.fullScreenUI,
  WindowEffect.toolTip,
  WindowEffect.contentBackground,
  WindowEffect.underWindowBackground,
  WindowEffect.underPageBackground,
];

List<WindowEffect> get currentWindowEffects {
  if (kIsWeb) return [];

  if (defaultTargetPlatform == TargetPlatform.windows) {
    return _WindowsWindowEffects;
  } else if (defaultTargetPlatform == TargetPlatform.linux) {
    return _LinuxWindowEffects;
  } else if (defaultTargetPlatform == TargetPlatform.macOS) {
    return _MacosWindowEffects;
  }

  return [];
}

class Settings extends ScrollablePage with OptionWidgetMixin, PageMixin {
  Settings({super.key});

  @override
  Widget buildHeader(BuildContext context) {
    return const PageHeader(title: Text('Settings'));
  }

  @override
  List<Widget> buildScrollable(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    var globalConfigMap = ManualValueNotifier(<NamedValue>[]);
    globalConfigMap.value
        .addAll(GlobalConfig.keys.map((e) => NamedValue.fromLocalValue(
              e,
              GlobalConfig.get(e),
              tryChangeValue: (value) {
                GlobalConfig.set(e, value);
              },
            )));

    return [
      Text('Server', style: FluentTheme.of(context).typography.subtitle),
      spacer,
      ClientOptionsWidget(globalConfigMap)
    ];
  }
}
