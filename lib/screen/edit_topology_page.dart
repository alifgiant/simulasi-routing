import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../service/graph_service.dart';
import '../service/router/router.dart';
import '../service/router/routes.dart';

class EditTopologyPage extends ConsumerWidget {
  const EditTopologyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Topology')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(21),
              children: [
                TextField(
                  decoration: const InputDecoration(
                    filled: true,
                    labelText: 'Jumlah Node',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onChanged: (s) => ref
                      .read(GraphService.provider.notifier)
                      .updateNodeCount(s),
                ),
              ],
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
