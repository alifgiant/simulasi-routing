import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';

class GraphService extends ChangeNotifier {
  static final provider = ChangeNotifierProvider<GraphService>(
    (ref) => GraphService(),
  );

  final state = Graph()..addNode(Node.Id(1));

  void updateNodeCount(String count) {
    final newCount = int.tryParse(count) ?? 0;
    final diff = newCount - state.nodeCount();
    if (diff.isNegative) {
      // for (var i = 0; i < diff; i++) {
      //   state.graph.removeNode(Node.Id(nodeCount + i));
      // }
    } else {
      final nodeCount = state.nodeCount();
      for (var i = 0; i < diff; i++) {
        final id = nodeCount + i + 1;
        final node = Node.Id(id);
        state.addNode(node);

        if (i > 1) state.addEdge(Node.Id(id), Node.Id(id - 1));
      }
      notifyListeners();
    }
    // if (newCount > state.nodeCount) {
    //   final node = state.graph.getNodeUsingId(id);
    // }

    // state = state.copyWith(nodeCount: newCount);

    // state.graph.nodes;
    // state.graph.rem
  }
}

// class GraphState {
//   // final int nodeCount;
//   final Graph graph;

//   GraphState({
//     // this.nodeCount = 0,
//     required this.graph,
//   }) {
//     graph.isTree = true;
//   }

//   GraphState copyWith({int? nodeCount, Graph? graph}) {
//     return GraphState(
//       nodeCount: nodeCount ?? this.nodeCount,
//       graph: graph ?? this.graph,
//     );
//   }
// }
