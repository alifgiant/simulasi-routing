import 'package:flutter/material.dart';
import 'package:routing_nanda/src/circle_data.dart';

import 'debouncer.dart';

class HomeController extends ChangeNotifier {
  final Map<int, CircleData> circles = {};
  final Map<int, Set<int>> connections = {};
  double offeredLoad = 0.0;
  bool isDragging = false;

  final Debouncer debouncer = Debouncer();
  final connectionCtlr = TextEditingController();
  final fiberCtlr = TextEditingController();
  final lamdaCtlr = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    debouncer.dispose();
    connectionCtlr.dispose();
    fiberCtlr.dispose();
    lamdaCtlr.dispose();
  }

  void changeLoad(double value) {
    offeredLoad = value;
    notifyListeners();
  }

  void onTapCanvas(TapUpDetails tapDetail) {
    final id = circles.isEmpty ? 0 : circles.keys.last + 1;
    final newCircle = CircleData(id, tapDetail.localPosition);
    circles[id] = newCircle;
    notifyListeners();
  }

  void onPanCanvas(DragUpdateDetails details) {
    for (var circle in circles.values) {
      circle.position += details.delta;
    }
    notifyListeners();
  }

  void onDeleteNode(DragTargetDetails<CircleData> details) {
    circles.remove(details.data.id);
    notifyListeners();
  }

  void onConnectionChanged(String s) {
    debouncer.start(() {
      final splitted = s.split(',');
      Map<int, Set<int>> newCons = {};
      for (var element in splitted) {
        final trimmed = element.trim();
        final nodes = trimmed.split('-').map(int.tryParse);
        if (nodes.any((n) => n == null) || nodes.length != 2) {
          continue;
        }

        final source = nodes.first! < nodes.last! ? nodes.first! : nodes.last!;
        final target = nodes.first! < nodes.last! ? nodes.last! : nodes.first!;

        final currentCons = newCons[source] ?? {};
        currentCons.add(target);
        newCons[source] = currentCons;
      }
      connections
        ..clear()
        ..addAll(newCons);

      notifyListeners();
    });
  }

  void onDragNode(DragUpdateDetails details, CircleData circle) {
    final localPosition = circle.position + details.delta;
    circle.position = localPosition;
    isDragging = true;
    notifyListeners();
  }

  void onDragEnd(
    DraggableDetails details,
    CircleData circle,
    RenderBox renderBox,
  ) {
    Offset localPosition = renderBox.globalToLocal(
      // add offset to counter removed top padding
      details.offset + const Offset(20, 20),
    );

    circle.position = localPosition;
    isDragging = false;
    notifyListeners();
  }

  void onStartSimulation() {
    //
  }
}
