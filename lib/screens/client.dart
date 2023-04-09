import 'package:dashboard/widgets/client/info.dart';
import 'package:dashboard/widgets/client/option.dart';
import 'package:dashboard/widgets/client/option_list.dart';
import 'package:dashboard/widgets/client/param.dart';
import 'package:dashboard/side_assist/side_assist.dart';
import 'package:dashboard/widgets/client/parameter_list.dart';
import 'package:fluent_ui/fluent_ui.dart';

class ClientPage extends StatelessWidget {
  final Client client;
  const ClientPage(this.client, {super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      children: [
        ClientInfoSliverBar(client),
        ClientParameterListWidget(client),
        ClientOptionsWidget(client)
      ],
    );
  }
}
