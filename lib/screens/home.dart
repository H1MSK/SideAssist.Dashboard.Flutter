import 'package:dashboard/widgets/clients.dart';
import 'package:dashboard/widgets/page.dart';
import 'package:fluent_ui/fluent_ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with PageMixin {
  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
        header: const PageHeader(title: Text("Home")),
        children: [
          subtitle(content: const Text("Clients")),
          spacer,
          ClientsList(ClientsList.nonFilter)
        ]);
  }
}
