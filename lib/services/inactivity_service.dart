import 'dart:async';

class InactivityService {
  Timer? _timer;
  Duration _timeout = const Duration(minutes: 5);
  void Function()? _onTimeout;
  DateTime? _lastInteraction;

  bool get isRunning => _timer != null;

  void configure({
    required Duration timeout,
    required void Function() onTimeout,
  }) {
    _timeout = timeout;
    _onTimeout = onTimeout;
  }

  void start({DateTime? lastInteraction}) {
    _lastInteraction = lastInteraction ?? DateTime.now();
    _resetTimer();
  }

  void registerInteraction() {
    _lastInteraction = DateTime.now();
    _resetTimer();
  }

  DateTime? get lastInteraction => _lastInteraction;

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(_timeout, () {
      _onTimeout?.call();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    _onTimeout = null;
  }
}
