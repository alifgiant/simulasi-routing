import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:routing_nanda/src/core/circle_data.dart';
import 'package:routing_nanda/src/utils/logger.dart';

class ValidateParamUsecase {
  ExperimentParams? start(
    int fiberCount,
    int lambdaCount,
    double offeredLoad,
    double holdTime,
    Map<int, CircleData> nodes,
  ) {
    Logger.i.log('Checking Simulation Parameter ...');
    if (fiberCount < 1) {
      EasyLoading.showError('Periksa jumlah fiber / harus lebih dari 0');
      Logger.i.log('Error fiberCount < 1');
      return null;
    }

    if (lambdaCount < 1) {
      EasyLoading.showError(
        'Periksa jumlah panjang gelombang / harus lebih dari 0',
      );
      Logger.i.log('Error lambdaCount < 1');
      return null;
    }

    if (offeredLoad == 1) {
      EasyLoading.showError(
        'Tidak bisa menjalankan simulasi, atur beban dibawah 1',
      );
      Logger.i.log('Error offeredLoad == 1');
      return null;
    }

    if (holdTime <= 0) {
      EasyLoading.showError(
        'Tidak bisa menjalankan simulasi, atur waktu tinggu lebih besar dari 0',
      );
      Logger.i.log('Error holdTime <= 0');
      return null;
    }

    if (nodes.length < 2) {
      EasyLoading.showError('Tidak bisa menjalankan simulasi, minimal 2 node');
      return null;
    }

    Logger.i.log(
      'Simulation Parameter is valid\n${defaultYamlWriter.write(
        {
          'fiberCount': fiberCount,
          'lambdaCount': lambdaCount,
          'offeredLoad': offeredLoad,
          'holdTime': '${holdTime}s',
        },
      )}',
    );

    return ExperimentParams(
      fiberCount: fiberCount,
      lambdaCount: lambdaCount,
      offeredLoad: offeredLoad,
      holdTime: holdTime,
    );
  }
}

class ExperimentParams {
  final int fiberCount, lambdaCount;
  final double offeredLoad, holdTime, rateOfRequest;

  const ExperimentParams({
    required this.fiberCount,
    required this.lambdaCount,
    required this.offeredLoad,
    required this.holdTime,
  }) : rateOfRequest = offeredLoad * fiberCount * lambdaCount / holdTime;
}
