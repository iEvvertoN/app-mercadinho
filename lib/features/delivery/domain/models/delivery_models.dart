/// Modelos do módulo de entregas (papel "entregador").
///
/// Reaproveita o vocabulário do mercadinho: pedido, volumes secos/gelados,
/// janela de entrega e senha de entrega. O que vem do estudo do iFood é apenas
/// o essencial: estado versionável, evento leve (geo + hora) e prova separada.
library;

import 'dart:convert';

enum StopStatus { pending, onRoute, arrived, delivered, failed }

const _stopStatusWire = {
  StopStatus.pending: 'pending',
  StopStatus.onRoute: 'on_route',
  StopStatus.arrived: 'arrived',
  StopStatus.delivered: 'delivered',
  StopStatus.failed: 'failed',
};

const _stopStatusLabel = {
  StopStatus.pending: 'Aguardando',
  StopStatus.onRoute: 'Em rota',
  StopStatus.arrived: 'No cliente',
  StopStatus.delivered: 'Entregue',
  StopStatus.failed: 'Não entregue',
};

String stopStatusToWire(StopStatus status) => _stopStatusWire[status]!;

String stopStatusLabel(StopStatus status) => _stopStatusLabel[status]!;

StopStatus stopStatusFromWire(Object? value) {
  final raw = value?.toString();
  for (final entry in _stopStatusWire.entries) {
    if (entry.value == raw) return entry.key;
  }
  return StopStatus.pending;
}

enum ProofMethod { password, signature, passwordAndSignature }

const _proofMethodWire = {
  ProofMethod.password: 'password',
  ProofMethod.signature: 'signature',
  ProofMethod.passwordAndSignature: 'password_and_signature',
};

String proofMethodToWire(ProofMethod method) => _proofMethodWire[method]!;

ProofMethod proofMethodFromWire(Object? value) {
  final raw = value?.toString();
  for (final entry in _proofMethodWire.entries) {
    if (entry.value == raw) return entry.key;
  }
  return ProofMethod.password;
}

/// Motivos de falha de entrega. Lista curta de propósito: motivo longo não é
/// preenchido no calor da rua.
const deliveryFailureReasons = <String>[
  'Cliente ausente',
  'Endereço não encontrado',
  'Cliente recusou o pedido',
  'Local fechado',
  'Outro motivo',
];

class DeliveryStop {
  const DeliveryStop({
    required this.orderId,
    required this.code,
    required this.customerName,
    required this.addressText,
    this.timeSlot,
    this.dryVolumes = 0,
    this.coldVolumes = 0,
    this.itemsCount = 0,
    this.totalAmount = 0,
    this.phone,
    this.latitude,
    this.longitude,
    this.status = StopStatus.pending,
    this.sequence = 0,
    this.arrivedAt,
    this.deliveredAt,
    this.failureReason,
    this.observation,
  });

  /// Identidade no ERP (usada nas chamadas de status/prova).
  final String orderId;

  /// Código legível mostrado ao entregador (ex.: "1042").
  final String code;

  final String customerName;
  final String addressText;
  final String? timeSlot;
  final int dryVolumes;
  final int coldVolumes;
  final int itemsCount;
  final double totalAmount;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final StopStatus status;
  final int sequence;
  final DateTime? arrivedAt;
  final DateTime? deliveredAt;
  final String? failureReason;
  final String? observation;

  int get totalVolumes => dryVolumes + coldVolumes;

  bool get isOpen =>
      status == StopStatus.pending ||
      status == StopStatus.onRoute ||
      status == StopStatus.arrived;

  DeliveryStop copyWith({
    StopStatus? status,
    DateTime? arrivedAt,
    DateTime? deliveredAt,
    String? failureReason,
    String? observation,
  }) {
    return DeliveryStop(
      orderId: orderId,
      code: code,
      customerName: customerName,
      addressText: addressText,
      timeSlot: timeSlot,
      dryVolumes: dryVolumes,
      coldVolumes: coldVolumes,
      itemsCount: itemsCount,
      totalAmount: totalAmount,
      phone: phone,
      latitude: latitude,
      longitude: longitude,
      status: status ?? this.status,
      sequence: sequence,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      failureReason: failureReason ?? this.failureReason,
      observation: observation ?? this.observation,
    );
  }

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'code': code,
        'customerName': customerName,
        'addressText': addressText,
        'timeSlot': timeSlot,
        'dryVolumes': dryVolumes,
        'coldVolumes': coldVolumes,
        'itemsCount': itemsCount,
        'totalAmount': totalAmount,
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
        'status': stopStatusToWire(status),
        'sequence': sequence,
        'arrivedAt': arrivedAt?.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
        'failureReason': failureReason,
        'observation': observation,
      };

  factory DeliveryStop.fromJson(Map<String, dynamic> json) {
    double? asDouble(Object? value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    int asInt(Object? value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    DateTime? asDate(Object? value) {
      if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
      return null;
    }

    return DeliveryStop(
      orderId: (json['orderId'] ?? json['id'] ?? '').toString(),
      code: (json['code'] ?? json['orderCode'] ?? json['orderId'] ?? '').toString(),
      customerName: (json['customerName'] ?? json['cliente'] ?? 'Cliente').toString(),
      addressText: (json['addressText'] ?? json['address'] ?? json['endereco'] ?? '').toString(),
      timeSlot: (json['timeSlot'] ?? json['scheduledWindow'])?.toString(),
      dryVolumes: asInt(json['dryVolumes'] ?? json['volumesSecos']),
      coldVolumes: asInt(json['coldVolumes'] ?? json['volumesGelados']),
      itemsCount: asInt(json['itemsCount'] ?? json['items']),
      totalAmount: asDouble(json['totalAmount'] ?? json['total']) ?? 0,
      phone: json['phone']?.toString(),
      latitude: asDouble(json['latitude'] ?? json['lat']),
      longitude: asDouble(json['longitude'] ?? json['lng']),
      status: stopStatusFromWire(json['status']),
      sequence: asInt(json['sequence'] ?? json['seq']),
      arrivedAt: asDate(json['arrivedAt']),
      deliveredAt: asDate(json['deliveredAt']),
      failureReason: json['failureReason']?.toString(),
      observation: json['observation']?.toString(),
    );
  }
}

class DeliveryRoute {
  const DeliveryRoute({
    required this.id,
    required this.courierId,
    required this.date,
    required this.stops,
    this.storeName,
    this.version = 1,
    this.isDemo = false,
  });

  final String id;
  final String courierId;
  final DateTime date;
  final List<DeliveryStop> stops;
  final String? storeName;

  /// Versão do estado da rota. Serve para o app recusar estado velho quando
  /// volta do offline (padrão observado no iFood, adaptado).
  final int version;

  /// Rota de demonstração, gerada localmente quando o ERP ainda não expõe
  /// os endpoints de entrega.
  final bool isDemo;

  int get total => stops.length;

  int get delivered => stops.where((s) => s.status == StopStatus.delivered).length;

  int get failed => stops.where((s) => s.status == StopStatus.failed).length;

  int get remaining => stops.where((s) => s.isOpen).length;

  int get totalVolumes => stops.fold(0, (sum, s) => sum + s.totalVolumes);

  double get progress => total == 0 ? 0 : (delivered + failed) / total;

  DeliveryStop? stopByOrderId(String orderId) {
    for (final stop in stops) {
      if (stop.orderId == orderId) return stop;
    }
    return null;
  }

  DeliveryRoute copyWith({
    List<DeliveryStop>? stops,
    int? version,
    DateTime? date,
  }) {
    return DeliveryRoute(
      id: id,
      courierId: courierId,
      date: date ?? this.date,
      stops: stops ?? this.stops,
      storeName: storeName,
      version: version ?? this.version,
      isDemo: isDemo,
    );
  }

  DeliveryRoute replaceStop(DeliveryStop updated) {
    final next = <DeliveryStop>[];
    for (final stop in stops) {
      next.add(stop.orderId == updated.orderId ? updated : stop);
    }
    return copyWith(stops: next, version: version + 1);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'courierId': courierId,
        'date': date.toIso8601String(),
        'storeName': storeName,
        'version': version,
        'isDemo': isDemo,
        'stops': stops.map((s) => s.toJson()).toList(),
      };

  factory DeliveryRoute.fromJson(Map<String, dynamic> json) {
    final rawStops = (json['stops'] as List?) ?? const [];
    return DeliveryRoute(
      id: (json['id'] ?? 'route').toString(),
      courierId: (json['courierId'] ?? '').toString(),
      date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      storeName: json['storeName']?.toString(),
      version: (json['version'] is num) ? (json['version'] as num).toInt() : 1,
      isDemo: json['isDemo'] == true,
      stops: rawStops
          .whereType<Map>()
          .map((m) => DeliveryStop.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

class DeliveryProof {
  const DeliveryProof({
    required this.orderId,
    required this.method,
    required this.capturedAt,
    this.password,
    this.signature,
    this.latitude,
    this.longitude,
    this.appVersion = '1.0.0',
  });

  final String orderId;
  final ProofMethod method;
  final DateTime capturedAt;
  final String? password;

  /// Assinatura normalizada (0..1) coletada no dedo, ponto a ponto.
  final List<List<double>>? signature;

  final double? latitude;
  final double? longitude;
  final String appVersion;

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'method': proofMethodToWire(method),
        'password': password,
        'signature': signature,
        'capturedAt': capturedAt.toIso8601String(),
        'lat': latitude,
        'lng': longitude,
        'appVersion': appVersion,
      };
}

/// Evento que não subiu para o ERP e fica na fila local.
///
/// A fila é o que impede o entregador de "perder" uma entrega por falta de
/// sinal — o padrão que o iFood resolve com o handshake offline.
class PendingEvent {
  PendingEvent({
    required this.id,
    required this.kind,
    required this.payload,
    required this.createdAt,
    this.orderId,
    this.attempts = 0,
    this.lastError,
  });

  final String id;

  /// `status`, `proof` ou `shift`.
  final String kind;

  final String? orderId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int attempts;
  String? lastError;

  PendingEvent withAttemptError(String error) {
    attempts += 1;
    lastError = error;
    return this;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'orderId': orderId,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
        'lastError': lastError,
      };

  factory PendingEvent.fromJson(Map<String, dynamic> json) {
    return PendingEvent(
      id: (json['id'] ?? '').toString(),
      kind: (json['kind'] ?? 'status').toString(),
      orderId: json['orderId']?.toString(),
      payload: Map<String, dynamic>.from((json['payload'] as Map?) ?? const {}),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
      attempts: (json['attempts'] is num) ? (json['attempts'] as num).toInt() : 0,
      lastError: json['lastError']?.toString(),
    );
  }

  String encode() => jsonEncode(toJson());

  static PendingEvent? decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return PendingEvent.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Evento corrompido é descartado na leitura, não derruba a fila.
    }
    return null;
  }
}
