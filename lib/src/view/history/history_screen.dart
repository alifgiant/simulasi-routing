import 'package:flutter/material.dart';
import 'package:routing_nanda/src/utils/history_holder.dart';
import 'package:routing_nanda/src/utils/utils.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late String query = '';
  late Iterable<String> filteredLogs = HistoryHolder.i.logs.where(
    (e) => e.contains(query),
  );

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
            ? content()
            : const Center(child: Text('Belum Ada Log')),
      ),
    );
  }

  Widget content() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: TextField(
            onChanged: (val) {
              setState(() => query = val);
              filteredLogs = HistoryHolder.i.logs.where(
                (e) => e.contains(query),
              );
            },
            decoration: const InputDecoration(
              hintText: 'Cari ...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filteredLogs.length,
            itemBuilder: (context, index) => Text(
              filteredLogs.elementAt(index),
            ),
          ),
        ),
      ],
    );
  }
}
