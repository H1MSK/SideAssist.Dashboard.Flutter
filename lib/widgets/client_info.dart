import 'package:dashboard/side_assist/side_assist.dart';
import 'package:dashboard/widgets/page.dart';
import 'package:fluent_ui/fluent_ui.dart';

class ClientInfoWidget extends StatelessWidget with PageMixin {
  final Client client;
  const ClientInfoWidget(this.client, {super.key});

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    return PageHeader(title: Text(client.name));
  }
}

class ClientFastInfoWidget extends StatelessWidget {
  final Client client;
  const ClientFastInfoWidget(this.client, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Text((client.category + [client.name]).join('.')),
    );
  }
}
