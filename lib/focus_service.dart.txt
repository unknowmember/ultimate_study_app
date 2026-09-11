import 'dart:async'; // Đã sửa lỗi thừa số 0 ở đây
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart';

int _keyboardHookProc(int nCode, int wParam, int lParam) {
  if (nCode == HC_ACTION && FocusService.isFocusActive) {
    if (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN) {
      final pKb = Pointer<KBDLLHOOKSTRUCT>.fromAddress(lParam);
      final vkCode = pKb.ref.vkCode;

      if (vkCode == VK_LWIN || vkCode == VK_RWIN) return 1;
      
      final isAltPressed = (pKb.ref.flags & LLKHF_ALTDOWN) != 0;
      if (isAltPressed && (vkCode == VK_TAB || vkCode == VK_ESCAPE)) {
        return 1;
      }
    }
  }
  return CallNextHookEx(FocusService._hHook, nCode, wParam, lParam);
}

class FocusService extends ChangeNotifier {
  static final FocusService _instance = FocusService._internal();
  factory FocusService() => _instance;
  FocusService._internal();

  static int _hHook = NULL;
  static bool isFocusActive = false;
  
  Timer? _focusTimer;
  int totalSeconds = 0;
  int remainingSeconds = 0;

  double get progress => totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;

  Future<void> startFocusMode(Duration duration) async {
    if (duration.inSeconds <= 0) return;

    isFocusActive = true;
    totalSeconds = duration.inSeconds;
    remainingSeconds = totalSeconds;

    if (defaultTargetPlatform == TargetPlatform.windows) {
      final lpfn = Pointer.fromFunction<HOOKPROC>(_keyboardHookProc, 0);
      final hModule = GetModuleHandle(nullptr);
      _hHook = SetWindowsHookEx(WH_KEYBOARD_LL, lpfn, hModule, 0);
    }

    await windowManager.setAlwaysOnTop(true);
    await Future.delayed(const Duration(milliseconds: 50));
    await windowManager.setFullScreen(true);

    _focusTimer?.cancel();
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        remainingSeconds--;
        notifyListeners();
      } else {
        stopFocusMode();
      }
    });

    notifyListeners();
  }

  Future<void> stopFocusMode() async {
    _focusTimer?.cancel();
    _focusTimer = null;
    isFocusActive = false;

    if (_hHook != NULL) {
      UnhookWindowsHookEx(_hHook);
      _hHook = NULL;
    }

    notifyListeners();

    try {
      await windowManager.setAlwaysOnTop(false);
      await Future.delayed(const Duration(milliseconds: 100));
      await windowManager.setFullScreen(false);
    } catch (_) {}
  }

  String get formattedTime {
    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    final seconds = remainingSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}