import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:routing_nanda/src/core/circle_data.dart';
import 'package:routing_nanda/src/utils/logger.dart';

class ValidateParamUsecase {
  ValidationResult? start(
    String fiber,
    String lambda,
    double offeredLoad,
    Map<int, CircleData> nodes,
  ) {
    Logger.i.log('Checking Simulation Parameter ...');
    final fiberCount = int.tryParse(fiber) ?? -1;
    if (fiberCount < 1) {
      EasyLoading.showError('Periksa jumlah fiber / harus lebih dari 0');
      Logger.i.log('Error fiberCount < 1');
      return null;
    }

    final lambdaCount = int.tryParse(lambda) ?? -1;
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

    if (nodes.length < 2) {
      EasyLoading.showError('Tidak bisa menjalankan simulasi, minimal 2 node');
    }

    Logger.i.log(
      'Simulation Parameter is valid\n${defaultYamlWriter.write(
        {
          'fiberCount': fiberCount,
          'lambdaCount': lambdaCount,
          'offeredLoad': offeredLoad,
        },
      )}',
    );

    return ValidationResult(
      fiberCount: fiberCount,
      lambdaCount: lambdaCount,
      offeredLoad: offeredLoad,
    );
  }
}

class ValidationResult {
  final int fiberCount, lambdaCount;

  final double offeredLoad;

  ValidationResult({
    required this.fiberCount,
    required this.lambdaCount,
    required this.offeredLoad,
  });
}
