/// Núcleo do picking: estado, regras e transições.
///
/// Sem UI e sem HTTP de propósito: é a parte que precisa estar certa antes de
/// qualquer tela. As regras aqui são as do processo padronizado
/// (`docs/processo-operacional.md`) — principalmente as que impedem erro:
/// scan obrigatório, substituição acima de 20% exigindo aprovação, e handoff
/// bloqueado quando a contagem de volumes não fecha.
library;

enum PickingStatus { waiting, inProgress, packing, ready, verified, handedOff, canceled }

enum ItemPickStatus { pending, found, missing, substituted, givenUp }

enum CheckMethod { scan, weight, manual }

enum BagTemperature { dry, cold }

enum SubstitutionApproval { notRequired, pending, approved, rejected, expired }

const double substitutePriceTolerance = 0.20;
const double weightTolerance = 0.10;

class PickingResult {
  const PickingResult.ok()
      : ok = true,
        error = null;

  const PickingResult.fail(this.error) : ok = false;

  final bool ok;
  final String? error;

  @override
  String toString() => ok ? 'ok' : 'falha: $error';
}

class PickingSubstitution {
  PickingSubstitution({
    required this.fromProductId,
    required this.fromProductName,
    required this.fromPrice,
    required this.toProductId,
    required this.toProductName,
    required this.toPrice,
    this.approval = SubstitutionApproval.notRequired,
  });

  final String fromProductId;
  final String fromProductName;
  final double fromPrice;
  final String toProductId;
  final String toProductName;
  final double toPrice;

  SubstitutionApproval approval;

  double get priceDeltaPercent =>
      fromPrice <= 0 ? 0 : ((toPrice - fromPrice) / fromPrice) * 100;

  /// Toda substituição acima da tolerância precisa de aprovação do cliente.
  bool get requiresApproval => priceDeltaPercent > substitutePriceTolerance * 100;

  bool get isApproved =>
      !requiresApproval ||
      approval == SubstitutionApproval.approved ||
      approval == SubstitutionApproval.notRequired;

  bool get isBlocked =>
      requiresApproval &&
      (approval == SubstitutionApproval.pending ||
          approval == SubstitutionApproval.rejected ||
          approval == SubstitutionApproval.expired);

  PickingResult approve() {
    if (!requiresApproval) {
      approval = SubstitutionApproval.notRequired;
      return const PickingResult.ok();
    }
    approval = SubstitutionApproval.approved;
    return const PickingResult.ok();
  }

  PickingResult reject() {
    approval = SubstitutionApproval.rejected;
    return const PickingResult.ok();
  }

  PickingResult expire() {
    if (approval == SubstitutionApproval.approved) {
      return const PickingResult.fail('Substituição já aprovada não expira.');
    }
    approval = SubstitutionApproval.expired;
    return const PickingResult.ok();
  }

  Map<String, dynamic> toJson() => {
        'fromProductId': fromProductId,
        'fromProductName': fromProductName,
        'fromPrice': fromPrice,
        'toProductId': toProductId,
        'toProductName': toProductName,
        'toPrice': toPrice,
        'priceDeltaPercent': priceDeltaPercent,
        'requiresApproval': requiresApproval,
        'approval': approval.name,
      };
}

class PickingItem {
  PickingItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.barcode,
    required this.requestedQty,
    required this.unitPrice,
    this.weighable = false,
    this.unit = 'UN',
    this.aisle,
    this.isCold = false,
  });

  final String id;
  final String productId;
  final String name;
  final String barcode;
  final double requestedQty;
  final double unitPrice;
  final bool weighable;
  final String unit;

  /// Item que precisa ir em sacola gelada.
  final bool isCold;

  /// Corredor/prateleira. Hoje o `ProductModel` não tem esse campo — quando
  /// existir no ERP, é o que ordena a caminhada do separador.
  final String? aisle;

  ItemPickStatus status = ItemPickStatus.pending;
  CheckMethod? method;
  double foundQty = 0;
  double? weightGrams;
  String? missingReason;
  PickingSubstitution? substitution;

  bool get isResolved => status != ItemPickStatus.pending;

  double get billedQty {
    if (status != ItemPickStatus.found && status != ItemPickStatus.substituted) return 0;
    if (weighable && weightGrams != null) {
      return weightGrams! / 1000.0;
    }
    return foundQty;
  }

  double get billedTotal => billedQty * unitPrice;

  /// Peso real fora de ±10% do pedido exige conferência (marca, não bloqueia).
  bool get hasWeightDivergence {
    if (!weighable || weightGrams == null || requestedQty <= 0) return false;
    final expected = requestedQty; // em kg
    final actual = weightGrams! / 1000.0;
    return ((actual - expected) / expected).abs() > weightTolerance;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'name': name,
        'barcode': barcode,
        'requestedQty': requestedQty,
        'foundQty': foundQty,
        'weightGrams': weightGrams,
        'weighable': weighable,
        'unit': unit,
        'aisle': aisle,
        'isCold': isCold,
        'status': status.name,
        'method': method?.name,
        'missingReason': missingReason,
        'substitution': substitution?.toJson(),
      };
}

class PickingBag {
  PickingBag({
    required this.id,
    required this.temperature,
    required this.itemIds,
    this.sealNumber,
    this.sealedAt,
  });

  final String id;
  final BagTemperature temperature;
  final List<String> itemIds;
  String? sealNumber;
  DateTime? sealedAt;

  bool get isSealed => sealNumber != null && sealNumber!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'temperature': temperature.name,
        'itemIds': itemIds,
        'sealNumber': sealNumber,
        'sealedAt': sealedAt?.toIso8601String(),
      };
}

/// Uma tarefa de separação = um pedido.
///
/// A tarefa é a dona do estado: nenhum passo "pula" etapa, e cada transição
/// registra hora. O pedido no ERP reflete isso depois, via eventos.
class PickingTask {
  PickingTask({
    required this.orderId,
    required this.code,
    required this.items,
    this.status = PickingStatus.waiting,
    List<PickingBag>? bags,
    this.assigneeId,
    this.startedAt,
    this.finishedAt,
    this.verifiedAt,
    this.handedOffAt,
    this.verifiedBy,
    this.courierId,
    this.volumesCounted,
    this.passwordChecked = false,
    this.cancelReason,
  }) : bags = bags ?? <PickingBag>[];

  final String orderId;
  final String code;
  final List<PickingItem> items;
  final List<PickingBag> bags;

  PickingStatus status;
  String? assigneeId;
  DateTime? startedAt;
  DateTime? finishedAt;
  DateTime? verifiedAt;
  DateTime? handedOffAt;
  String? verifiedBy;
  String? courierId;
  int? volumesCounted;
  bool passwordChecked;
  String? cancelReason;

  int get resolvedCount => items.where((i) => i.isResolved).length;

  double get progress => items.isEmpty ? 0 : resolvedCount / items.length;

  double get fillRate {
    if (items.isEmpty) return 0;
    final found = items
        .where((i) => i.status == ItemPickStatus.found || i.status == ItemPickStatus.substituted)
        .length;
    return found / items.length;
  }

  bool get hasPendingItems => items.any((i) => !i.isResolved);

  bool get hasBlockedSubstitution => items.any((i) => i.substitution?.isBlocked ?? false);

  int get expectedVolumes => bags.isEmpty ? 0 : bags.length;

  int get sealedBags => bags.where((b) => b.isSealed).length;

  bool get allBagsSealed => bags.isNotEmpty && sealedBags == bags.length;

  double get billedTotal => items.fold(0, (sum, item) => sum + item.billedTotal);

  List<PickingItem> get itemsInWalkOrder {
    final sorted = [...items];
    sorted.sort((a, b) {
      final aisleA = a.aisle ?? 'zzz';
      final aisleB = b.aisle ?? 'zzz';
      final byAisle = aisleA.compareTo(aisleB);
      if (byAisle != 0) return byAisle;
      return a.name.compareTo(b.name);
    });
    return sorted;
  }

  // ---------------------------------------------------------------- transições

  PickingResult start(String assignee) {
    if (status != PickingStatus.waiting) {
      return PickingResult.fail('Tarefa não está aguardando (${status.name}).');
    }
    if (assignee.trim().isEmpty) {
      return const PickingResult.fail('Informe o separador.');
    }
    assigneeId = assignee.trim();
    startedAt = DateTime.now();
    status = PickingStatus.inProgress;
    return const PickingResult.ok();
  }

  PickingItem? itemById(String itemId) {
    for (final item in items) {
      if (item.id == itemId) return item;
    }
    return null;
  }

  /// Conferência por código de barras. O código **precisa** bater com o
  /// esperado: é isso que impede trocar produto sem perceber.
  PickingResult scan(String itemId, {required String barcode, double? quantity}) {
    if (status != PickingStatus.inProgress && status != PickingStatus.packing) {
      return PickingResult.fail('Tarefa não está em separação (${status.name}).');
    }
    final item = itemById(itemId);
    if (item == null) return const PickingResult.fail('Item não pertence à tarefa.');

    final clean = barcode.trim();
    if (item.barcode.isNotEmpty && clean != item.barcode) {
      return PickingResult.fail('Código não confere com "${item.name}".');
    }

    item.method = CheckMethod.scan;
    item.foundQty = quantity ?? item.requestedQty;
    item.status = ItemPickStatus.found;
    item.missingReason = null;
    return const PickingResult.ok();
  }

  /// Item pesável: a prova é o peso real, não a quantidade digitada.
  PickingResult weigh(String itemId, {required double grams}) {
    if (grams <= 0) return const PickingResult.fail('Peso precisa ser maior que zero.');
    final item = itemById(itemId);
    if (item == null) return const PickingResult.fail('Item não pertence à tarefa.');
    if (!item.weighable) {
      return const PickingResult.fail('Item não é pesável.');
    }
    item.method = CheckMethod.weight;
    item.weightGrams = grams;
    item.foundQty = grams / 1000.0;
    item.status = ItemPickStatus.found;
    item.missingReason = null;
    return const PickingResult.ok();
  }

  PickingResult markMissing(String itemId, {required String reason}) {
    if (reason.trim().isEmpty) {
      return const PickingResult.fail('Informe o motivo da falta.');
    }
    final item = itemById(itemId);
    if (item == null) return const PickingResult.fail('Item não pertence à tarefa.');
    item.status = ItemPickStatus.missing;
    item.missingReason = reason.trim();
    item.foundQty = 0;
    item.weightGrams = null;
    return const PickingResult.ok();
  }

  PickingResult giveUp(String itemId, {required String reason}) {
    if (reason.trim().isEmpty) {
      return const PickingResult.fail('Informe o motivo da desistência.');
    }
    final item = itemById(itemId);
    if (item == null) return const PickingResult.fail('Item não pertence à tarefa.');
    item.status = ItemPickStatus.givenUp;
    item.missingReason = reason.trim();
    item.foundQty = 0;
    return const PickingResult.ok();
  }

  /// Propõe substituição. Acima da tolerância fica `pending` até decisão.
  PickingResult proposeSubstitution(
    String itemId, {
    required String toProductId,
    required String toProductName,
    required double toPrice,
  }) {
    final item = itemById(itemId);
    if (item == null) return const PickingResult.fail('Item não pertence à tarefa.');
    if (!item.isResolved && item.status != ItemPickStatus.pending) {
      return const PickingResult.fail('Item já conferido.');
    }

    final substitution = PickingSubstitution(
      fromProductId: item.productId,
      fromProductName: item.name,
      fromPrice: item.unitPrice,
      toProductId: toProductId,
      toProductName: toProductName,
      toPrice: toPrice,
      approval: SubstitutionApproval.notRequired,
    );
    substitution.approval = substitution.requiresApproval
        ? SubstitutionApproval.pending
        : SubstitutionApproval.notRequired;

    item.substitution = substitution;
    item.status = substitution.requiresApproval
        ? ItemPickStatus.pending
        : ItemPickStatus.substituted;
    if (substitution.requiresApproval) {
      item.missingReason = 'Aguardando aprovação do cliente';
    }
    return const PickingResult.ok();
  }

  PickingResult decideSubstitution(String itemId, {required bool approved}) {
    final item = itemById(itemId);
    if (item == null) return const PickingResult.fail('Item não pertence à tarefa.');
    final substitution = item.substitution;
    if (substitution == null) {
      return const PickingResult.fail('Item não tem substituição proposta.');
    }
    if (!substitution.requiresApproval) {
      return const PickingResult.fail('Substituição não exige aprovação.');
    }

    if (approved) {
      substitution.approve();
      item.status = ItemPickStatus.substituted;
      item.foundQty = item.requestedQty;
      item.missingReason = null;
    } else {
      substitution.reject();
      item.status = ItemPickStatus.missing;
      item.missingReason = 'Substituição recusada pelo cliente';
    }
    return const PickingResult.ok();
  }

  PickingResult addBag({
    required String bagId,
    required BagTemperature temperature,
    required List<String> itemIds,
  }) {
    if (bagId.trim().isEmpty) return const PickingResult.fail('Sacola sem identificação.');
    if (itemIds.isEmpty) return const PickingResult.fail('Sacola sem itens.');
    bags.add(PickingBag(id: bagId, temperature: temperature, itemIds: [...itemIds]));
    return const PickingResult.ok();
  }

  PickingResult sealBag(String bagId, {required String sealNumber}) {
    if (sealNumber.trim().isEmpty) {
      return const PickingResult.fail('Informe o número do lacre.');
    }
    final duplicated = bags.any((b) => b.id != bagId && b.sealNumber == sealNumber.trim());
    if (duplicated) return const PickingResult.fail('Lacre já usado em outra sacola.');

    for (final bag in bags) {
      if (bag.id == bagId) {
        bag.sealNumber = sealNumber.trim();
        bag.sealedAt = DateTime.now();
        return const PickingResult.ok();
      }
    }
    return const PickingResult.fail('Sacola não encontrada.');
  }

  /// Fecha a separação. Exige tudo resolvido e todas as sacolas lacradas.
  PickingResult finish() {
    if (status != PickingStatus.inProgress) {
      return PickingResult.fail('Tarefa não está em separação (${status.name}).');
    }
    if (hasPendingItems) {
      return const PickingResult.fail('Ainda há itens pendentes.');
    }
    if (hasBlockedSubstitution) {
      return const PickingResult.fail('Há substituição aguardando aprovação.');
    }
    if (bags.isEmpty) {
      return const PickingResult.fail('Nenhuma sacola registrada.');
    }
    if (!allBagsSealed) {
      return const PickingResult.fail('Todas as sacolas precisam estar lacradas.');
    }
    finishedAt = DateTime.now();
    status = PickingStatus.ready;
    return const PickingResult.ok();
  }

  /// Conferência por outra pessoa. Divergência de volume bloqueia.
  PickingResult verify({required String by, required int volumesCounted}) {
    if (status != PickingStatus.ready) {
      return PickingResult.fail('Tarefa não está pronta (${status.name}).');
    }
    if (by.trim().isEmpty) return const PickingResult.fail('Informe quem conferiu.');
    if (volumesCounted != expectedVolumes) {
      return PickingResult.fail(
        'Contagem não confere: esperado $expectedVolumes, contado $volumesCounted.',
      );
    }
    verifiedBy = by.trim();
    this.volumesCounted = volumesCounted;
    verifiedAt = DateTime.now();
    status = PickingStatus.verified;
    return const PickingResult.ok();
  }

  /// Passagem para o entregador: contagem dupla + senha conferida.
  PickingResult handOff({required String courierId, required bool passwordChecked}) {
    if (status != PickingStatus.verified) {
      return PickingResult.fail('Pedido não foi conferido (${status.name}).');
    }
    if (courierId.trim().isEmpty) return const PickingResult.fail('Informe o entregador.');
    this.courierId = courierId.trim();
    this.passwordChecked = passwordChecked;
    handedOffAt = DateTime.now();
    status = PickingStatus.handedOff;
    return const PickingResult.ok();
  }

  PickingResult cancel({required String reason}) {
    if (status == PickingStatus.handedOff) {
      return const PickingResult.fail('Pedido já saiu com o entregador.');
    }
    if (reason.trim().isEmpty) return const PickingResult.fail('Informe o motivo.');
    cancelReason = reason.trim();
    status = PickingStatus.canceled;
    return const PickingResult.ok();
  }

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'code': code,
        'status': status.name,
        'assigneeId': assigneeId,
        'startedAt': startedAt?.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'verifiedAt': verifiedAt?.toIso8601String(),
        'verifiedBy': verifiedBy,
        'handedOffAt': handedOffAt?.toIso8601String(),
        'courierId': courierId,
        'volumesCounted': volumesCounted,
        'passwordChecked': passwordChecked,
        'items': items.map((i) => i.toJson()).toList(),
        'bags': bags.map((b) => b.toJson()).toList(),
      };
}
