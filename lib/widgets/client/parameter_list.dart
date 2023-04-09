import 'dart:collection';

import 'package:dashboard/side_assist/side_assist.dart';
import 'package:dashboard/widgets/client/param.dart';
import 'package:dashboard/widgets/page.dart';
import 'package:fluent_ui/fluent_ui.dart';

class ClientParameterListWidget extends StatefulWidget {
  final Client client;
  const ClientParameterListWidget(this.client, {super.key});

  @override
  State<ClientParameterListWidget> createState() =>
      _ClientParameterListWidgetState();
}

class _ClientParameterListWidgetState extends State<ClientParameterListWidget>
    with PageMixin {
  int currentExpanded = -1;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        subtitle(content: const Text("Params")),
        ValueListenableBuilder(
            valueListenable: widget.client.parametersValueNotifier,
            builder: (context, SplayTreeSet<NamedValue> parameters, child) =>
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: parameters.length,
                  itemBuilder: (context, index) =>
                      ClientParamWidget(parameters.elementAt(index),
                          expanded: index == currentExpanded,
                          onStateChange: (expanded) => setState(() {
                                currentExpanded = expanded ? index : -1;
                              })),
                )),
      ],
    );
  }
}
