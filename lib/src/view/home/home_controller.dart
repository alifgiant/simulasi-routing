import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:routing_nanda/src/data/circle_data.dart';
import 'package:routing_nanda/src/utils/history_holder.dart';
import 'package:routing_nanda/src/utils/logger.dart';
import 'package:routing_nanda/src/utils/utils.dart';

import '../../domain/usecases/experiment_usecase.dart';
import '../../domain/usecases/route_finder_usecase.dart';
import '../../domain/usecases/setup_exp_config_usecase.dart';
import '../../domain/usecases/validate_config_usecase.dart';
import '../../utils/debouncer.dart';

class HomeController extends ChangeNotifier {
  final Map<int, CircleData> circlesMap = {};
  final Map<int, Set<int>> linksMap = {};
  double offeredLoad = 0.7;
  int fiberCount = 4,
      lambdaCount = 8,
      holdingTime = 10, // second
      experimentDuration = 120; // second

  bool isDragging = false;

  final Debouncer debouncer = Debouncer();
  final connectionCtlr = TextEditingController();

  final ValidateParamUsecase validateParamUsecase;
  final SetupNetworkConfigUsecase setupNetworkConfigUsecase;
  final RouteFinderUsecase routeFinderUsecase;
  final ExperimentUsecase experimentUsecase;

  HomeController({
    required this.validateParamUsecase,
    required this.setupNetworkConfigUsecase,
    required this.routeFinderUsecase,
    required this.experimentUsecase,
  });

  @override
  void dispose() {
    super.dispose();
    debouncer.dispose();
    connectionCtlr.dispose();
  }

  void changeFiber(double value) {
    fiberCount = value.toInt();
    notifyListeners();
  }

  void changeLambda(double value) {
    lambdaCount = value.toInt();
    notifyListeners();
  }

  void changeLoad(double value) {
    offeredLoad = value;
    notifyListeners();
  }

  void changeHoldTime(double value) {
    holdingTime = value.toInt();
    notifyListeners();
  }

  void changeExperimentDuration(double value) {
    experimentDuration = value.toInt();
    notifyListeners();
  }

  void onTapCanvas(TapUpDetails tapDetail) {
    final id = circlesMap.isEmpty ? 0 : circlesMap.keys.last + 1;
    final newCircle = CircleData(id, tapDetail.localPosition);
    circlesMap[id] = newCircle;
    notifyListeners();
  }

  void onPanCanvas(DragUpdateDetails details) {
    for (var circle in circlesMap.values) {
      circle.position += details.delta;
    }
    notifyListeners();
  }

  void onDeleteNode(DragTargetDetails<CircleData> details) {
    circlesMap.remove(details.data.id);
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

  Future<void> onStartSimulation() async {
    EasyLoading.show(
      status: 'Simulation Running',
      dismissOnTap: false,
      maskType: EasyLoadingMaskType.black,
    );

    Logger.i.log('======================================', showDate: false);
    final expParam = validateParamUsecase.start(
      fiberCount,
      lambdaCount,
      offeredLoad,
      holdingTime,
      experimentDuration,
      circlesMap,
    );

    if (expParam == null) return;

    final networkConfig = setupNetworkConfigUsecase.start(
      fiberCount: expParam.fiberCount,
      lambdaCount: expParam.lambdaCount,
      circlesMap: circlesMap,
      linksMap: linksMap,
    );

    Logger.i.log(
      'Experiment Started, will repeat Step 2 and 3 for ${expParam.experimentDuration}s ...',
    );
    Logger.i.log('Step 1: Construction of pre-defined paths');
    final nodeMap = routeFinderUsecase.start(
      networkConfig,
      expParam.fiberCount,
      expParam.lambdaCount,
    );

    await experimentUsecase.start(nodeMap, expParam);
    Logger.i.log('End: Simulation finished');
    Logger.i.log('Simulation Result:\n${yamlWriter.write(
      SimulationReporter.i.readReport(),
    )}');

    EasyLoading.showSuccess('Simulation Finished');
  }

  Future<void> importConfig() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'JSON'],
    );
    if (result == null || result.files.isEmpty) return;

    final byte = result.files.first.bytes!;

    final dataStr = String.fromCharCodes(byte);
    final mapData = jsonDecode(dataStr);

    final circles = (mapData['circle'] as List).map(
      (e) => CircleData.fromJson(e),
    );
    circlesMap
      ..clear()
      ..addAll({for (var circle in circles) circle.id: circle});
    connectionCtlr.text = mapData['connection'];
    fiberCount = mapData['fiber'] ?? fiberCount;
    lambdaCount = mapData['lambda'] ?? lambdaCount;
    offeredLoad = mapData['load'] ?? offeredLoad;
    holdingTime = mapData['holdtime'] ?? holdingTime;

    onConnectionChanged(connectionCtlr.text);
  }

  void exportConfig() {
    final mapData = {
      'circle': circlesMap.values.map((e) => e.toJson()).toList(),
      'connection': connectionCtlr.text,
      'fiber': fiberCount,
      'lambda': lambdaCount,
      'load': offeredLoad,
      'holdtime': holdingTime,
    };

    final encoded = jsonEncode(mapData);
    encoded.downloadAsFile(filename: 'app-config.json');
  }
}
