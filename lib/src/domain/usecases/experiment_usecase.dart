import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:routing_nanda/src/domain/core/node.dart';
import 'package:routing_nanda/src/domain/core/node_runner.dart';
import 'package:routing_nanda/src/domain/usecases/validate_config_usecase.dart';

class ExperimentUsecase {
  Future<void> start(
    Map<int, Node> routingMap,
    ExperimentParams expParam,
  ) async {
    final nodeRunners = routingMap.map(
      (key, value) => MapEntry(
        key,
        NodeRunner(node: value, nodeMap: routingMap),
      ),
    );
    for (var node in nodeRunners.values) {
      node.run(expParam);
    }

    // let experiment run for as long as [experimentDuration]
    final targetDuration = Duration(seconds: expParam.experimentDuration);
    final experimentStartTime = DateTime.now();
    Duration passedTime = DateTime.now().difference(experimentStartTime);
    do {
      // update progress every second,
      // because minimal experimentDuration is 10s
      await Future.delayed(const Duration(seconds: 1));
      passedTime = DateTime.now().difference(experimentStartTime);
      final completion =
          passedTime.inMilliseconds / targetDuration.inMilliseconds;
      EasyLoading.showProgress(
        completion <= 1 ? completion : 1,
        status: 'Simulation Running',
        maskType: EasyLoadingMaskType.black,
      );
    } while (passedTime < targetDuration);

    for (var node in nodeRunners.values) {
      node.stop();
    }
  }
}
