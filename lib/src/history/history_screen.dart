import 'package:flutter/material.dart';
import 'package:routing_nanda/src/history/history_holder.dart';
import 'package:routing_nanda/src/utils.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HistoryHolder.i,
      builder: (_, __) => Scaffold(
        appBar: AppBar(
          title: const Text('Logs'),
          actions: [
            IconButton.outlined(
              onPressed: HistoryHolder.i.logs.isNotEmpty
                  ? () => HistoryHolder.i.dump().downloadAsFile()
                  : null,
              icon: const Icon(Icons.download_rounded),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              style: IconButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              onPressed: HistoryHolder.i.logs.isNotEmpty
                  ? HistoryHolder.i.clear
                  : null,
              icon: const Icon(Icons.delete_forever),
            ),
            const SizedBox(width: 12)
          ],
        ),
        body: HistoryHolder.i.logs.isNotEmpty
            ? ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: HistoryHolder.i.logs.length,
                itemBuilder: (context, index) => Text(
                  HistoryHolder.i.logs.elementAt(index),
                ),
              )
            : const Center(child: Text('Belum Ada Log')),
      ),
    );
  }
}
