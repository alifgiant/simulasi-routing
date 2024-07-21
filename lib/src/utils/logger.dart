import 'package:flutter/foundation.dart';
import 'package:routing_nanda/src/utils/history_holder.dart';
import 'package:yaml_writer/yaml_writer.dart';

class Logger {
  const Logger._();

  static const i = Logger._();

  void log(String s, {bool showDate = true}) {
    final str = showDate ? '${DateTime.now()} => $s' : s;
    HistoryHolder.i.log(str);
    if (kDebugMode) print(str);
  }
}

final defaultYamlWriter = YamlWriter();
final stringYamlWriter = YamlWriter(toEncodable: (object) => object.toString());
