import 'package:dashboard/widgets/clients.dart';
import 'package:dashboard/widgets/page.dart';
import 'package:fluent_ui/fluent_ui.dart';

class CategoryPage extends StatelessWidget with PageMixin {
  final List<String> category;
  const CategoryPage(this.category, {super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
        header: PageHeader(title: Text(category.join('.'))),
        children: [
          spacer,
          subtitle(content: const Text("clients")),
          spacer,
          ClientsList(ClientsList.categoryFilter(category))
        ]);
  }
}
