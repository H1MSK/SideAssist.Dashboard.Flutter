import 'package:dashboard/pages.dart';
import 'package:dashboard/side_assist/side_assist.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';

import 'client_info.dart';

class ClientsList extends StatelessWidget {
  static bool Function(Client) nonFilter = (p0) => true;
  static bool Function(Client) categoryFilter(List<String> category) {
    return (Client client) => listEquals(client.category, category);
  }

  final bool Function(Client client) filter;
  const ClientsList(this.filter, {super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: dashboard.clientsNotifier,
        builder: (context, Map<String, Client> clients, child) => ListView(
              shrinkWrap: true,
              children: dashboard.orderedClients
                  .where(filter)
                  .map((e) => Padding(
                        padding: const EdgeInsets.all(4),
                        child: GestureDetector(
                          child: ClientFastInfoWidget(e),
                          onTap: () {
                            var path = '/' + (e.category + [e.name]).join('/');
                            if (Pages.router.location != path) {
                              Pages.router.push(path);
                            }
                          },
                        ),
                      ))
                  .toList(growable: false),
            ));
  }
}
