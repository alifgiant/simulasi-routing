import 'package:flutter_riverpod/flutter_riverpod.dart';

class GraphService extends StateNotifier<GraphState> {
  static final provider = StateNotifierProvider<GraphService, GraphState>(
    (ref) => GraphService(),
  );

  GraphService() : super(const GraphState());

  void updateNodeCount(String count) {
    final newCount = int.tryParse(count) ?? 0;
    state = state.copyWith(nodeCount: newCount);
  }
}

class GraphState {
  final int nodeCount;

  const GraphState({this.nodeCount = 0});

  GraphState copyWith({int? nodeCount}) {
    return GraphState(nodeCount: nodeCount ?? this.nodeCount);
  }
}
