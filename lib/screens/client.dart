import 'package:dashboard/side_assist/side_assist.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../widgets/option_list.dart';
import '../widgets/client_info.dart';
import '../widgets/page.dart';

class ClientPage extends StatelessWidget with PageMixin {
  final Client client;
  const ClientPage(this.client, {super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      children: [
        ClientInfoWidget(client),
        biggerSpacer,
        subtitle(content: const Text("Parameters")),
        spacer,
        ClientOptionsWidget(client.parametersValueNotifier),
        biggerSpacer,
        subtitle(content: const Text("Options")),
        spacer,
        ClientOptionsWidget(client.optionsValueNotifier)
      ],
    );
  }
}
