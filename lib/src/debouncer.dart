import 'dart:async';

class Debouncer {
  final Duration delay;

  Debouncer({
    this.delay = const Duration(milliseconds: 300),
  });

  Timer? _timer;

  void start(void Function() func) {
    _timer?.cancel();
    _timer = Timer(delay, func);
  }

  void dispose() {
    _timer?.cancel();
  }
}
