import 'package:flutter/material.dart';

class ExperimentPage extends StatelessWidget {
  const ExperimentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Running Experiment')),
      body: Center(
        child: Text(runtimeType.toString()),
      ),
    );
  }
}
