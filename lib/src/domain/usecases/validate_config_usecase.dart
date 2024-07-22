import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:routing_nanda/src/data/circle_data.dart';
import 'package:routing_nanda/src/utils/logger.dart';

class ValidateParamUsecase {
  ExperimentParams? start(
    int fiberCount,
    int lambdaCount,
    double offeredLoad,
    int holdTime,
    int experimentDuration,
    Map<int, CircleData> nodes,
  ) {
    Logger.i.log('Checking Simulation Parameter ...');

    if (nodes.length < 2) {
      EasyLoading.showError('Tidak bisa menjalankan simulasi, minimal 2 node');
      Logger.i.log('Error nodes.length < 2');
      return null;
    }

    if (experimentDuration == 0) {
      EasyLoading.showError('Tidak bisa menjalankan simulasi selama 0s');
      Logger.i.log('Error experiment duration == 0');
      return null;
    }

    final params = ExperimentParams(
      fiberCount: fiberCount,
      lambdaCount: lambdaCount,
      offeredLoad: offeredLoad,
      holdTime: holdTime,
      experimentDuration: experimentDuration,
    );

    Logger.i.log(
      'Simulation Parameter is valid ${yamlWriter.write(params)}',
    );

    return params;
  }
}

class ExperimentParams {
  final int fiberCount, lambdaCount, holdTime, experimentDuration;
  final double offeredLoad;
  late final double rateOfRequest;

  ExperimentParams({
    required this.fiberCount,
    required this.lambdaCount,
    required this.offeredLoad,
    required this.holdTime,
    required this.experimentDuration,
  }) {
    const precision = 1000;
    final realRate = offeredLoad * fiberCount * lambdaCount / holdTime;
    rateOfRequest = (realRate * precision).floorToDouble() / precision;
  }

  Map<String, dynamic> toJson() {
    return {
      'Fiber Count': fiberCount,
      'Wavelength Count in a Fiber': lambdaCount,
      'Offered load': offeredLoad,
      'Mean Hold Time each connection': '${holdTime}s',
      'Rate Request / second (λ)': '$rateOfRequest/s',
      'Experiment Duration': '${experimentDuration}s',
    };
  }

  @override
  String toString() {
    return yamlWriter.write(toJson());
  }
}
