import 'package:routing_nanda/src/core/circle_data.dart';
import 'package:routing_nanda/src/core/link.dart';
import 'package:routing_nanda/src/core/node.dart';
import 'package:routing_nanda/src/utils/logger.dart';
import 'package:yaml_writer/yaml_writer.dart';

class SetupNetworkConfigUsecase {
  final yamlWriter = YamlWriter(toEncodable: (object) => object.toString());

  ConfigResult start({
    required int fiber,
    required int lambda,
    required int holdTime,
    required double offeredLoad,
    required Map<int, CircleData> circlesMap,
    required Map<int, Set<int>> linksMap,
  }) {
    Logger.i.log('Configuring Network ...');
    final cables = <Link>[];
    for (var connection in linksMap.entries) {
      final source = connection.key;
      final targets = connection.value;
      for (var target in targets) {
        for (var fiberI = 0; fiberI < fiber; fiberI++) {
          for (var lambdaI = 0; lambdaI < lambda; lambdaI++) {
            final cable = Link(
              source: source,
              target: target,
              fiber: fiberI,
              lambda: lambdaI,
            );
            cables.add(cable);
          }
        }
      }
    }
    cables.shuffle();

    // final rateOfRequest = offeredLoad * fiber * lambda / holdTime;

    Logger.i.log('Total cables (link x fiber x lambda): ${cables.length}');
    Logger.i.log('Offered Load: $offeredLoad');
    Logger.i.log('Request Rate / second (λ): $offeredLoad');
    Logger.i.log('Offered Load: $offeredLoad');
    Logger.i.log('Available Link:\n${yamlWriter.write(cables)}');
    final nodes = circlesMap.values.map(Node.fromCircle).toList();

    return ConfigResult(
      availableLink: cables,
      nodes: nodes,
    );
  }
}

class ConfigResult {
  final List<Link> availableLink;
  final List<Node> nodes;

  ConfigResult({
    required this.availableLink,
    required this.nodes,
  });
}
