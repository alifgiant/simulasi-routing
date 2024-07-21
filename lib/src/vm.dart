import 'package:flutter/material.dart';

class VmView<T extends ChangeNotifier> extends StatefulWidget {
  final T Function(BuildContext context) createVm;
  final Widget Function(T controller) builder;

  const VmView({
    super.key,
    required this.createVm,
    required this.builder,
  });

  @override
  State<StatefulWidget> createState() => VM<T>();
}

class VM<T extends ChangeNotifier> extends State<VmView<T>> {
  late final T controller;
  @override
  void initState() {
    super.initState();
    controller = widget.createVm(context);
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => widget.builder(controller),
    );
  }
}
