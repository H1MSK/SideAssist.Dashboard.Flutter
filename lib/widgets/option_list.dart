import 'package:dashboard/side_assist/side_assist.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../manual_value_notifer.dart';
import 'option.dart';
import 'page.dart';

class ClientOptionsWidget extends StatelessWidget with PageMixin {
  final ManualValueNotifier<Iterable<NamedValue>> options;
  const ClientOptionsWidget(this.options, {super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: options,
      builder: (context, Iterable<NamedValue> options, child) => Column(
        children: [
          for (var o in options) ...[ClientOptionWidget(o), spacer]
        ],
      ),
    );
  }
}
