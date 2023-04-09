import 'dart:collection';

import 'package:dashboard/side_assist/side_assist.dart';
import 'package:dashboard/widgets/client/option.dart';
import 'package:dashboard/widgets/page.dart';
import 'package:fluent_ui/fluent_ui.dart';

class ClientOptionsWidget extends StatelessWidget with PageMixin {
  final Client client;
  const ClientOptionsWidget(this.client, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        subtitle(content: const Text('Options')),
        ValueListenableBuilder(
          valueListenable: client.optionsValueNotifier,
          builder: (context, SplayTreeSet<NamedValue> options, child) => Column(
            children: options
                .map((e) => ClientOptionWidget(e))
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}
