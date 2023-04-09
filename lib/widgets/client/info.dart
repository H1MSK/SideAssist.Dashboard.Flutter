import 'package:dashboard/side_assist/side_assist.dart';
import 'package:dashboard/theme.dart';
import 'package:dashboard/widgets/page.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

class ClientInfoSliverBar extends StatelessWidget with PageMixin {
  final Client client;
  const ClientInfoSliverBar(this.client, {super.key});

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    return subtitle(content: Text(client.name));
  }
}
