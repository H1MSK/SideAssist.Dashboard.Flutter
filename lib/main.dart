import 'dart:io';

import 'package:dashboard/config.dart';
import 'package:dashboard/screens/settings.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Page;
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:flutter_acrylic/window_effect.dart';
import 'package:go_router/go_router.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:provider/provider.dart';
import 'package:system_theme/system_theme.dart';
import 'package:window_manager/window_manager.dart';
import 'package:dashboard/side_assist/side_assist.dart';

import 'theme.dart';
import 'pages.dart';

const String appTitle = 'Win UI for Flutter';

/// Checks if the current environment is a desktop environment.
bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

final appTheme = AppTheme();

void main() async {
  await GlobalConfig.init([
    NamedValue("server.host", value: "localhost"),
    NamedValue("server.port", value: 1883),
    NamedValue("server.username", value: "side_assist_dashboard"),
    NamedValue("server.password", value: "16509490"),
    NamedValue("theme.mode",
        value: ThemeMode.system.name,
        type: ValueType.optionType,
        meta: OptionMetaType(
            ThemeMode.values.map((e) => e.name).toList(growable: false)),
        tryChangeValue: (value) => appTheme.mode = ThemeMode.values.firstWhere(
            (element) => element.name == value,
            orElse: () => appTheme.mode)),
    NamedValue(
      "theme.windowEffects",
      value: (Platform.isWindows ? WindowEffect.acrylic : WindowEffect.disabled)
          .name,
      type: ValueType.optionType,
      meta: OptionMetaType(currentWindowEffects.isEmpty
          ? [WindowEffect.disabled.name]
          : currentWindowEffects.map((e) => e.name).toList(growable: false)),
      tryChangeValue: (value) => appTheme.windowEffect = WindowEffect.values
          .firstWhere((element) => element.name == value,
              orElse: () => appTheme.windowEffect),
    ),
  ]);
  dashboard.initialize();
  Pages.initialize();
  var future = dashboard.connect(
      GlobalConfig.get("server.username"), GlobalConfig.get("server.password"));

  WidgetsFlutterBinding.ensureInitialized();

  // if it's not on the web, windows or android, load the accent color
  if (!kIsWeb &&
      [
        TargetPlatform.windows,
        TargetPlatform.android,
      ].contains(defaultTargetPlatform)) {
    SystemTheme.accentColor.load();
  }

  if (isDesktop) {
    await flutter_acrylic.Window.initialize();
    await flutter_acrylic.Window.hideWindowControls();
    await WindowManager.instance.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      );
      await windowManager.setMinimumSize(const Size(500, 600));
      await windowManager.show();
      await windowManager.setPreventClose(true);
      await windowManager.setSkipTaskbar(false);
    });
  }

  var state = await future;

  if (state?.state != MqttConnectionState.connected) exit(1);

  runApp(const MyApp());

  Future.wait([
    // DeferredWidget.preload(popups.loadLibrary),
    // DeferredWidget.preload(forms.loadLibrary),
    // DeferredWidget.preload(inputs.loadLibrary),
    // DeferredWidget.preload(navigation.loadLibrary),
    // DeferredWidget.preload(surfaces.loadLibrary),
    // DeferredWidget.preload(theming.loadLibrary),
  ]);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  // private navigators

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => appTheme,
      builder: (context, _) {
        final appTheme = context.watch<AppTheme>();
        return FluentApp.router(
          title: appTitle,
          themeMode: appTheme.mode,
          debugShowCheckedModeBanner: false,
          color: appTheme.color,
          darkTheme: FluentThemeData(
            brightness: Brightness.dark,
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen() ? 2.0 : 0.0,
            ),
          ),
          theme: FluentThemeData(
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen() ? 2.0 : 0.0,
            ),
          ),
          locale: appTheme.locale,
          builder: (context, child) {
            return Directionality(
              textDirection: appTheme.textDirection,
              child: NavigationPaneTheme(
                data: NavigationPaneThemeData(
                  backgroundColor: appTheme.windowEffect !=
                          flutter_acrylic.WindowEffect.disabled
                      ? Colors.transparent
                      : null,
                ),
                child: child!,
              ),
            );
          },
          routeInformationParser: Pages.router.routeInformationParser,
          routerDelegate: Pages.router.routerDelegate,
          routeInformationProvider: Pages.router.routeInformationProvider,
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
    required this.child,
    required this.shellContext,
    required this.state,
  }) : super(key: key);

  final Widget child;
  final BuildContext? shellContext;
  final GoRouterState state;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WindowListener {
  bool value = false;

  // int index = 0;

  final viewKey = GlobalKey(debugLabel: 'Navigation View Key');
  final searchKey = GlobalKey(debugLabel: 'Search Bar Key');
  final searchFocusNode = FocusNode();
  final searchController = TextEditingController();

  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  int topIndex = 0;

  @override
  Widget build(BuildContext context) {
    final localizations = FluentLocalizations.of(context);

    final appTheme = context.watch<AppTheme>();
    if (widget.shellContext != null) {
      if (Pages.router.canPop() == false) {
        setState(() {});
      }
    }
    return ValueListenableBuilder(
        valueListenable: Pages.generatedPaneItemsNotifier,
        builder: (context, List<NavigationPaneItem> generatedPaneItems, _) =>
            NavigationView(
              key: viewKey,
              appBar: NavigationAppBar(
                automaticallyImplyLeading: false,
                leading: () {
                  final enabled =
                      widget.shellContext != null && Pages.router.canPop();

                  final onPressed = enabled
                      ? () {
                          if (Pages.router.canPop()) {
                            context.pop();
                            setState(() {});
                          }
                        }
                      : null;
                  return NavigationPaneTheme(
                    data: NavigationPaneTheme.of(context)
                        .merge(NavigationPaneThemeData(
                      unselectedIconColor: ButtonState.resolveWith((states) {
                        if (states.isDisabled) {
                          return ButtonThemeData.buttonColor(context, states);
                        }
                        return ButtonThemeData.uncheckedInputColor(
                          FluentTheme.of(context),
                          states,
                        ).basedOnLuminance();
                      }),
                    )),
                    child: Builder(
                      builder: (context) => PaneItem(
                        icon: const Center(
                            child: Icon(FluentIcons.back, size: 12.0)),
                        title: Text(localizations.backButtonTooltip),
                        body: const SizedBox.shrink(),
                        enabled: enabled,
                      ).build(
                        context,
                        false,
                        onPressed,
                        displayMode: PaneDisplayMode.compact,
                      ),
                    ),
                  );
                }(),
                title: () {
                  if (kIsWeb) {
                    return const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(appTitle),
                    );
                  }
                  return const DragToMoveArea(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(appTitle),
                    ),
                  );
                }(),
                actions: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      if (!kIsWeb) WindowButtons(),
                    ]),
              ),
              paneBodyBuilder: (item, child) {
                final name = item?.key is ValueKey
                    ? (item!.key as ValueKey).value
                    : null;
                return FocusTraversalGroup(
                  key: ValueKey('body$name'),
                  child: widget.child,
                );
              },
              pane: NavigationPane(
                onChanged: (value) => topIndex = value,
                selected: topIndex,
                displayMode: appTheme.displayMode,
                indicator: () {
                  switch (appTheme.indicator) {
                    case NavigationIndicators.end:
                      return const EndNavigationIndicator();
                    case NavigationIndicators.sticky:
                    default:
                      return const StickyNavigationIndicator();
                  }
                }(),
                items: Pages.originalItems + generatedPaneItems,
                autoSuggestBox: AutoSuggestBox(
                  key: searchKey,
                  focusNode: searchFocusNode,
                  controller: searchController,
                  unfocusedColor: Colors.transparent,
                  items: _recursivePaneItemToAutoSuggestBoxItem(
                          (Pages.originalItems + Pages.generatedPaneItems)
                              .whereType<PaneItem>())
                      .toList(growable: false),
                  trailingIcon: IgnorePointer(
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(FluentIcons.search),
                    ),
                  ),
                  placeholder: 'Search',
                ),
                autoSuggestBoxReplacement: const Icon(FluentIcons.search),
                footerItems: Pages.footerItems,
              ),
              onOpenSearch: () {
                searchFocusNode.requestFocus();
              },
            ));
  }

  Iterable<AutoSuggestBoxItem<String>> _recursivePaneItemToAutoSuggestBoxItem(
      Iterable<NavigationPaneItem> items) sync* {
    for (var item in items) {
      if (item is! PaneItem) continue;
      assert(item.title is Text);
      final text = (item.title as Text).data!;
      yield AutoSuggestBoxItem(
        label: text,
        value: text,
        onSelected: () {
          item.onTap?.call();
          searchController.clear();
        },
      );
      if (item is PaneItemExpander) {
        yield* _recursivePaneItemToAutoSuggestBoxItem(item.items);
      }
    }
  }

  @override
  void onWindowClose() async {
    bool _isPreventClose = await windowManager.isPreventClose();
    if (_isPreventClose) {
      showDialog(
        context: context,
        builder: (_) {
          return ContentDialog(
            title: const Text('Confirm close'),
            content: const Text('Are you sure you want to close this window?'),
            actions: [
              FilledButton(
                child: const Text('Yes'),
                onPressed: () {
                  Navigator.pop(context);
                  windowManager.destroy();
                },
              ),
              Button(
                child: const Text('No'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    }
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);

    return SizedBox(
      width: 138,
      height: 50,
      child: WindowCaption(
        brightness: theme.brightness,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
