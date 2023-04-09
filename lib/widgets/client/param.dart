import 'dart:math';

import 'package:dashboard/side_assist/side_assist.dart';
import 'package:dashboard/widgets/typer_animated_text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

import '../edit.dart';

class ClientParamWidget extends StatefulWidget {
  final NamedValue param;
  final bool expanded;
  final void Function(bool expanded)? onStateChange;
  const ClientParamWidget(this.param,
      {this.expanded = false, this.onStateChange, super.key});

  @override
  State<ClientParamWidget> createState() => _ClientParamWidgetState();
}

class _LastHalfLinear extends Curve {
  @override
  double transform(double t) => max(0, t * 2 - 1);
}

class _ClientParamWidgetState extends State<ClientParamWidget>
    with EditWidgetMixin {
  bool expanded = false;
  @override
  void initState() {
    super.initState();
    expanded = widget.expanded;
    widget.param.valueNotifer.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant ClientParamWidget oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    if (widget.expanded != oldWidget.expanded) setState(() {});
  }

  Widget? buildExpandedControls(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: expanded ? 160 : 0, minWidth: 0),
        child: CommandBar(
            mainAxisAlignment: MainAxisAlignment.end,
            primaryItems: buildViewControls(
                widget.param.type, widget.param.meta, widget.param.value)),
      );

  @override
  Widget build(BuildContext context) {
    return Expander(
      header: Row(
        children: [
          Text(widget.param.name),
          TyperAnimatedText(
            ': ' + widget.param.value.toString(),
            reverse: expanded,
            curve: _LastHalfLinear(),
          )
        ],
      ),
      content: Text(widget.param.value.toString()),
      trailing: buildExpandedControls(context),
      initiallyExpanded: widget.expanded,
      onStateChanged: (value) {
        setState(() {
          expanded = value;
          widget.onStateChange?.call(value);
        });
      },
    );
  }
}
