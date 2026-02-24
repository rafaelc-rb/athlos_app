import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rest_timer_notifier.g.dart';

class RestTimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;

  const RestTimerState({
    this.remainingSeconds = 0,
    this.totalSeconds = 0,
    this.isRunning = false,
  });

  bool get isActive => remainingSeconds > 0 || isRunning;

  double get progress =>
      totalSeconds > 0 ? remainingSeconds / totalSeconds : 0;

  RestTimerState copyWith({
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
  }) =>
      RestTimerState(
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        totalSeconds: totalSeconds ?? this.totalSeconds,
        isRunning: isRunning ?? this.isRunning,
      );
}

@Riverpod(keepAlive: true)
class RestTimer extends _$RestTimer {
  Timer? _timer;

  @override
  RestTimerState build() => const RestTimerState();

  void start(int seconds) {
    _timer?.cancel();
    state = RestTimerState(
      remainingSeconds: seconds,
      totalSeconds: seconds,
      isRunning: true,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = state.remainingSeconds - 1;
      if (next <= 0) {
        _timer?.cancel();
        state = state.copyWith(remainingSeconds: 0, isRunning: false);
      } else {
        state = state.copyWith(remainingSeconds: next);
      }
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void resume() {
    if (state.remainingSeconds <= 0) return;
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = state.remainingSeconds - 1;
      if (next <= 0) {
        _timer?.cancel();
        state = state.copyWith(remainingSeconds: 0, isRunning: false);
      } else {
        state = state.copyWith(remainingSeconds: next);
      }
    });
  }

  void addTime(int seconds) {
    if (state.remainingSeconds <= 0) return;
    state = state.copyWith(
      remainingSeconds: state.remainingSeconds + seconds,
      totalSeconds: state.totalSeconds + seconds,
    );
  }

  void skip() {
    _timer?.cancel();
    state = state.copyWith(remainingSeconds: 0, isRunning: false);
  }

  void reset() {
    _timer?.cancel();
    state = const RestTimerState();
  }
}
