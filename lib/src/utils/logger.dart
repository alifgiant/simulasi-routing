import 'package:routing_nanda/src/utils/history_holder.dart';

class Logger {
  const Logger._();

  static const i = Logger._();

  void log(String s, {bool showDate = true}) {
    HistoryHolder.i.log(
      showDate ? '${DateTime.now()} => $s' : s,
    );
  }
}
