class HistoryHolder {
  HistoryHolder._();

  static final i = HistoryHolder._();

  final List<String> _logs = [];
  Iterable<String> get logs => _logs;
  void log(String s) => _logs.add(s);
  void clear() => _logs.clear();
}
