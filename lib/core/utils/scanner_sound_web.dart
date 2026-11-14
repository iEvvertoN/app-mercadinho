// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;
import 'package:flutter/services.dart';

void playSuccessBeepImpl() {
  HapticFeedback.mediumImpact();
  try {
    final scanner = js.context['MercadinhoWebScanner'];
    if (scanner != null) {
      scanner.callMethod('playBeep', []);
    }
  } catch (_) {}
}

void playErrorBeepImpl() {
  HapticFeedback.heavyImpact();
  try {
    final scanner = js.context['MercadinhoWebScanner'];
    if (scanner != null) {
      scanner.callMethod('playErrorBeep', []);
    }
  } catch (_) {}
}

