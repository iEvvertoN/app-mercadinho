/// Impressão do rótulo de lacre em impressora térmica ESC/POS.
///
/// Por que ESC/POS e não PDF: impressora térmica de varejo (Epson TM-T20,
/// Elgin, Bematech) fala ESC/POS por rede na porta 9100. Mandar os bytes
/// direto resolve sem SDK, sem driver e sem app intermediário — e o cupom sai
/// na hora, que é o que a operação precisa.
///
/// O envio por socket só existe em Android/iOS/desktop; na web o app mostra o
/// conteúdo do rótulo e não tenta imprimir.
library;

import 'dart:convert';
import 'dart:io' show Socket;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/seal_label.dart';

class PrinterConfig {
  const PrinterConfig({required this.host, this.port = 9100});

  final String host;
  final int port;

  bool get isConfigured => host.trim().isNotEmpty;

  String get label => isConfigured ? '$host:$port' : 'não configurada';
}

class SealPrinterStore {
  static const _hostKey = 'picking.printer.host';
  static const _portKey = 'picking.printer.port';

  Future<PrinterConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PrinterConfig(
      host: prefs.getString(_hostKey) ?? '',
      port: prefs.getInt(_portKey) ?? 9100,
    );
  }

  Future<void> save(PrinterConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hostKey, config.host.trim());
    await prefs.setInt(_portKey, config.port);
  }
}

/// Constrói os bytes ESC/POS de um rótulo de 58 mm.
class EscPosBuilder {
  final BytesBuilder _bytes = BytesBuilder();

  List<int> build(SealLabel label) {
    _init();
    _alignCenter();
    _bold(true);
    _textSize(2, 2);
    _line('LACRE ${label.sealNumber}');
    _textSize(1, 1);
    _bold(false);
    _line('');
    _textSize(2, 2);
    _line(label.temperatureLabel);
    _textSize(1, 1);
    _line('');
    _bold(true);
    _line('PEDIDO ${label.orderCode}');
    _line('SACOLA ${label.bagId}');
    _bold(false);
    _line('${label.itemCount} item(ns)');
    _line('');
    _qr(label.qrPayload);
    _line('');
    _line('--------------------------------');
    _line('Conferido e lacrado');
    if (label.reprintCount > 0) {
      _line('REIMPRESSO x${label.reprintCount}');
    }
    _feed(3);
    _cut();
    return _bytes.toBytes();
  }

  /// Texto simples, útil para preview e para teste sem impressora.
  String buildPreview(SealLabel label) => [
        '============================',
        '       LACRE ${label.sealNumber}',
        '============================',
        '  ${label.temperatureLabel}',
        '  PEDIDO ${label.orderCode}  |  SACOLA ${label.bagId}',
        '  ${label.itemCount} item(ns)',
        '  QR: ${label.qrPayload}',
        '----------------------------',
        '  Conferido e lacrado',
        if (label.reprintCount > 0) '  REIMPRESSO x${label.reprintCount}',
      ].join('\n');

  void _init() {
    _bytes.add(const [0x1B, 0x40]); // ESC @
    _bytes.add(const [0x1B, 0x61, 0x01]); // alinhamento centro
  }

  void _alignCenter() => _bytes.add(const [0x1B, 0x61, 0x01]);

  void _bold(bool on) => _bytes.add([0x1B, 0x45, on ? 0x01 : 0x00]);

  void _textSize(int width, int height) =>
      _bytes.add([0x1D, 0x21, ((width - 1) << 4) | (height - 1)]);

  void _line(String text) {
    _bytes.add(utf8.encode(_sanitize(text)));
    _bytes.add(const [0x0A]);
  }

  void _feed(int lines) => _bytes.add([0x1B, 0x64, lines]);

  void _cut() => _bytes.add(const [0x1D, 0x56, 0x42, 0x00]); // partial cut

  /// QR nativo do ESC/POS (modelo 2, correção M).
  void _qr(String data) {
    final payload = utf8.encode(data);
    final length = payload.length + 3;
    final pL = length & 0xFF;
    final pH = (length >> 8) & 0xFF;

    // Seleciona modelo 2
    _bytes.add(const [0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00]);
    // Tamanho do módulo (6)
    _bytes.add(const [0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x06]);
    // Correção de erro M
    _bytes.add(const [0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x31]);
    // Armazena dados
    _bytes.add([0x1D, 0x28, 0x6B, pL, pH, 0x31, 0x50, 0x30, ...payload]);
    // Imprime
    _bytes.add(const [0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);
  }

  /// Acentuação depende da página de código da impressora. Para não sair lixo,
  /// normaliza o texto do rótulo (que é curto e controlado) para ASCII.
  String _sanitize(String input) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
    const to = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final index = from.indexOf(char);
      buffer.write(index >= 0 ? to[index] : char);
    }
    return buffer.toString();
  }
}

sealed class PrinterResult {
  const PrinterResult();
}

class PrinterQueued extends PrinterResult {
  const PrinterQueued(this.bytes);
  final int bytes;
}

class PrinterFailed extends PrinterResult {
  const PrinterFailed(this.message);
  final String message;
}

class PrinterNotConfigured extends PrinterResult {
  const PrinterNotConfigured();
}

class SealPrinter {
  SealPrinter({SealPrinterStore? store, EscPosBuilder? builder})
      : _store = store ?? SealPrinterStore(),
        _builder = builder ?? EscPosBuilder();

  final SealPrinterStore _store;
  final EscPosBuilder _builder;

  Future<PrinterConfig> config() => _store.load();

  Future<void> configure(PrinterConfig config) => _store.save(config);

  String preview(SealLabel label) => _builder.buildPreview(label);

  /// Envia o rótulo. Retorna o resultado sem lançar: imprimir não pode
  /// derrubar a operação de fechamento.
  Future<PrinterResult> print(SealLabel label) async {
    final config = await _store.load();
    if (!config.isConfigured) return const PrinterNotConfigured();

    if (kIsWeb) {
      return const PrinterFailed(
        'Impressão direta não funciona na versão web. Configure um servidor de impressão.',
      );
    }

    final bytes = _builder.build(label);
    Socket? socket;
    try {
      socket = await Socket.connect(
        config.host.trim(),
        config.port,
        timeout: const Duration(seconds: 5),
      );
      socket.add(bytes);
      await socket.flush();
      return PrinterQueued(bytes.length);
    } catch (error) {
      return PrinterFailed('Falha ao imprimir em ${config.label}: $error');
    } finally {
      await socket?.close();
    }
  }
}
