import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';

mixin PageMixin {
  static const _spacer = SizedBox(height: 10.0);
  static const _biggerSpacer = SizedBox(height: 40.0);

  SizedBox get spacer => _spacer;
  SizedBox get biggerSpacer => _biggerSpacer;

  Widget description({required Widget content}) {
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 4.0),
        child: DefaultTextStyle(
          style: FluentTheme.of(context).typography.body!,
          child: content,
        ),
      );
    });
  }

  Widget subtitle({required Widget content}) {
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: 14.0, bottom: 2.0),
        child: DefaultTextStyle(
          style: FluentTheme.of(context).typography.subtitle!,
          child: content,
        ),
      );
    });
  }
}

abstract class Page extends StatelessWidget {
  Page({super.key}) {
    _pageIndex++;
  }

  final StreamController _controller = StreamController.broadcast();
  Stream get stateStream => _controller.stream;

  @override
  Widget build(BuildContext context);

  void setState(VoidCallback func) {
    func();
    _controller.add(null);
  }

  Widget description({required Widget content}) {
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 4.0),
        child: DefaultTextStyle(
          style: FluentTheme.of(context).typography.body!,
          child: content,
        ),
      );
    });
  }

  Widget subtitle({required Widget content}) {
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: 14.0, bottom: 2.0),
        child: DefaultTextStyle(
          style: FluentTheme.of(context).typography.subtitle!,
          child: content,
        ),
      );
    });
  }
}

int _pageIndex = -1;

abstract class ScrollablePage extends Page {
  ScrollablePage({super.key});

  final scrollController = ScrollController();
  Widget buildHeader(BuildContext context) => const SizedBox.shrink();

  Widget buildBottomBar(BuildContext context) => const SizedBox.shrink();

  List<Widget> buildScrollable(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.scrollable(
      key: PageStorageKey(_pageIndex),
      scrollController: scrollController,
      header: buildHeader(context),
      children: buildScrollable(context),
      bottomBar: buildBottomBar(context),
    );
  }
}

class EmptyPage extends Page {
  final Widget? child;

  EmptyPage({
    this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return child ?? const SizedBox.shrink();
  }
}

extension PageExtension on List<Page> {
  List<Widget> transform(BuildContext context) {
    return map((page) {
      return StreamBuilder(
        stream: page.stateStream,
        builder: (context, _) {
          return page.build(context);
        },
      );
    }).toList();
  }
}
