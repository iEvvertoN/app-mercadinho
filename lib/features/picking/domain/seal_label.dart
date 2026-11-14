/// Lacre de sacola: numeração, conteúdo do rótulo e geração do código.
///
/// O lacre é o que prova que ninguém abriu a sacola depois da conferência.
/// Por isso ele tem **número único por dia**, é impresso e o número fica
/// registrado no pedido. Reimpressão é permitida, mas fica marcada.
library;

import 'package:shared_preferences/shared_preferences.dart';

import 'picking_models.dart';

class SealLabel {
  const SealLabel({
    required this.sealNumber,
    required this.orderId,
    required this.orderCode,
    required this.bagId,
    required this.temperature,
    required this.itemCount,
    required this.createdAt,
    this.reprintCount = 0,
  });

  final String sealNumber;
  final String orderId;
  final String orderCode;
  final String bagId;
  final BagTemperature temperature;
  final int itemCount;
  final DateTime createdAt;
  final int reprintCount;

  String get temperatureLabel {
    switch (temperature) {
      case BagTemperature.dry:
        return 'SECO';
      case BagTemperature.cold:
        return 'GELADO';
    }
  }

  /// Conteúdo do QR. **Não** carrega senha nem dado pessoal: só o suficiente
  /// para amarrar sacola → pedido → lacre na conferência e no handoff.
  String get qrPayload {
    final date = '${createdAt.year.toString().padLeft(4, '0')}'
        '${createdAt.month.toString().padLeft(2, '0')}'
        '${createdAt.day.toString().padLeft(2, '0')}';
    return 'IFD1|$orderId|$bagId|$sealNumber|${temperature.name}|$date';
  }

  SealLabel reprinted() => SealLabel(
        sealNumber: sealNumber,
        orderId: orderId,
        orderCode: orderCode,
        bagId: bagId,
        temperature: temperature,
        itemCount: itemCount,
        createdAt: createdAt,
        reprintCount: reprintCount + 1,
      );
}

/// Numeração sequencial por dia: `0911-0001`, `0911-0002`…
///
/// Sequencial (e não aleatório) porque é o que permite ao conferente perceber
/// um lacre faltando na sequência do dia.
class SealNumberGenerator {
  static const _keyPrefix = 'picking.seal.counter.';

  Future<String> next({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final dayKey =
        '${at.year.toString().padLeft(4, '0')}${at.month.toString().padLeft(2, '0')}${at.day.toString().padLeft(2, '0')}';
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$dayKey';
    final current = prefs.getInt(key) ?? 0;
    final next = current + 1;
    await prefs.setInt(key, next);
    final shortDay = '${dayKey.substring(4, 6)}${dayKey.substring(6, 8)}';
    return '$shortDay-${next.toString().padLeft(4, '0')}';
  }

  /// Só para teste/diagnóstico: lê o contador sem incrementar.
  Future<int> peek({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final dayKey =
        '${at.year.toString().padLeft(4, '0')}${at.month.toString().padLeft(2, '0')}${at.day.toString().padLeft(2, '0')}';
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_keyPrefix$dayKey') ?? 0;
  }
}

/// Monta os rótulos de uma tarefa: uma sacola seca e uma gelada, conforme os
/// itens. O operador confirma; o app não inventa sacola vazia.
List<({String bagId, BagTemperature temperature, List<String> itemIds})> proposeBags(
  PickingTask task,
) {
  final dry = <String>[];
  final cold = <String>[];
  for (final item in task.items) {
    if (item.isCold) {
      cold.add(item.id);
    } else {
      dry.add(item.id);
    }
  }

  final proposals = <({String bagId, BagTemperature temperature, List<String> itemIds})>[];
  if (dry.isNotEmpty) {
    proposals.add((bagId: 'S1', temperature: BagTemperature.dry, itemIds: dry));
  }
  if (cold.isNotEmpty) {
    proposals.add((
      bagId: dry.isEmpty ? 'S1' : 'S2',
      temperature: BagTemperature.cold,
      itemIds: cold,
    ));
  }
  return proposals;
}
