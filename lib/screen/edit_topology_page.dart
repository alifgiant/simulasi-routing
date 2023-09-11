import 'package:flutter/material.dart';
import 'package:simulasi_routing/router/router.dart';
import 'package:simulasi_routing/router/routes.dart';

class EditTopologyPage extends StatelessWidget {
  const EditTopologyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Topology')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: Text(runtimeType.toString()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(21.0),
            child: FilledButton.tonal(
              onPressed: () => routerProvider.push(Routes.editTopology),
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }
}
