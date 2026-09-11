import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:local_notifier/local_notifier.dart';

enum PomodoroMode { work, shortBreak, longBreak }

class PomodoroService extends ChangeNotifier {
  static final PomodoroService _instance = PomodoroService._internal();
  factory PomodoroService() => _instance;
  PomodoroService._internal() {
    remainingSeconds = workDuration;
  }

  int workDuration = 25 * 60;       
  int shortBreakDuration = 5 * 60;  
  int longBreakDuration = 15 * 60;  
  int longBreakInterval = 4;        

  PomodoroMode currentMode = PomodoroMode.work;
  int remainingSeconds = 25 * 60;
  bool isRunning = false;
  int completedSessions = 0;

  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  void startTimer() {
    if (isRunning) return;
    isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        remainingSeconds--;
        notifyListeners();
      } else {
        _onTimerComplete();
      }
    });
    notifyListeners();
  }

  void pauseTimer() {
    _timer?.cancel();
    isRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    pauseTimer();
    _resetToCurrentMode();
  }

  void switchMode(PomodoroMode mode) {
    pauseTimer();
    currentMode = mode;
    _resetToCurrentMode();
  }

  void _resetToCurrentMode() {
    switch (currentMode) {
      case PomodoroMode.work:
        remainingSeconds = workDuration;
        break;
      case PomodoroMode.shortBreak:
        remainingSeconds = shortBreakDuration;
        break;
      case PomodoroMode.longBreak:
        remainingSeconds = longBreakDuration;
        break;
    }
    notifyListeners();
  }

  void _onTimerComplete() {
    pauseTimer();

    // 1. Gửi thông báo Windows & Phát chuông
    _sendWindowsNotification();
    _playSound();

    // 2. Chuyển chế độ
    if (currentMode == PomodoroMode.work) {
      completedSessions++;
      if (completedSessions % longBreakInterval == 0) {
        currentMode = PomodoroMode.longBreak;
      } else {
        currentMode = PomodoroMode.shortBreak;
      }
    } else {
      currentMode = PomodoroMode.work;
    }

    _resetToCurrentMode();
    startTimer(); // Tự động chạy phiên tiếp theo
  }

  void _playSound() async {
    try {
      // Phát âm thanh beep ngắn
      await _audioPlayer.play(UrlSource('https://actions.google.com/sounds/v1/alarms/beep_short.ogg'));
    } catch (_) {}
  }

  void _sendWindowsNotification() {
    String title = 'Pomodoro Timer';
    String body = currentMode == PomodoroMode.work
        ? 'Hết giờ tập trung! Hãy nghỉ ngơi một chút.'
        : 'Hết giờ nghỉ! Quay lại làm việc nào.';

    LocalNotification notification = LocalNotification(
      title: title,
      body: body,
    );
    notification.show();
  }

  void updateDurations({required int workMin, required int shortMin, required int longMin}) {
    workDuration = workMin * 60;
    shortBreakDuration = shortMin * 60;
    longBreakDuration = longMin * 60;
    _resetToCurrentMode();
  }

  String get formattedTime {
    final min = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final sec = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  double get progress {
    int total = workDuration;
    if (currentMode == PomodoroMode.shortBreak) total = shortBreakDuration;
    if (currentMode == PomodoroMode.longBreak) total = longBreakDuration;
    return total > 0 ? (total - remainingSeconds) / total : 0;
  }
}