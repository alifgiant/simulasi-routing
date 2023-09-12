import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../service/graph_service.dart';
import '../service/router/router.dart';
import '../service/router/routes.dart';

class EditTopologyPage extends ConsumerWidget {
  const EditTopologyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graph = ref.watch(GraphService.provider).state;
    String countTxt = graph.nodeCount().toString();
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Topology')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(21),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          filled: true,
                          labelText: 'Jumlah Node',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        controller: TextEditingController(text: countTxt),
                        onChanged: (s) => countTxt = s,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonal(
                      onPressed: () => ref
                          .read(GraphService.provider.notifier)
                          .updateNodeCount(countTxt),
                      child: const Text('Set'),
                    )
                  ],
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
