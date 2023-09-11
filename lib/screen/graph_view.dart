import 'package:flutter/material.dart';

class GraphView extends StatelessWidget {
  const GraphView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.inverseSurface,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 21),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
