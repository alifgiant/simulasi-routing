import 'package:flutter/material.dart';
import 'package:routing_nanda/src/history/history_holder.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton.filled(
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            onPressed: HistoryHolder.i.clear,
            icon: const Icon(Icons.delete_forever),
          ),
          const SizedBox(width: 12)
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: HistoryHolder.i.logs.length,
        itemBuilder: (context, index) => Text(
          HistoryHolder.i.logs.elementAt(index),
        ),
      ),
    );
  }
}
