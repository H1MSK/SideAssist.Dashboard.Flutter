import 'package:dashboard/main.dart';
import 'package:dashboard/manual_value_notifer.dart';
import 'package:dashboard/screens/category.dart';
import 'package:dashboard/screens/home.dart';
import 'package:dashboard/side_assist/side_assist.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'screens/client.dart';
import 'screens/settings.dart';

class Pages {
  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();
  static late final GoRouter router;

  static final List<NavigationPaneItem> originalItems = [
    PaneItem(
      key: const Key('/'),
      icon: const Icon(FluentIcons.home),
      title: const Text('Home'),
      body: const SizedBox.shrink(),
      onTap: () {
        if (Pages.router.location != '/') {
          Pages.router.push('/');
        }
      },
    ),
  ];

  static final List<NavigationPaneItem> footerItems = [
    PaneItem(
      key: const Key('/settings'),
      icon: const Icon(FluentIcons.settings_secure),
      title: const Text('Settings'),
      body: const SizedBox.shrink(),
      onTap: () {
        if (Pages.router.location != '/settings') {
          Pages.router.push('/settings');
        }
      },
    )
  ];

  static final initialRoutes = [
    /// Home
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),

    /// Settings
    GoRoute(
      path: '/settings',
      builder: (context, state) => Settings(),
    ),
    // ...PageInfo.generatedRoutes
  ];

  static void initialize() {
    router = GoRouter(
      navigatorKey: rootNavigatorKey,
      routes: [
        ShellRoute(
            navigatorKey: _shellNavigatorKey,
            builder: (context, state, child) {
              return MyHomePage(
                child: child,
                shellContext: _shellNavigatorKey.currentContext,
                state: state,
              );
            },
            routes: <RouteBase>[...initialRoutes]),
      ],
    );
    dashboard.clientsNotifier.addListener(() {
      var shellRoute = router.routeInformationParser.configuration.routes[0];
      shellRoute.routes.removeRange(2, shellRoute.routes.length);
      _regeneratePaneItemsAndRoutes();
      shellRoute.routes.addAll(generatedRoutes);
      generatedPaneItemsNotifier.notifyListeners();
    });
  }

  static void _regeneratePaneItemsAndRoutes() {
    generatedPaneItems.clear();
    var lastCategory = <String>[];
    PaneItemExpander? expander;
    for (var client in dashboard.orderedClients) {
      if (!listEquals(lastCategory, client.category)) {
        lastCategory = client.category;
        if (client.category.isEmpty) {
          expander = null;
        } else {
          var routePath = '/category/' + client.category.join('/');
          expander = PaneItemExpander(
            key: Key(routePath),
            icon: const Icon(FluentIcons.all_apps),
            title: Text(client.category.join('.')),
            items: [],
            body: const SizedBox.shrink(),
            onTap: () {
              if (router.location != routePath) {
                router.push(routePath);
              }
            },
          );
          generatedPaneItems.add(expander);
          generatedRoutes.add(GoRoute(
              path: routePath,
              builder: (context, state) => CategoryPage(client.category)));
        }
      }

      var routePath = '/' + client.name;
      if (client.category.isNotEmpty) {
        routePath = '/' + client.category.join('/') + routePath;
      }
      (expander?.items ?? generatedPaneItems).add(PaneItem(
          key: Key(routePath),
          icon: const Icon(FluentIcons.app_icon_default),
          title: Text(client.name),
          body: const SizedBox.shrink(),
          onTap: () {
            if (router.location != routePath) {
              router.push(routePath);
            }
          }));
      generatedRoutes.add(GoRoute(
          path: routePath, builder: (context, state) => ClientPage(client)));
    }
  }

  static final generatedPaneItemsNotifier =
      ManualValueNotifier(<NavigationPaneItem>[]);

  static List<NavigationPaneItem> get generatedPaneItems =>
      generatedPaneItemsNotifier.value;

  static final generatedRoutes = <RouteBase>[];
}
