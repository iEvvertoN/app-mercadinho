import 'dart:ffi' as ffi;
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

typedef _Win32BeepNative = ffi.Int32 Function(ffi.Uint32 dwFreq, ffi.Uint32 dwDuration);
typedef _Win32BeepDart = int Function(int dwFreq, int dwDuration);

_Win32BeepDart? _win32Beep;

void _initWin32Beep() {
  if (_win32Beep != null || !Platform.isWindows) return;
  try {
    final kernel32 = ffi.DynamicLibrary.open('kernel32.dll');
    _win32Beep = kernel32.lookupFunction<_Win32BeepNative, _Win32BeepDart>('Beep');
  } catch (_) {}
}

void playSuccessBeepImpl() {
  HapticFeedback.mediumImpact();
  SystemSound.play(SystemSoundType.click);
  if (Platform.isWindows) {
    Future.microtask(() {
      try {
        _initWin32Beep();
        _win32Beep?.call(2650, 85);
      } catch (_) {}
    });
  }
}

void playErrorBeepImpl() {
  HapticFeedback.heavyImpact();
  SystemSound.play(SystemSoundType.alert);
  if (Platform.isWindows) {
    Future.microtask(() {
      try {
        _initWin32Beep();
        _win32Beep?.call(330, 180);
      } catch (_) {}
    });
  }
}

