import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/delivery_api_service.dart';
import '../data/delivery_store.dart';
import '../data/location_service.dart';
import '../domain/models/delivery_models.dart';

enum DeliveryMode { live, demo }

/// Estado do módulo de entregas.
///
/// Regra de ouro: toda ação que muda o pedido é aplicada **primeiro** no
/// estado local e só depois tentada no ERP. Se a rede falhar, o evento entra na
/// fila e o entregador continua trabalhando — é isso que evita "perdi a
/// entrega porque o sinal caiu".
class DeliveryController extends ChangeNotifier {
  DeliveryController({
    DeliveryApiService? api,
    DeliveryStore? store,
    LocationService? location,
  })  : _api = api ?? DeliveryApiService(),
        _store = store ?? DeliveryStore(),
        _location = location ?? const LocationService();

  static const String appVersion = '1.0.0';

  final DeliveryApiService _api;
  final DeliveryStore _store;
  final LocationService _location;

  bool _disposed = false;
  Timer? _pollTimer;

  String courierId = 'entregador-01';
  String courierName = 'Entregador';

  DeliveryRoute? route;
  DeliveryMode mode = DeliveryMode.live;
  bool loading = false;
  bool syncing = false;
  bool shiftOpen = false;
  DateTime? shiftStartedAt;
  DateTime? lastSync;
  String? errorMessage;

  List<PendingEvent> _queue = <PendingEvent>[];
  int get pendingCount => _queue.length;

  bool get hasRoute => route != null;
  bool get isDemo => mode == DeliveryMode.demo;
  bool get hasPending => _queue.isNotEmpty;

  List<DeliveryStop> get openStops =>
      (route?.stops ?? const <DeliveryStop>[]).where((s) => s.isOpen).toList();

  String get shiftLabel {
    if (!shiftOpen) return 'Turno fechado';
    final started = shiftStartedAt;
    if (started == null) return 'Turno aberto';
    final elapsed = DateTime.now().difference(started);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;
    return 'Turno aberto há ${hours}h${minutes.toString().padLeft(2, '0')}';
  }

  Future<void> init() async {
    final courier = await _store.loadCourier();
    if (courier != null && (courier['id'] ?? '').isNotEmpty) {
      courierId = courier['id']!;
      courierName = courier['name']?.isNotEmpty == true ? courier['name']! : courierName;
    }

    final shift = await _store.loadShift();
    shiftOpen = shift.open;
    shiftStartedAt = shift.startedAt;

    _queue = await _store.loadQueue();
    lastSync = await _store.loadLastSync();

    final cached = await _store.loadRoute();
    if (cached != null) {
      route = cached;
      mode = cached.isDemo ? DeliveryMode.demo : DeliveryMode.live;
    }

    _safeNotify();
    await refresh();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_disposed && !loading && !syncing) {
        refresh(silent: true);
      }
    });
  }

  Future<void> refresh({bool silent = false}) async {
    if (loading) return;
    if (!silent) {
      loading = true;
      errorMessage = null;
      _safeNotify();
    }

    final response = await _api.fetchRoute(courierId: courierId);

    if (response.ok && response.data != null) {
      final fetched = _mergeWithLocal(DeliveryRoute.fromJson(response.data!));
      route = fetched;
      mode = DeliveryMode.live;
      errorMessage = null;
      lastSync = DateTime.now();
      await _store.saveRoute(fetched);
      await _store.saveLastSync(lastSync!);
    } else if (response.unsupported) {
      // ERP sem os endpoints de entrega: entra em demonstração para o app
      // continuar utilizável e a integração ser feita depois.
      mode = DeliveryMode.demo;
      if (route == null || !route!.isDemo) {
        route = _demoRoute();
        await _store.saveRoute(route);
      }
      errorMessage = null;
    } else if (!silent) {
      errorMessage = 'Sem conexão. Mostrando a última rota salva.';
      if (route == null) {
        final cached = await _store.loadRoute();
        if (cached != null) route = cached;
      }
    }

    loading = false;
    _safeNotify();
  }

  /// Preserva o que o entregador já fez offline quando a rota volta do ERP.
  DeliveryRoute _mergeWithLocal(DeliveryRoute incoming) {
    final current = route;
    if (current == null || current.stops.isEmpty) return incoming;

    final merged = incoming.stops.map((stop) {
      final local = current.stopByOrderId(stop.orderId);
      if (local == null) return stop;
      // Estado local "avançado" vence o remoto: nunca retroceder uma entrega
      // já concluída no aparelho.
      if (_statusRank(local.status) > _statusRank(stop.status)) {
        return stop.copyWith(
          status: local.status,
          arrivedAt: local.arrivedAt,
          deliveredAt: local.deliveredAt,
          failureReason: local.failureReason,
        );
      }
      return stop;
    }).toList();

    return incoming.copyWith(stops: merged);
  }

  int _statusRank(StopStatus status) => switch (status) {
        StopStatus.pending => 0,
        StopStatus.onRoute => 1,
        StopStatus.arrived => 2,
        StopStatus.delivered => 3,
        StopStatus.failed => 3,
      };

  Future<void> openShift() async {
    shiftOpen = true;
    shiftStartedAt = DateTime.now();
    await _store.saveShift(open: true, startedAt: shiftStartedAt);
    _safeNotify();
    await _emitShift(open: true);
  }

  Future<void> closeShift() async {
    shiftOpen = false;
    await _store.saveShift(open: false);
    _safeNotify();
    await _emitShift(open: false);
  }

  Future<void> _emitShift({required bool open}) async {
    final point = await _location.lastKnown();
    final response = await _api.pushShift(
      courierId: courierId,
      open: open,
      at: DateTime.now(),
      latitude: point?.latitude,
      longitude: point?.longitude,
    );
    if (!response.ok && !response.unsupported) {
      _enqueue(
        kind: 'shift',
        payload: {
          'courierId': courierId,
          'open': open,
          'at': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  /// Coloca todos os pedidos pendentes em rota ("saiu para entrega").
  /// Marca **um** pedido como "saiu para entrega".
  ///
  /// A operação permite os dois modos: liberar pedido por pedido (padrão) ou
  /// confirmar a retirada do lote inteiro na loja (explícito, na tela da rota).
  /// Antes, um único toque marcava todos — o que fazia o cliente receber
  /// "saiu para entrega" para pedidos que ainda estavam na loja.
  Future<void> startStop(DeliveryStop stop) async {
    final current = route;
    if (current == null) return;
    if (stop.status != StopStatus.pending) return;

    final updated = stop.copyWith(status: StopStatus.onRoute);
    route = current.replaceStop(updated);
    await _store.saveRoute(route);
    _safeNotify();

    await _emitStatus(stop.orderId, StopStatus.onRoute);
  }

  /// Confirma a retirada de **todos** os pedidos pendentes na loja.
  Future<void> startAllStops() async {
    final current = route;
    if (current == null) return;

    var updated = current;
    final pending = current.stops.where((s) => s.status == StopStatus.pending).toList();
    for (final stop in pending) {
      updated = updated.replaceStop(stop.copyWith(status: StopStatus.onRoute));
      await _emitStatus(stop.orderId, StopStatus.onRoute);
    }
    route = updated;
    await _store.saveRoute(updated);
    _safeNotify();
  }

  Future<void> markArrived(DeliveryStop stop) async {
    final current = route;
    if (current == null) return;

    final updated = stop.copyWith(status: StopStatus.arrived, arrivedAt: DateTime.now());
    route = current.replaceStop(updated);
    await _store.saveRoute(route);
    _safeNotify();

    await _emitStatus(stop.orderId, StopStatus.arrived);
  }

  Future<String?> deliver(DeliveryStop stop, {required DeliveryProof proof}) async {
    final current = route;
    if (current == null) return 'Rota não encontrada';

    final proofResponse = await _api.pushProof(proof, courierId: courierId);
    if (!proofResponse.ok &&
        !proofResponse.unsupported &&
        proofResponse.statusCode != null &&
        proofResponse.statusCode! >= 400 &&
        proofResponse.statusCode! < 500) {
      return proofResponse.error ?? 'Prova de entrega recusada pelo servidor';
    }

    final updated = stop.copyWith(status: StopStatus.delivered, deliveredAt: DateTime.now());
    route = current.replaceStop(updated);
    await _store.saveRoute(route);
    _safeNotify();

    if (!proofResponse.ok && !proofResponse.unsupported) {
      _enqueue(
        kind: 'status',
        orderId: stop.orderId,
        payload: {
          'orderId': stop.orderId,
          'status': stopStatusToWire(StopStatus.delivered),
          'at': DateTime.now().toIso8601String(),
          'lat': proof.latitude,
          'lng': proof.longitude,
        },
      );
      _enqueue(kind: 'proof', orderId: stop.orderId, payload: proof.toJson());
    }
    return null;
  }

  Future<void> failDelivery(DeliveryStop stop, {required String reason}) async {
    final current = route;
    if (current == null) return;

    final updated = stop.copyWith(status: StopStatus.failed, failureReason: reason);
    route = current.replaceStop(updated);
    await _store.saveRoute(route);
    _safeNotify();

    await _emitStatus(stop.orderId, StopStatus.failed, failureReason: reason);
  }

  Future<void> _emitStatus(String orderId, StopStatus status, {String? failureReason}) async {
    final point = await _location.lastKnown();
    final response = await _api.pushStatus(
      orderId: orderId,
      status: status,
      at: DateTime.now(),
      latitude: point?.latitude,
      longitude: point?.longitude,
      failureReason: failureReason,
      appVersion: appVersion,
      courierId: courierId,
    );
    if (!response.ok && !response.unsupported) {
      _enqueue(
        kind: 'status',
        orderId: orderId,
        payload: {
          'orderId': orderId,
          'status': stopStatusToWire(status),
          'at': DateTime.now().toIso8601String(),
          'lat': point?.latitude,
          'lng': point?.longitude,
          if (failureReason != null) 'failureReason': failureReason,
        },
      );
    }
  }

  void _enqueue({
    required String kind,
    required Map<String, dynamic> payload,
    String? orderId,
  }) {
    _queue.add(
      PendingEvent(
        id: '${kind}_${DateTime.now().microsecondsSinceEpoch}',
        kind: kind,
        orderId: orderId,
        payload: payload,
        createdAt: DateTime.now(),
      ),
    );
    unawaited(_store.saveQueue(_queue));
    _safeNotify();
  }

  /// Tenta esvaziar a fila. Chamado ao abrir o app, ao ganhar rede e no botão
  /// "Sincronizar".
  Future<void> flushQueue() async {
    if (syncing || _queue.isEmpty) return;
    syncing = true;
    _safeNotify();

    final remaining = <PendingEvent>[];
    var offlineHit = false;

    for (var index = 0; index < _queue.length; index++) {
      final event = _queue[index];

      // Depois da primeira falha de rede, preserva a ordem e não insiste.
      if (offlineHit) {
        remaining.add(event);
        continue;
      }

      if (event.lastError == 'unsupported') {
        // Endpoint inexistente: reter não ajuda e reenviar para sempre gera
        // ruído. Fica registrado como não sincronizado.
        remaining.add(event);
        continue;
      }

      DeliveryApiResponse response;
      switch (event.kind) {
        case 'proof':
          response = await _api.pushProof(_proofFromPayload(event.payload), courierId: courierId);
        case 'shift':
          response = await _api.pushShift(
            courierId: (event.payload['courierId'] ?? courierId).toString(),
            open: event.payload['open'] == true,
            at: DateTime.tryParse((event.payload['at'] ?? '').toString()) ?? DateTime.now(),
          );
        default:
          response = await _api.pushStatus(
            orderId: (event.payload['orderId'] ?? event.orderId ?? '').toString(),
            status: stopStatusFromWire(event.payload['status']),
            at: DateTime.tryParse((event.payload['at'] ?? '').toString()) ?? DateTime.now(),
            latitude: (event.payload['lat'] as num?)?.toDouble(),
            longitude: (event.payload['lng'] as num?)?.toDouble(),
            failureReason: event.payload['failureReason']?.toString(),
            appVersion: appVersion,
            courierId: courierId,
          );
      }

      if (response.ok) continue;

      if (response.unsupported) {
        event.lastError = 'unsupported';
        remaining.add(event);
      } else {
        event.withAttemptError(response.error ?? 'offline');
        remaining.add(event);
        offlineHit = true;
      }
    }

    _queue = remaining;
    await _store.saveQueue(_queue);

    syncing = false;
    if (_queue.isEmpty) {
      lastSync = DateTime.now();
      await _store.saveLastSync(lastSync!);
    }
    _safeNotify();
  }

  DeliveryProof _proofFromPayload(Map<String, dynamic> payload) {
    return DeliveryProof(
      orderId: (payload['orderId'] ?? '').toString(),
      method: proofMethodFromWire(payload['method']),
      capturedAt: DateTime.tryParse((payload['capturedAt'] ?? '').toString()) ?? DateTime.now(),
      password: payload['password']?.toString(),
      signature: (payload['signature'] as List?)
          ?.whereType<List>()
          .map((row) => row.map((v) => (v as num).toDouble()).toList())
          .toList(),
      latitude: (payload['lat'] as num?)?.toDouble(),
      longitude: (payload['lng'] as num?)?.toDouble(),
      appVersion: appVersion,
    );
  }

  Future<GeoPoint?> captureLocation() => _location.current();

  /// Rota de demonstração: permite exercitar o app inteiro antes de o ERP
  /// expor os endpoints de entrega. Nunca é confundida com dado real — a UI
  /// mostra o aviso de demonstração.
  DeliveryRoute _demoRoute() {
    final today = DateTime.now();
    return DeliveryRoute(
      id: 'demo-${today.year}${today.month}${today.day}',
      courierId: courierId,
      date: today,
      storeName: 'Mercadinho Matriz - Centro',
      isDemo: true,
      version: 1,
      stops: const [
        DeliveryStop(
          orderId: '9001',
          code: '1042',
          customerName: 'Ana Paula Ribeiro',
          addressText: 'Rua Santos Dumont, 210 - Centro',
          timeSlot: 'Hoje, 14:00 - 16:00',
          dryVolumes: 2,
          coldVolumes: 1,
          itemsCount: 12,
          totalAmount: 187.40,
          phone: '(88) 99911-2233',
          latitude: -6.3621,
          longitude: -39.2985,
          sequence: 1,
        ),
        DeliveryStop(
          orderId: '9002',
          code: '1043',
          customerName: 'José Airton Lima',
          addressText: 'Av. Perimetral, 1180 - Jardim Iguatu',
          timeSlot: 'Hoje, 14:00 - 16:00',
          dryVolumes: 1,
          coldVolumes: 2,
          itemsCount: 8,
          totalAmount: 96.90,
          phone: '(88) 98877-4455',
          latitude: -6.3712,
          longitude: -39.2891,
          sequence: 2,
        ),
        DeliveryStop(
          orderId: '9003',
          code: '1044',
          customerName: 'Francisca Alves',
          addressText: 'Rua das Flores, 45 - Vila Centenário',
          timeSlot: 'Hoje, 16:00 - 18:00',
          dryVolumes: 3,
          coldVolumes: 0,
          itemsCount: 17,
          totalAmount: 254.15,
          phone: '(88) 99633-7788',
          latitude: -6.3588,
          longitude: -39.3052,
          sequence: 3,
        ),
      ],
    );
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    _api.dispose();
    super.dispose();
  }
}
