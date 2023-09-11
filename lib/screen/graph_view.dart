import 'package:flutter/material.dart';

class GraphView extends StatelessWidget {
  const GraphView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(runtimeType.toString()),
      ),
    );
  }
}
