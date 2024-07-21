import 'package:routing_nanda/src/core/circle_data.dart';
import 'package:routing_nanda/src/core/link.dart';
import 'package:routing_nanda/src/core/node.dart';
import 'package:routing_nanda/src/utils/logger.dart';
import 'package:yaml_writer/yaml_writer.dart';

class SetupExpConfigUsecase {
  final yamlWriter = YamlWriter(toEncodable: (object) => object.toString());

  ConfigResult? start(
    int fiber,
    int lambda,
    double offeredLoad,
    Map<int, CircleData> circlesMap,
    Map<int, Set<int>> linksMap,
  ) {
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
    Logger.i.log('Total cables (link x fiber x lambda): ${cables.length}');
    Logger.i.log('Offered Load: $offeredLoad');
    final lastIndex = cables.length - 1;
    final usedCount = (offeredLoad * lastIndex).floor();
    cables.shuffle();
    final availableLink = cables.sublist(usedCount);
    Logger.i.log('Available Link:\n${yamlWriter.write(availableLink)}');

    final nodes = circlesMap.values.map(Node.fromCircle).toList()..shuffle();
    Logger.i.log('Communication: ${nodes[0]} to ${nodes[1]}');

    return ConfigResult(
      availableLink: availableLink,
      nodes: nodes,
      start: nodes[0],
      end: nodes[1],
    );
  }
}

class ConfigResult {
  final List<Link> availableLink;
  final List<Node> nodes;
  final Node start, end;

  ConfigResult({
    required this.availableLink,
    required this.nodes,
    required this.start,
    required this.end,
  });
}
