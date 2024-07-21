import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:routing_nanda/src/logger.dart';
import 'package:yaml_writer/yaml_writer.dart';

class ValidateParamUsecase {
  final yamlWriter = YamlWriter();

  ValidationResult? start(String fiber, String lambda, double offeredLoad) {
    Logger.i.log('Checking Simulation Parameter');
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

    Logger.i.log(
      'Simulation Parameter is valid\n${yamlWriter.write(
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
