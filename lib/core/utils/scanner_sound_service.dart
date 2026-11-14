import 'scanner_sound_io.dart'
    if (dart.library.html) 'scanner_sound_web.dart' as impl;

/// Serviço de Efeitos Sonoros de Leitor de Código de Barras de Supermercado (2650Hz Laser Beep)
class ScannerSoundService {
  /// Toca o "BIP" clássico de caixa de supermercado quando um código é lido com sucesso
  static void playSuccessBeep() {
    impl.playSuccessBeepImpl();
  }

  /// Toca o som grave de alerta quando o código de barras não é encontrado no ERP
  static void playErrorBeep() {
    impl.playErrorBeepImpl();
  }
}

