import 'package:fluent_ui/fluent_ui.dart';

class TyperAnimatedText extends StatefulWidget {
  final String text;
  final bool reverse;
  final Duration? duration;
  final AnimationController? controller;
  final Curve curve;
  final TextOverflow? overflow;
  final int? maxLines;
  final TextStyle? style;
  const TyperAnimatedText(this.text,
      {this.reverse = false,
      this.duration,
      this.maxLines,
      this.style,
      this.curve = Curves.linear,
      this.controller,
      this.overflow,
      super.key});

  @override
  State<TyperAnimatedText> createState() => _TyperAnimatedTextState();
}

class _TyperAnimatedTextState extends State<TyperAnimatedText>
    with SingleTickerProviderStateMixin {
  late AnimationController? _localController;

  double value = 0;

  void _checkAnimation() {
    if (_localController == null) return;
    if (!widget.reverse && _localController!.value != 1) {
      if (_localController!.duration != null) {
        _localController!.forward();
      } else {
        _localController!.value = 1;
      }
    } else if (widget.reverse && _localController!.value != 0) {
      if (_localController!.duration != null) {
        _localController!.reverse();
      } else {
        _localController!.value = 0;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _localController?.duration =
        widget.duration ?? FluentTheme.of(context).mediumAnimationDuration;
  }

  @override
  void didUpdateWidget(covariant TyperAnimatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAnimation();
  }

  void _updateLength(AnimationController controller) {
    setState(() {
      value = widget.curve.transform(controller.value).clamp(0, 1);
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _localController = AnimationController(vsync: this);
      _localController!.addListener(() => _updateLength(_localController!));
    } else {
      _localController = null;
      widget.controller!.addListener(() => _updateLength(widget.controller!));
    }
    _checkAnimation();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _localController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.text.substring(0, (value * widget.text.length).round()),
      overflow: widget.overflow,
      style: widget.style,
      maxLines: widget.maxLines,
    );
  }
}
