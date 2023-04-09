import 'dart:math';

import 'package:dashboard/side_assist/side_assist.dart';
import 'package:dashboard/widgets/edit.dart';
import 'package:dashboard/widgets/typer_animated_text.dart';
import 'package:fluent_ui/fluent_ui.dart';

class OptionWidgetMixin {
  Widget Function(BuildContext, bool) getHeaderBuilder(NamedValue option) {
    return (BuildContext context, bool isOpen) => Flexible(
            child: Row(
          children: [
            Text(option.name),
          ],
        ));
  }
}

class ClientOptionWidget extends StatefulWidget {
  final NamedValue option;
  final bool expanded;
  final void Function(bool expanded)? onStateChange;
  const ClientOptionWidget(this.option,
      {this.expanded = false, this.onStateChange, super.key});

  @override
  State<ClientOptionWidget> createState() => _ClientOptionWidgetState();
}

class _LastHalfLinear extends Curve {
  @override
  double transform(double t) => max(0, t * 2 - 1);
}

class _ClientOptionWidgetState extends State<ClientOptionWidget>
    with EditWidgetMixin {
  bool expanded = false;
  late final bool valueChangable;
  late final bool valueChangeEnabled;
  bool editing = false;
  late final List<CommandBarButton> viewCommands;
  late final List<CommandBarButton> editCommands;
  dynamic newValue;

  @override
  void initState() {
    super.initState();
    expanded = widget.expanded;
    widget.option.valueNotifer.addListener(() {
      setState(() {});
    });

    valueChangable = widget.option.isValueChangable;
    valueChangeEnabled = widget.option.isValueChangeEnabled;

    viewCommands = [
      if (widget.option.isValueChangable)
        CommandBarButton(
          icon: valueChangeEnabled
              ? const Icon(FluentIcons.edit)
              : const Icon(FluentIcons.blocked),
          label: Text(valueChangeEnabled ? "edit" : "uneditable"),
          onPressed: () => setState(() {
            editing = true;
          }),
        )
    ];
    editCommands = [
      CommandBarButton(
        icon: const Icon(FluentIcons.accept),
        label: const Text("accept"),
        onPressed: () => setState(() {
          widget.option.tryChangeValue!(newValue);
          editing = false;
        }),
      ),
      CommandBarButton(
        icon: const Icon(FluentIcons.cancel),
        label: const Text("cancel"),
        onPressed: () => setState(() {
          editing = false;
        }),
      )
    ];
  }

  Widget? buildControls(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: expanded ? 280 : 0, minWidth: 0),
        child: CommandBar(
            mainAxisAlignment: MainAxisAlignment.end,
            primaryItems: editing
                ? editCommands
                : buildViewControls(widget.option.type, widget.option.meta,
                        widget.option.value) +
                    viewCommands),
      );

  @override
  Widget build(BuildContext context) {
    return Expander(
      header: Row(
        children: [
          Text(widget.option.name),
          TyperAnimatedText(
            ': ' + widget.option.value.toString(),
            reverse: expanded,
            curve: _LastHalfLinear(),
          )
        ],
      ),
      content: editing
          ? Card(
              padding: const EdgeInsets.all(0),
              child: Expanded(
                child: buildEditWidget(widget.option.type, widget.option.meta,
                    widget.option.value, (value) => newValue = value),
              ))
          : Text(widget.option.value.toString()),
      trailing: buildControls(context),
      initiallyExpanded: widget.expanded,
      onStateChanged: (value) {
        setState(() {
          expanded = value;
          if (!expanded) editing = false;
          widget.onStateChange?.call(value);
        });
      },
    );
  }
}
