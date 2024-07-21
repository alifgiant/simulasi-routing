import 'package:flutter/material.dart';
import 'package:routing_nanda/src/core/circle_data.dart';
import 'package:routing_nanda/src/utils/logger.dart';

import '../usecases/route_finder_usecase.dart';
import '../usecases/setup_exp_config_usecase.dart';
import '../usecases/validate_config_usecase.dart';
import '../utils/debouncer.dart';

class HomeController extends ChangeNotifier {
  final Map<int, CircleData> ciclesMap = {};
  final Map<int, Set<int>> linksMap = {};
  double offeredLoad = 0.0;
  bool isDragging = false;

  final Debouncer debouncer = Debouncer();
  final connectionCtlr = TextEditingController();
  final fiberCtlr = TextEditingController(text: '1');
  final lamdaCtlr = TextEditingController(text: '1');

  final ValidateParamUsecase validateParamUsecase;
  final SetupNetworkConfigUsecase setupNetworkConfigUsecase;
  final RouteFinderUsecase routeFinderUsecase;

  HomeController({
    required this.validateParamUsecase,
    required this.setupNetworkConfigUsecase,
    required this.routeFinderUsecase,
  });

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
    final id = ciclesMap.isEmpty ? 0 : ciclesMap.keys.last + 1;
    final newCircle = CircleData(id, tapDetail.localPosition);
    ciclesMap[id] = newCircle;
    notifyListeners();
  }

  void onPanCanvas(DragUpdateDetails details) {
    for (var circle in ciclesMap.values) {
      circle.position += details.delta;
    }
    notifyListeners();
  }

  void onDeleteNode(DragTargetDetails<CircleData> details) {
    ciclesMap.remove(details.data.id);
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
      linksMap
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
    Logger.i.log('======================================', showDate: false);
    final validationResult = validateParamUsecase.start(
      fiberCtlr.text,
      lamdaCtlr.text,
      offeredLoad,
      ciclesMap,
    );

    if (validationResult == null) return;

    final config = setupNetworkConfigUsecase.start(
      validationResult.fiberCount,
      validationResult.lambdaCount,
      validationResult.offeredLoad,
      ciclesMap,
      linksMap,
    );

    Logger.i.log('Experiment Started ...');
    final nodes = config.nodes..shuffle();
    Logger.i.log('Communication from ${nodes[0]} to ${nodes[1]}');
    Logger.i.log('Step 1: Construction of pre-defined paths');
    routeFinderUsecase.start(config);
    Logger.i.log('Step 2: Collecting information by signaling');
    Logger.i.log('Step 3: Route and wavelength selection');
    //
  }
}
